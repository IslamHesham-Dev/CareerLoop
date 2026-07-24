from __future__ import annotations

import hashlib
import re
import threading
from dataclasses import dataclass
from typing import Any
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup, Tag
from requests_ntlm import HttpNtlmAuth


CMS_BASE_URL = "https://cms.giu-uni.de"
CMS_STUDENT_PATH = "/apps/student/"
COURSE_CODE = re.compile(r"\b[A-Z]{2,8}\s*-?\s*\d{2,4}[A-Z]?\b", re.I)


def _clean(value: str | None) -> str:
    return " ".join((value or "").split())


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
    """Authenticated, read-only client for the GIU course-management system.

    The CMS uses the same NTLM credentials as the student portal. Course URLs
    and download URLs remain server-side and are represented by opaque IDs in
    the mobile API.
    """

    def __init__(
        self,
        username: str,
        password: str,
        *,
        base_url: str = CMS_BASE_URL,
        timeout: int = 60,
        verify: bool = True,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.session = requests.Session()
        self.session.auth = HttpNtlmAuth(username, password)
        self.session.verify = verify
        self.session.headers.update(
            {"User-Agent": "CareerLoop/1.0 (read-only GIU CMS client)"}
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
            raise RuntimeError("GIU CMS redirected outside its authenticated host.")
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

            landing = self._get(CMS_STUDENT_PATH)
            html = landing.text
            courses = self._parse_course_links(html, page_url=landing.url)

            # Some CMS versions place the course grid one navigation step away
            # from the student landing page. Discover it from same-host links
            # instead of hard-coding a brittle controller route.
            if not courses:
                for candidate in self._navigation_candidates(html, landing.url):
                    response = self._get(candidate)
                    courses.extend(
                        self._parse_course_links(
                            response.text,
                            page_url=response.url,
                        )
                    )
                    if courses:
                        break

            unique = {course["id"]: course for course in courses}
            courses = sorted(
                unique.values(),
                key=lambda course: (course["code"] == "CMS", course["title"]),
            )
            if not courses:
                raise RuntimeError(
                    "GIU CMS authenticated successfully, but no course links "
                    "were found on the student pages."
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
    def _week(card: Tag, indexes: dict[int, int]) -> tuple[int | None, str | None]:
        week_card = card.find_parent("div", class_=lambda value: value and "weeksdata" in value)
        if week_card is None:
            week_card = card.find_parent(class_=re.compile(r"\bweek", re.I))
        if week_card is None:
            return None, None
        key = id(week_card)
        header = week_card.find(["h2", "h3", "h4"], class_=re.compile(r"text-big", re.I))
        header = header or week_card.find(["h2", "h3", "h4"])
        text = _clean(header.get_text(" ", strip=True) if header else "")
        explicit = re.search(r"\bweek\s*(\d+)\b", text, re.I)
        if explicit:
            return int(explicit.group(1)), text
        if key not in indexes:
            indexes[key] = len(indexes) + 1
        return indexes[key], text or f"Week {indexes[key]}"

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
        week_indexes: dict[int, int] = {}

        for anchor in soup.select("a#download, a[id$='download']"):
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
            week, week_label = self._week(body, week_indexes)
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
