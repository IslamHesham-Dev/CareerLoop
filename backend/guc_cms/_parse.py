"""Turn the CMS HTML into our dataclasses.

These are plain functions: HTML string in, dataclasses out. No network here.
Keeping the parsing separate from the client means you can save one page to a
file and test the parser on it forever, without hitting the server every time.

The CMS is an old ASP.NET site, so the markup is a bit crusty. The two shapes we
lean on:

  * The "all courses" page is a set of tables whose columns are
    [checkbox, Name, Active, ID, SeasonId].
  * A course page is a list of `div.weeksdata` blocks. Each block has a week
    label and, inside it, one `div.card-body` per downloadable file.
"""

from __future__ import annotations

import re

from bs4 import BeautifulSoup

from .models import ContentItem, Course, CourseContent

# "(|CSEN603|)" -> "CSEN603"
_CODE_RE = re.compile(r"\(\|([^|]+)\|\)")


def _clean_title(name: str) -> tuple[str | None, str]:
    """Split a course label into (code, human title).

    "(|CSEN603|) Software Engineering (436)" -> ("CSEN603", "Software Engineering")
    """
    code_match = _CODE_RE.search(name)
    code = code_match.group(1).strip() if code_match else None
    title = _CODE_RE.sub("", name)  # drop the code
    title = re.sub(r"\(\-?\d+\)\s*$", "", title)  # drop the trailing "(436)"
    return code, title.strip()


def parse_courses(html: str) -> list[Course]:
    """Read the "all courses" page into a list of Course."""
    soup = BeautifulSoup(html, "lxml")
    courses: list[Course] = []

    for table in soup.find_all("table"):
        rows = table.find_all("tr")
        if not rows:
            continue
        header = [c.get_text(strip=True) for c in rows[0].find_all(["th", "td"])]
        # Only the course tables have ID and SeasonId columns.
        if "ID" not in header or "SeasonId" not in header:
            continue

        # Find columns by their header name, not a fixed position: GIU's table
        # has an extra "Season" column that GUC's does not, which would shift
        # everything if we read cells[3]/cells[4] blindly.
        i_name = header.index("Name") if "Name" in header else 1
        i_active = header.index("Active") if "Active" in header else 2
        i_id = header.index("ID")
        i_sid = header.index("SeasonId")

        for row in rows[1:]:
            cells = [c.get_text(strip=True) for c in row.find_all(["th", "td"])]
            if len(cells) <= max(i_id, i_sid):
                continue
            cid, sid = cells[i_id], cells[i_sid]
            if not cid.lstrip("-").isdigit() or not sid.lstrip("-").isdigit():
                continue
            name, active = cells[i_name], cells[i_active]
            code, title = _clean_title(name)
            courses.append(
                Course(
                    id=int(cid),
                    season_id=int(sid),
                    name=name,
                    code=code,
                    title=title,
                    active=(active.lower() == "active"),
                )
            )
    return courses


def _week_label(week_div) -> str | None:
    """Name for a week block, e.g. "Week 11" or "Final Exams".

    Each block has a date header (`h2.text-big`, always "Week: YYYY-M-D") and a
    couple of `p.p2` lines. The *last* p2 is reliably the week's name; the first
    is an announcement we don't want here. We fall back to the date header.
    """
    names = [
        p.get_text(strip=True)
        for p in week_div.find_all("p", class_="p2")
        if p.get_text(strip=True)
    ]
    if names:
        return names[-1]
    date = week_div.find("h2", class_="text-big")
    if date and date.get_text(strip=True):
        return date.get_text(strip=True)
    return None


def _parse_item(card_body, week: str | None) -> ContentItem | None:
    """Read one file card. Returns None if there is no download link in it."""
    link = card_body.find("a", href=re.compile(r"^/Uploads/"))
    if not link:
        return None

    label = card_body.find("div", id=re.compile(r"^content"))
    title, kind, content_id = "", None, 0
    if label:
        strong = label.find(["strong", "b"])
        title = strong.get_text(strip=True) if strong else label.get_text(strip=True)
        # The text after the <strong> is the kind, usually in parentheses.
        tail = label.get_text(" ", strip=True)
        if strong:
            tail = tail.replace(strong.get_text(strip=True), "", 1).strip()
        kind_match = re.search(r"\(([^)]+)\)", tail)
        kind = kind_match.group(1).strip() if kind_match else (tail or None)
        id_match = re.search(r"\d+", label.get("id", ""))
        content_id = int(id_match.group()) if id_match else 0

    return ContentItem(
        content_id=content_id,
        title=title,
        kind=kind,
        url=link["href"],
        week=week,
    )


def parse_course_content(html: str) -> CourseContent:
    """Read a single course page into its files, grouped by week."""
    soup = BeautifulSoup(html, "lxml")

    name_el = soup.find("span", id=re.compile("LabelCourseName"))
    season_el = soup.find("span", id=re.compile("LabelseasonName"))
    course_name = name_el.get_text(strip=True) if name_el else ""
    season_name = season_el.get_text(strip=True) if season_el else None

    items: list[ContentItem] = []
    for week_div in soup.find_all("div", class_="weeksdata"):
        week = _week_label(week_div)
        for card_body in week_div.find_all("div", class_="card-body"):
            item = _parse_item(card_body, week)
            if item:
                items.append(item)

    return CourseContent(course_name=course_name, season_name=season_name, items=items)
