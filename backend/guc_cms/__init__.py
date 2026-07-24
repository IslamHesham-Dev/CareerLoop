"""guc_cms: a tiny Python client for the GUC student CMS.

    from guc_cms import GucCms

    cms = GucCms("your.username", "your.password")   # or set GUC_USERNAME / GUC_PASSWORD
    for course in cms.list_courses():
        print(course.code, course.title)

    se = cms.find_course("Software Engineering")
    content = cms.get_content(se)
    for week, files in content.weeks().items():
        print(week, "->", len(files), "files")

The whole point of keeping this plain: later you wrap `list_courses`,
`get_content`, and `download` as agent tools. Nothing in here knows about
agents; that stays your job in the room.
"""

from .client import BASE_URL, GucCms
from .models import ContentItem, Course, CourseContent

__all__ = ["GucCms", "Course", "ContentItem", "CourseContent", "BASE_URL"]
