from __future__ import annotations

import hashlib
import re
import threading
from dataclasses import dataclass
from datetime import date
from typing import Any
from urllib.parse import parse_qs, urljoin, urlparse

import requests
from bs4 import BeautifulSoup, Tag
from requests_ntlm import HttpNtlmAuth

from guc_cms._sites import CMS_SITES


CMS_BASE_URL = "https://cms.giu-uni.de"
CMS_STUDENT_PATH = "/apps/student/"
CMS_COURSE_LIST_PATH = "/apps/student/ViewAllCourseStn.aspx"
CMS_COURSE_HOME_PATH = "/apps/student/HomePageStn.aspx"
CMS_COURSE_VIEW_PATH = "/apps/student/CourseViewStn.aspx"
COURSE_CODE = re.compile(r"\b[A-Z]{2,8}\s*-?\s*\d{2,4}[A-Z]?\b", re.I)
SEASON_HEADING = re.compile(
    r"\bSeason\s*:\s*(?P<id>\d+)\s*,\s*Title\s*:\s*"
    r"(?P<title>.+?)(?:\s+Current\s+Season)?\s*$",
    re.I,
)


def _clean(value: str | None) -> str:
    return " ".join((value or "").split())


_WEEK_LABEL_RE = re.compile(r"\bweek\s*(\d+)\b", re.I)
_WEEK_DATE_RE = re.compile(r"(\d{4})-(\d{1,2})-(\d{1,2})")


def _parse_week_date(text: str) -> date | None:
    match = _WEEK_DATE_RE.search(text)
    if not match:
        return None
    try:
        return date(int(match.group(1)), int(match.group(2)), int(match.group(3)))
    except ValueError:
        return None


def _stable_id(prefix: str, value: str) -> str:
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:24]
    return f"{prefix}_{digest}"


def _course_code(text: str) -> str:
    wrapped = re.search(r"\(\|?([A-Za-z]+\d[A-Za-z\d]*)\|?\)", text)
    match = wrapped or COURSE_CODE.search(text)
    return re.sub(r"\s|-", "", match.group(1 if wrapped else 0)).upper() if match else ""


def _course_title(text: str, code: str) -> str:
    title = re.sub(r"\(\|?[A-Za-z]+\d[A-Za-z\d]*\|?\)", "", text)
    if code:
        title = re.sub(re.escape(code), "", title, flags=re.I)
    title = re.sub(r"\(\d+\)", "", title)
    title = title.strip(" -|")
    return _clean(title) or code or "CMS course"


@dataclass(frozen=True)
class CmsDownload:
    response: requests.Response
    filename: str
    content_type: str


