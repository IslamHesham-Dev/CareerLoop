"""Which university are we talking to?

GUC (Cairo) and GIU both run the same CMS software, so one client works for
both. The only things that differ are the host and a couple of page paths, which
live here. Pick a site with `GucCms(site="guc")` or the GUC_SITE env var.

GUC is verified against the live site. GIU is filled in from a GIU project that
uses the same CMS, but it is NOT verified yet. Treat GIU as a starting point to
confirm once a GIU login is available.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class CmsSite:
    base_url: str
    course_list_path: str  # the page that lists all your courses
    course_view_path: str  # one course's page (takes ?id=&sid=)


CMS_SITES: dict[str, CmsSite] = {
    "guc": CmsSite(
        base_url="https://cms.guc.edu.eg",
        course_list_path="/apps/student/ViewAllCourseStn",
        course_view_path="/apps/student/CourseViewStn.aspx",
    ),
    # UNVERIFIED. Hosts/paths taken from a GIU project on the same CMS. The course
    # list page differs (HomePageStn), so the course-list parsing may need a tweak
    # once a GIU login is available.
    "giu": CmsSite(
        base_url="https://cms.giu-uni.de",
        course_list_path="/apps/student/HomePageStn.aspx",
        course_view_path="/apps/student/CourseViewStn.aspx",
    ),
}
