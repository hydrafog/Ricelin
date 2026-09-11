#!/usr/bin/env python3
"""Shared calendar contract between Ricelin and Vortex.

The file holds a JSON array of {id, date, endDate, time, endTime, text, recur}.
This helper validates the shape with allowlist regex and converts key-for-key
between Ricelin events.json and Vortex calendar.json with no network sync.
"""

import argparse
import json
import re
import sys
from pathlib import Path

DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
TIME_RE = re.compile(r"^\d{1,2}:\d{2}$")
RECUR_OK = ("", "year", "month")


class EventsError(Exception):
    """Typed failure for a corrupt or invalid events body."""


def validate_event(obj):
    """Check one entry against the allowlist; raise EventsError on failure."""
    if not isinstance(obj, dict):
        raise EventsError("entry must be an object")
    date = obj.get("date", "")
    if not isinstance(date, str) or not DATE_RE.match(date):
        raise EventsError("invalid date: %r" % (date,))
    for key in ("time", "endTime"):
        val = obj.get(key, "")
        if not isinstance(val, str) or (val != "" and not TIME_RE.match(val)):
            raise EventsError("invalid %s: %r" % (key, val))
    recur = obj.get("recur", "")
    if recur not in RECUR_OK:
        raise EventsError("invalid recur: %r" % (recur,))
    end_date = obj.get("endDate", "")
    if not isinstance(end_date, str) or (end_date != "" and not DATE_RE.match(end_date)):
        raise EventsError("invalid endDate: %r" % (end_date,))
    return True


def normalize_event(obj):
    """Return the entry with empty-string defaults for missing keys."""
    validate_event(obj)
    return {
        "id": obj.get("id", ""),
        "date": obj.get("date", ""),
        "endDate": obj.get("endDate", ""),
        "time": obj.get("time", ""),
        "endTime": obj.get("endTime", ""),
        "text": obj.get("text", ""),
        "recur": obj.get("recur", ""),
    }


def load_events(path, last_good=None):
    """Read and validate the events file.

    File-not-found self-heals to an empty list: parent dirs are created and
    the file is seeded with []. A corrupt body reports a typed error to
    stderr and preserves the caller last_good list: the error is raised as
    EventsError so the caller keeps its last-good in-memory list intact.
    """
    p = Path(path)
    try:
        raw = p.read_text(encoding="utf-8")
    except FileNotFoundError:
        # NOTE: FileNotFound (does not exist) self-heals to empty list.
        try:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("[]", encoding="utf-8")
        except OSError as exc:
            print("ricelin-events: self-heal write failed: %s" % exc, file=sys.stderr)
        return []
    except OSError as exc:
        print("ricelin-events: cannot read %s: %s" % (path, exc), file=sys.stderr)
        raise EventsError("unreadable events file: %s" % path) from exc
    if raw.strip() == "":
        return [] if last_good is None else last_good
    try:
        data = json.loads(raw)
    except ValueError as exc:
        print("ricelin-events: corrupt events body in %s: %s" % (path, exc), file=sys.stderr)
        print("ricelin-events: keeping last-good list intact", file=sys.stderr)
        raise EventsError("corrupt events body in %s" % path) from exc
    if not isinstance(data, list):
        print("ricelin-events: corrupt events body in %s: top level must be a list" % path, file=sys.stderr)
        print("ricelin-events: keeping last-good list intact", file=sys.stderr)
        raise EventsError("corrupt events body in %s" % path)
    try:
        return [normalize_event(e) for e in data]
    except EventsError as exc:
        print("ricelin-events: invalid entry in %s: %s" % (path, exc), file=sys.stderr)
        print("ricelin-events: keeping last-good list intact", file=sys.stderr)
        raise


def save_events(path, events):
    """Write the normalized list atomically."""
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_suffix(p.suffix + ".tmp")
    tmp.write_text(json.dumps(events, ensure_ascii=False), encoding="utf-8")
    tmp.replace(p)


def to_vortex(events):
    """Normalize Ricelin entries for Vortex calendar.json (key-for-key)."""
    return [normalize_event(e) for e in events]


def from_vortex(items):
    """Normalize Vortex entries for Ricelin events.json (key-for-key)."""
    return [normalize_event(e) for e in items]


def main(argv):
    parser = argparse.ArgumentParser(description="Validate and convert calendar files.")
    parser.add_argument("--in", dest="src", required=True, help="source json file")
    parser.add_argument("--out", dest="dst", required=True, help="destination json file")
    parser.add_argument("--to-vortex", action="store_true", help="convert Ricelin to Vortex")
    parser.add_argument("--from-vortex", action="store_true", help="convert Vortex to Ricelin")
    args = parser.parse_args(argv)
    try:
        events = load_events(args.src)
    except EventsError as exc:
        print("ricelin-events: %s" % exc, file=sys.stderr)
        return 2
    if args.to_vortex:
        out = to_vortex(events)
    elif args.from_vortex:
        out = from_vortex(events)
    else:
        out = events
    save_events(args.dst, out)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
