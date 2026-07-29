from __future__ import annotations

import re
import threading
from typing import Any

from guc_portal import GucPortal


class AcademicService:
    """Per-student, read-only access to portal data with an isolated cache."""

    def __init__(
        self,
        portal: GucPortal,
        *,
        current_season: str,
        advisory_year: str,
        enrollment_year: int | None = None,
    ) -> None:
        self.portal = portal
        self.institution = getattr(portal, "site_name", "giu")
        self.university_label = self.institution.upper()
        self.current_season = current_season
        fallback_start = self._academic_year_start(advisory_year)
        self.enrollment_year = enrollment_year or max(2000, fallback_start - 3)
        # Safe fallback until the portal year selector is read. Once available
        # years are known, this expands to every year from enrollment onward.
        self.transcript_window_years = [
            f"{year}-{year + 1}"
            for year in range(
                self.enrollment_year,
                self.enrollment_year + 4,
            )
        ]
        self.advisory_year = (
            advisory_year
            if advisory_year in self.transcript_window_years
            else self.transcript_window_years[0]
        )
        self.cache: dict[Any, Any] = {}
        self.portal_lock = threading.RLock()

    @staticmethod
    def _academic_year_start(label: str) -> int:
        match = re.search(r"\b(20\d{2})\b", label)
        return int(match.group(1)) if match else 2021

    @staticmethod
    def _semester_order(label: str) -> tuple[int, int]:
        match = re.search(
            r"\b(Winter|Spring|Summer)(?:\s+Semester)?\s+(20\d{2})\b",
            label,
            re.IGNORECASE,
        )
        if not match:
            return (0, 0)
        # The portals label the annual sequence Spring, Summer, then Winter.
        term_rank = {"spring": 1, "summer": 2, "winter": 3}
        return (int(match.group(2)), term_rank[match.group(1).casefold()])

    @staticmethod
    def _pick(
        options: list[tuple[str, str]], query: str, kind: str
    ) -> tuple[str, str]:
        needle = query.strip().casefold()
        exact = [
            (value, label)
            for value, label in options
            if label.casefold() == needle
        ]
        matches = exact or [
            (value, label)
            for value, label in options
            if needle in label.casefold()
        ]
        if not matches:
            raise ValueError(f"No {kind} matches {query!r}.")
        if len(matches) > 1:
            labels = [label for _value, label in matches]
            raise ValueError(f"Ambiguous {kind} {query!r}; matches: {labels}")
        return matches[0]

    def _seasons(self) -> list[tuple[str, str]]:
        with self.portal_lock:
            if "seasons" not in self.cache:
                self.cache["seasons"] = self.portal.available_seasons(
                    tries=2, delay=60
                )
            return self.cache["seasons"]

    def prime_seasons(self, seasons: list[tuple[str, str]]) -> None:
        with self.portal_lock:
            self.cache["seasons"] = seasons

    def _courses(self, season_value: str) -> list[tuple[str, str]]:
        key = ("courses", season_value)
        with self.portal_lock:
            if key not in self.cache:
                self.cache[key] = self.portal.list_previous_courses(
                    season_value, tries=2, delay=60
                )
            return self.cache[key]

    def _years(self) -> list[tuple[str, str]]:
        with self.portal_lock:
            if "years" not in self.cache:
                self.cache["years"] = self.portal.available_years(
                    tries=2, delay=60
                )
            years = self.cache["years"]
            enrollment_years = self._enrollment_transcript_years(years)
            if enrollment_years:
                self.transcript_window_years = enrollment_years
            return years

    def _enrollment_transcript_years(
        self,
        options: list[tuple[str, str]],
    ) -> list[str]:
        """Return every portal transcript year from enrollment onward."""
        matching: dict[int, str] = {}
        for _value, label in options:
            match = re.search(r"\b(20\d{2})\b", label)
            if match is None:
                continue
            start = int(match.group(1))
            if start >= self.enrollment_year:
                matching.setdefault(start, label)
        return [matching[start] for start in sorted(matching)]

    def context(self) -> dict[str, Any]:
        sources = [
            f"{self.university_label} portal detailed grades",
            f"{self.university_label} transcript",
            f"live {self.university_label} CMS course resources",
        ]
        if self.institution == "giu":
            sources.append(
                "CareerLoop supplemental Drive videos for matched courses"
            )
        return {
            "simulated_current_season": self.current_season,
            "transcript_year": self.advisory_year,
            "enrollment_year": self.enrollment_year,
            "transcript_years": self.transcript_window_years,
            "data_sources": sources,
            "excluded_sources": ["live current-course page"],
        }

    def list_grade_seasons(self) -> list[str]:
        return [label for _value, label in self._seasons()]

    def select_current_season(self, season: str) -> dict[str, Any]:
        """Validate and select the season used by advisory tools."""
        _value, season_label = self._pick(
            self._seasons(), season, "season"
        )
        self.current_season = season_label
        return self.context()

    def select_latest_actual_context(self) -> dict[str, Any]:
        """Select the newest semester backed by a non-empty transcript page."""
        available_years = {
            label.casefold(): label for _value, label in self._years()
        }
        for expected_year in reversed(self.transcript_window_years):
            actual_year = available_years.get(expected_year.casefold())
            if actual_year is None:
                continue
            try:
                data = self.transcript(actual_year)
            except Exception:
                # A flaky/future page must not prevent checking an older year.
                continue
            if not data["courses"]:
                continue
            self.advisory_year = data["year"]
            transcript_semesters = {
                row["semester"].strip()
                for row in data["courses"]
                if row["semester"].strip()
            }
            transcript_semester_keys = {
                self._semester_order(semester)
                for semester in transcript_semesters
            } - {(0, 0)}
            season_labels = [label for _value, label in self._seasons()]
            actual_seasons = [
                season
                for season in season_labels
                if self._semester_order(season) in transcript_semester_keys
            ]
            if actual_seasons:
                self.current_season = max(
                    actual_seasons,
                    key=self._semester_order,
                )
            return self.context()
        return self.context()

    def list_courses(self, season: str | None = None) -> dict[str, Any]:
        requested = season or self.current_season
        season_value, season_label = self._pick(
            self._seasons(), requested, "season"
        )
        return {
            "season": season_label,
            "courses": [
                label for _value, label in self._courses(season_value)
            ],
        }

    def course_grades(
        self, course: str, season: str | None = None
    ) -> dict[str, Any]:
        requested = season or self.current_season
        season_value, season_label = self._pick(
            self._seasons(), requested, "season"
        )
        course_value, course_label = self._pick(
            self._courses(season_value), course, "course"
        )
        key = ("grades", season_value, course_value)
        with self.portal_lock:
            if key not in self.cache:
                grades = self.portal.get_previous_grades(
                    season_value,
                    course_value,
                    tries=2,
                    delay=60,
                )
                self.cache[key] = {
                    "season": season_label,
                    "course": course_label,
                    "assessments": [
                        {
                            "assessment": item.assessment,
                            "element": item.element,
                            "grade": item.grade,
                            "evaluator": item.evaluator,
                        }
                        for item in grades.items
                    ],
                    "midterm_results": grades.percentages,
                }
            return self.cache[key]

    def list_transcript_years(self) -> list[str]:
        available = {
            label.casefold(): label for _value, label in self._years()
        }
        return [
            available[year.casefold()]
            for year in self.transcript_window_years
            if year.casefold() in available
        ]

    def transcript(self, year: str | None = None) -> dict[str, Any]:
        requested = year or self.advisory_year
        year_value, year_label = self._pick(
            self._years(), requested, "transcript year"
        )
        key = ("transcript", year_value)
        with self.portal_lock:
            if key not in self.cache:
                transcript = self.portal.get_transcript_year(
                    year_value, tries=2, delay=60
                )
                self.cache[key] = {
                    "year": year_label,
                    "cumulative_gpa": transcript.cumulative_gpa,
                    "courses": [
                        {
                            "semester": row.semester,
                            "course": row.course,
                            "grade": row.grade,
                            "numeric": row.numeric,
                            "hours": row.hours,
                            "group": row.group,
                        }
                        for row in transcript.rows
                    ],
                }
            return self.cache[key]

    def find_transcript_course(
        self, course: str, year: str | None = None
    ) -> dict[str, Any]:
        data = self.transcript(year)
        needle = course.strip().casefold()
        return {
            "year": data["year"],
            "query": course,
            "matches": [
                row
                for row in data["courses"]
                if needle in row["course"].casefold()
            ],
        }

    def transcript_snapshot(self) -> dict[str, Any] | None:
        """Return already-loaded transcript evidence without portal I/O.

        Login and dashboard loading usually cache at least one transcript year.
        Interactive career searches should use that snapshot immediately
        instead of waiting behind a slow or retrying portal request.
        """
        with self.portal_lock:
            complete = self.cache.get("full_transcript")
            if complete is not None:
                return complete
            cached_years = [
                value
                for key, value in self.cache.items()
                if isinstance(key, tuple)
                and len(key) == 2
                and key[0] == "transcript"
                and isinstance(value, dict)
            ]
        if not cached_years:
            return None

        requested = {
            year.casefold() for year in self.transcript_window_years
        }
        cached_years = [
            value
            for value in cached_years
            if str(value.get("year", "")).casefold() in requested
        ]
        cached_years.sort(
            key=lambda value: self._academic_year_start(
                str(value.get("year", ""))
            )
        )
        if not cached_years:
            return None

        loaded_years = [str(value["year"]) for value in cached_years]
        courses = [
            {"academic_year": str(value["year"]), **row}
            for value in cached_years
            for row in value.get("courses", [])
        ]
        cumulative_gpa = next(
            (
                str(value["cumulative_gpa"])
                for value in reversed(cached_years)
                if value.get("cumulative_gpa")
            ),
            None,
        )
        return {
            "enrollment_year": self.enrollment_year,
            "requested_years": self.transcript_window_years,
            "loaded_years": loaded_years,
            "failed_years": [],
            "cumulative_gpa": cumulative_gpa,
            "courses": courses,
        }

    def full_transcript(self) -> dict[str, Any]:
        """Load every available transcript year beginning at enrollment."""
        with self.portal_lock:
            cached = self.cache.get("full_transcript")
            if cached is not None:
                return cached

        available = {
            label.casefold(): label for _value, label in self._years()
        }
        loaded_years: list[str] = []
        failed_years: list[str] = []
        courses: list[dict[str, str]] = []
        cumulative_gpa: str | None = None
        for expected_year in self.transcript_window_years:
            actual_year = available.get(expected_year.casefold())
            if actual_year is None:
                continue
            try:
                data = self.transcript(actual_year)
            except Exception:
                failed_years.append(actual_year)
                continue
            loaded_years.append(data["year"])
            courses.extend(
                {"academic_year": data["year"], **row}
                for row in data["courses"]
            )
            if data["cumulative_gpa"]:
                cumulative_gpa = data["cumulative_gpa"]
        if not loaded_years and failed_years:
            raise RuntimeError("No transcript year could be loaded.")
        result = {
            "enrollment_year": self.enrollment_year,
            "requested_years": self.transcript_window_years,
            "loaded_years": loaded_years,
            "failed_years": failed_years,
            "cumulative_gpa": cumulative_gpa,
            "courses": courses,
        }
        # Preserve a usable partial snapshot as well. Failed years can be
        # retried explicitly after clearing the portal cache; they should not
        # impose another 60-second retry on every career or document request.
        with self.portal_lock:
            self.cache["full_transcript"] = result
        return result

    def clear_cache(self) -> None:
        with self.portal_lock:
            self.cache.clear()