class GiuCmsClient:
    """Authenticated, read-only client for the GUC/GIU course-management system.

    The CMS uses the same NTLM credentials as the student portal. Course URLs
    and download URLs remain server-side and are represented by opaque IDs in
    the mobile API.
    """

    def __init__(
        self,
        username: str,
        password: str,
        *,
        site: str = "giu",
        base_url: str | None = None,
        timeout: int = 60,
        verify: bool = True,
    ) -> None:
        site_name = site.strip().casefold()
        if site_name not in CMS_SITES:
            raise ValueError(
                f"Unknown CMS site {site!r}. Known sites: {list(CMS_SITES)}."
            )
        self.site_name = site_name
        self.site = CMS_SITES[site_name]
        self.university_label = site_name.upper()
        self.base_url = (base_url or self.site.base_url).rstrip("/")
        self.course_list_path = self.site.course_list_path
        self.course_view_path = self.site.course_view_path
        self.course_home_path = CMS_COURSE_HOME_PATH
        self.timeout = timeout
        self.session = requests.Session()
        self.session.auth = HttpNtlmAuth(username, password)
        self.session.verify = verify
        self.session.headers.update(
            {
                "User-Agent": (
                    f"CareerLoop/1.0 (read-only {self.university_label} CMS client)"
                )
            }
        )
        self._course_urls: dict[str, str] = {}
        self._resource_urls: dict[str, tuple[str, str]] = {}
        self._courses_cache: list[dict[str, Any]] | None = None
        self._lock = threading.RLock()

    def close(self) -> None:
        with self._lock:
            self._course_urls.clear()
            self._resource_urls.clear()
            self._courses_cache = None
            self.session.auth = None
            self.session.close()

    def _safe_url(self, href: str, *, require_student_path: bool = True) -> str:
        url = urljoin(f"{self.base_url}/", href)
        parsed = urlparse(url)
        expected = urlparse(self.base_url)
        if parsed.scheme != "https" or parsed.netloc != expected.netloc:
            raise ValueError("The CMS returned an unexpected external URL.")
        if require_student_path and not parsed.path.casefold().startswith(
            CMS_STUDENT_PATH.casefold()
        ):
            raise ValueError("The CMS returned a URL outside the student area.")
        return url

    def _get(self, url_or_path: str, *, stream: bool = False) -> requests.Response:
        url = self._safe_url(url_or_path, require_student_path=not stream)
        response = self.session.get(
            url,
            timeout=self.timeout,
            allow_redirects=True,
            stream=stream,
        )
        response.raise_for_status()
        final = urlparse(response.url)
        expected = urlparse(self.base_url)
        if final.scheme != "https" or final.netloc != expected.netloc:
            response.close()
            raise RuntimeError(
                f"{self.university_label} CMS redirected outside its "
                "authenticated host."
            )
        return response

    @staticmethod
    def _anchor_label(anchor: Tag) -> str:
        label = (
            anchor.get("title")
            or anchor.get("aria-label")
            or anchor.get_text(" ", strip=True)
        )
        if len(_clean(label)) < 4:
            parent = anchor.find_parent(["article", "li", "div"])
            label = parent.get_text(" ", strip=True) if parent else label
        return _clean(label)

    @staticmethod
    def _is_course_anchor(anchor: Tag, label: str) -> bool:
        href = str(anchor.get("href") or "")
        lower_href = href.casefold()
        lower_label = label.casefold()
        if not href or href.startswith(("#", "javascript:", "mailto:")):
            return False
        if any(
            excluded in lower_href
            for excluded in (
                "download",
                "logout",
                "profile",
                "password",
                "notification",
            )
        ):
            return False
        path_signal = any(
            signal in lower_href
            for signal in (
                "coursedetail",
                "course/detail",
                "viewcourse",
                "coursecontent",
                "course/content",
                "subjectdetail",
                "subject/detail",
            )
        )
        text_signal = bool(_course_code(label))
        generic = lower_label.strip(" -|") in {
            "course",
            "courses",
            "my course",
            "my courses",
            "registered courses",
            "course materials",
        }
        return text_signal or (path_signal and not generic and len(label) > 6)

    def _parse_course_links(
        self,
        html: str,
        *,
        page_url: str,
    ) -> list[dict[str, Any]]:
        soup = BeautifulSoup(html, "lxml")
        courses: list[dict[str, Any]] = []
        seen_urls: set[str] = set()
        for anchor in soup.find_all("a", href=True):
            label = self._anchor_label(anchor)
            if not self._is_course_anchor(anchor, label):
                continue
            try:
                url = self._safe_url(urljoin(page_url, anchor["href"]))
            except ValueError:
                continue
            if url in seen_urls:
                continue
            seen_urls.add(url)
            code = _course_code(label)
            course_id = _stable_id("course", url)
            courses.append(
                {
                    "id": course_id,
                    "code": code or "CMS",
                    "title": _course_title(label, code),
                    "cms_label": label,
                    "resource_count": None,
                }
            )
            self._course_urls[course_id] = url
        return courses

    def _parse_course_table(self, html: str) -> list[dict[str, Any]]:
        """Parse GIU's HomePageStn course table.

        GIU includes hidden ID and SeasonId columns. Those two values are what
        CourseViewStn expects when a student opens a course.
        """
        soup = BeautifulSoup(html, "lxml")
        courses: list[dict[str, Any]] = []
        for table in soup.find_all("table"):
            rows = table.find_all("tr")
            if not rows:
                continue
            headers = [
                _clean(cell.get_text(" ", strip=True))
                for cell in rows[0].find_all(["th", "td"])
            ]
            folded = [header.casefold() for header in headers]
            if "id" not in folded or "seasonid" not in folded:
                continue
            name_index = folded.index("name") if "name" in folded else 1
            id_index = folded.index("id")
            season_index = folded.index("seasonid")
            season_name_index = (
                folded.index("season") if "season" in folded else None
            )
            active_index = (
                folded.index("active") if "active" in folded else None
            )
            for row in rows[1:]:
                cells = [
                    _clean(cell.get_text(" ", strip=True))
                    for cell in row.find_all(["th", "td"])
                ]
                if len(cells) <= max(name_index, id_index, season_index):
                    continue
                course_number = cells[id_index]
                season_number = cells[season_index]
                if not (
                    course_number.lstrip("-").isdigit()
                    and season_number.lstrip("-").isdigit()
                ):
                    continue
                label = cells[name_index]
                code = _course_code(label)
                url = self._safe_url(
                    f"{self.course_view_path}?id={course_number}"
                    f"&sid={season_number}"
                )
                course_id = _stable_id("course", url)
                courses.append(
                    {
                        "id": course_id,
                        "code": code or "CMS",
                        "title": _course_title(label, code),
                        "cms_label": label,
                        "resource_count": None,
                        "season": (
                            cells[season_name_index]
                            if season_name_index is not None
                            and season_name_index < len(cells)
                            else ""
                        ),
                        "season_id": int(season_number),
                        "active": (
                            cells[active_index].casefold() == "active"
                            if active_index is not None
                            and active_index < len(cells)
                            else None
                        ),
                    }
                )
                self._course_urls[course_id] = url
        return courses

    def _parse_all_course_seasons(
        self,
        html: str,
        *,
        page_url: str,
    ) -> list[dict[str, Any]]:
        """Parse ViewAllCourseStn's season headings and course tables.

        The historical-course page renders a heading such as
        ``Season : 67 , Title: Winter 2025`` followed by a table whose visible
        columns are Name and Active. The final number in each course label is
        the course offering ID expected by CourseViewStn; the season heading
        supplies its ``sid``.
        """
        soup = BeautifulSoup(html, "lxml")
        courses: list[dict[str, Any]] = []
        seen_tables: set[int] = set()
        heading_elements: list[Tag] = []
        for text_node in soup.find_all(string=SEASON_HEADING):
            if isinstance(text_node.parent, Tag):
                heading_elements.append(text_node.parent)
        # Some ASP.NET themes split "Season", its number, and its title over
        # nested spans. Inspect compact heading-like containers as a fallback.
        for element in soup.find_all(
            ["strong", "b", "span", "p", "div", "h1", "h2", "h3", "h4"]
        ):
            text = _clean(element.get_text(" ", strip=True))
            if text.casefold().count("season :") != 1:
                continue
            if SEASON_HEADING.search(text) and element not in heading_elements:
                heading_elements.append(element)

        for element in heading_elements:
            heading = SEASON_HEADING.search(
                _clean(element.get_text(" ", strip=True))
            )
            if heading is None:
                continue
            season_number = int(heading.group("id"))
            season_title = re.sub(
                r"\s+Current\s+Season\s*$",
                "",
                _clean(heading.group("title")),
                flags=re.I,
            )
            table = element.find_next("table")
            if table is None or id(table) in seen_tables:
                continue
            seen_tables.add(id(table))

            rows = table.find_all("tr")
            if not rows:
                continue
            headers = [
                _clean(cell.get_text(" ", strip=True)).casefold()
                for cell in rows[0].find_all(["th", "td"])
            ]
            name_index = headers.index("name") if "name" in headers else 0
            active_index = (
                headers.index("active") if "active" in headers else None
            )
            for row in rows[1:]:
                cells = row.find_all(["th", "td"])
                if len(cells) <= name_index:
                    continue
                label = _clean(cells[name_index].get_text(" ", strip=True))
                if not label:
                    continue

                course_number = ""
                for anchor in cells[name_index].find_all("a", href=True):
                    try:
                        anchor_url = self._safe_url(
                            urljoin(page_url, str(anchor["href"]))
                        )
                    except ValueError:
                        continue
                    query = parse_qs(urlparse(anchor_url).query)
                    candidate = (query.get("id") or [""])[0]
                    if candidate.lstrip("-").isdigit():
                        course_number = candidate
                        break
                if not course_number:
                    offering = re.search(r"\((\d+)\)\s*$", label)
                    course_number = offering.group(1) if offering else ""
                if not course_number:
                    continue

                url = self._safe_url(
                    f"{self.course_view_path}?id={course_number}"
                    f"&sid={season_number}"
                )
                course_id = _stable_id("course", url)
                code = _course_code(label)
                active_text = (
                    _clean(cells[active_index].get_text(" ", strip=True))
                    if active_index is not None
                    and active_index < len(cells)
                    else ""
                )
                courses.append(
                    {
                        "id": course_id,
                        "code": code or "CMS",
                        "title": _course_title(label, code),
                        "cms_label": label,
                        "resource_count": None,
                        "season": season_title,
                        "season_id": season_number,
                        "active": (
                            active_text.casefold() == "active"
                            if active_text
                            else None
                        ),
                    }
                )
                self._course_urls[course_id] = url
        return courses

    def _navigation_candidates(self, html: str, page_url: str) -> list[str]:
        soup = BeautifulSoup(html, "lxml")
        candidates: list[str] = []
        for anchor in soup.find_all("a", href=True):
            label = self._anchor_label(anchor).casefold()
            href = str(anchor["href"])
            if not any(word in f"{label} {href.casefold()}" for word in (
                "course",
                "subject",
                "material",
                "semester",
            )):
                continue
            try:
                url = self._safe_url(urljoin(page_url, href))
            except ValueError:
                continue
            if url not in candidates:
                candidates.append(url)
        return candidates[:8]

    def list_courses(self, *, force: bool = False) -> list[dict[str, Any]]:
        with self._lock:
            if self._courses_cache is not None and not force:
                return [dict(course) for course in self._courses_cache]

            # ViewAllCourseStn is the season-aware source. HomePageStn exposes
            # only the current subset and therefore cannot answer historical
            # advisory-semester requests.
            landing = self._get(self.course_list_path)
            html = landing.text
            courses = self._parse_all_course_seasons(
                html,
                page_url=landing.url,
            )
            if not courses:
                courses = self._parse_course_table(html)
            if not courses:
                courses = self._parse_course_links(
                    html,
                    page_url=landing.url,
                )

            # Retain the current-course page as a compatibility fallback for a
            # CMS deployment that does not expose the historical table.
            if not courses:
                home = self._get(self.course_home_path)
                courses = self._parse_course_table(home.text)
                if not courses:
                    courses = self._parse_course_links(
                        home.text,
                        page_url=home.url,
                    )
                candidates = self._navigation_candidates(home.text, home.url)
                for candidate in candidates:
                    if courses:
                        break
                    response = self._get(candidate)
                    courses.extend(
                        self._parse_course_links(
                            response.text,
                            page_url=response.url,
                        )
                    )

            unique = {course["id"]: course for course in courses}
            courses = sorted(
                unique.values(),
                key=lambda course: (course["code"] == "CMS", course["title"]),
            )
            if not courses:
                raise RuntimeError(
                    f"{self.university_label} CMS authenticated successfully, "
                    "but no course links were found on the student pages."
                )
            self._courses_cache = courses
            return [dict(course) for course in courses]

    def _course(self, course_id: str) -> tuple[dict[str, Any], str]:
        courses = self.list_courses()
        course = next(
            (item for item in courses if item["id"] == course_id),
            None,
        )
        if course is None or course_id not in self._course_urls:
            raise ValueError(f"No CMS course matches ID {course_id!r}.")
        return course, self._course_urls[course_id]

    @staticmethod
    def _week_card(card: Tag) -> Tag | None:
        week_card = card.find_parent("div", class_=lambda value: value and "weeksdata" in value)
        if week_card is None:
            week_card = card.find_parent(class_=re.compile(r"\bweek", re.I))
        return week_card

    @staticmethod
    def _week_numbers(soup: BeautifulSoup) -> dict[int, tuple[int, str]]:
        """Map each week block's identity to a (week_number, label) pair.

        The CMS stores the meaningful week name in the last ``p.p2`` element
        inside the block, while its heading is often only a date. The explicit
        "Week N" label always wins so a late upload date cannot relabel Week 1
        as the final week. Dates (earliest = Week 1) and then page order are
        only fallbacks when the CMS does not provide an explicit number.
        """
        cards = soup.find_all(
            "div", class_=lambda value: value and "weeksdata" in value
        )
        if not cards:
            cards = soup.find_all(class_=re.compile(r"\bweek", re.I))

        records: list[tuple[int, str, date | None, int | None]] = []
        for card in cards:
            header = card.find(
                ["h2", "h3", "h4"],
                class_=re.compile(r"text-big", re.I),
            )
            header = header or card.find(["h2", "h3", "h4"])
            header_text = _clean(
                header.get_text(" ", strip=True) if header else ""
            )
            names = [
                _clean(node.get_text(" ", strip=True))
                for node in card.find_all("p", class_="p2")
                if _clean(node.get_text(" ", strip=True))
            ]
            label = names[-1] if names else header_text
            explicit_match = _WEEK_LABEL_RE.search(label)
            records.append(
                (
                    id(card),
                    label,
                    _parse_week_date(header_text),
                    int(explicit_match.group(1))
                    if explicit_match
                    else None,
                )
            )

        labels = {key: label for key, label, _date, _number in records}
        dated = [
            (key, parsed_date)
            for key, _label, parsed_date, _number in records
            if parsed_date is not None
        ]
        dated.sort(key=lambda item: item[1])
        mapping: dict[int, tuple[int, str]] = {}
        for rank, (key, _date) in enumerate(dated, start=1):
            label = labels.get(key) or f"Week {rank}"
            mapping[key] = (rank, label)

        used_numbers = {
            number
            for _key, _label, _date, number in records
            if number is not None
        }
        for key, label, _date, number in records:
            if number is not None:
                mapping[key] = (number, label or f"Week {number}")

        next_number = 1
        for key, label, parsed_date, number in records:
            if number is not None or parsed_date is not None:
                continue
            while next_number in used_numbers:
                next_number += 1
            mapping[key] = (next_number, label or f"Week {next_number}")
            used_numbers.add(next_number)
            next_number += 1
        return mapping

    def _parse_resources(
        self,
        html: str,
        *,
        page_url: str,
    ) -> tuple[str, str, list[dict[str, Any]]]:
        soup = BeautifulSoup(html, "lxml")
        title_node = soup.select_one(".menu-header-title span")
        title_text = _clean(
            title_node.get_text(" ", strip=True) if title_node else ""
        )
        if not title_text:
            fallback = soup.find(["h1", "h2"]) or soup.title
            title_text = _clean(
                fallback.get_text(" ", strip=True) if fallback else ""
            )
        code = _course_code(title_text)
        title = _course_title(title_text, code)
        resources: list[dict[str, Any]] = []
        seen: set[str] = set()
        week_numbers = self._week_numbers(soup)

        for anchor in soup.select(
            "a#download, a[id$='download'], a[href^='/Uploads/']"
        ):
            href = str(anchor.get("href") or "")
            if not href:
                continue
            try:
                url = self._safe_url(
                    urljoin(page_url, href),
                    require_student_path=False,
                )
            except ValueError:
                continue
            if url in seen:
                continue
            seen.add(url)
            body = anchor.find_parent(class_=re.compile(r"\bcard-body\b"))
            body = body or anchor.parent
            if not isinstance(body, Tag):
                continue
            strong = body.find("strong")
            raw_title = _clean(
                strong.get_text(" ", strip=True) if strong else anchor.get_text(" ", strip=True)
            )
            display_title = _clean("-".join(raw_title.split("-")[1:])) or raw_title
            parent_text = _clean(
                strong.parent.get_text(" ", strip=True) if strong and strong.parent else ""
            )
            content_match = re.search(r"\(([^)]+)\)", parent_text)
            content_type = _clean(content_match.group(1) if content_match else "")
            divs = body.find_all("div", recursive=True)
            subtitle = _clean(divs[1].get_text(" ", strip=True)) if len(divs) > 1 else ""
            week_card = self._week_card(body)
            week, week_label = (
                week_numbers.get(id(week_card), (None, None))
                if week_card is not None
                else (None, None)
            )
            parsed = urlparse(url)
            extension = parsed.path.rsplit(".", 1)[-1].lower() if "." in parsed.path else ""
            resource_id = _stable_id("resource", url)
            is_vod = body.select_one("input.vodbutton") is not None
            filename = f"{display_title or 'cms-resource'}{f'.{extension}' if extension else ''}"
            self._resource_urls[resource_id] = (url, filename)
            resources.append(
                {
                    "id": resource_id,
                    "title": display_title or "CMS resource",
                    "subtitle": subtitle,
                    "content_type": content_type or ("Video" if is_vod else "Resource"),
                    "file_extension": extension,
                    "week": week,
                    "week_label": week_label,
                    "is_vod": is_vod,
                    "download_path": f"/v1/cms/resources/{resource_id}/download",
                }
            )
        return code, title, resources

    def course_content(self, course_id: str) -> dict[str, Any]:
        with self._lock:
            summary, url = self._course(course_id)
            response = self._get(url)
            code, title, resources = self._parse_resources(
                response.text,
                page_url=response.url,
            )
            return {
                **summary,
                "code": code or summary["code"],
                "title": title if title != "CMS course" else summary["title"],
                "resource_count": len(resources),
                "resources": resources,
            }

    def open_resource(self, resource_id: str) -> CmsDownload:
        with self._lock:
            resource = self._resource_urls.get(resource_id)
            if resource is None:
                raise ValueError(
                    "The CMS resource is not in this session. Open its course "
                    "page before downloading it."
                )
            url, filename = resource
            response = self._get(url, stream=True)
            content_type = response.headers.get(
                "Content-Type", "application/octet-stream"
            )
            disposition = response.headers.get("Content-Disposition", "")
            server_name = re.search(
                r"filename\*?=(?:UTF-8''|[\"']?)([^\"';]+)",
                disposition,
                re.I,
            )
            if server_name:
                filename = server_name.group(1)
            return CmsDownload(response, filename, content_type)
