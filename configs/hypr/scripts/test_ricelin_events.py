#!/usr/bin/env python3
"""AC4 checks for the shared events contract with temp-file fixtures only."""

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("ricelin_events", HERE / "ricelin-events.py")
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

EventsError = _mod.EventsError
from_vortex = _mod.from_vortex
load_events = _mod.load_events
to_vortex = _mod.to_vortex
validate_event = _mod.validate_event


class ContractTest(unittest.TestCase):
    def test_ac4_round_trip_vortex_calendar_json(self):
        events = [
            {"id": "1", "date": "2026-06-10", "endDate": "", "time": "09:00",
             "endTime": "10:00", "text": "Standup", "recur": ""},
            {"id": "2", "date": "2020-02-29", "endDate": "", "time": "",
             "endTime": "", "text": "Birthday", "recur": "year"},
        ]
        vortex = to_vortex(events)
        back = from_vortex(vortex)
        self.assertEqual(events, back)

    def test_ac4_empty_defaults_for_missing_keys(self):
        out = to_vortex([{"id": "1", "date": "2026-06-10"}])
        self.assertEqual(out[0]["endDate"], "")
        self.assertEqual(out[0]["time"], "")
        self.assertEqual(out[0]["recur"], "")

    def test_ac4_rejects_bad_date_and_time(self):
        with self.assertRaises(EventsError):
            validate_event({"id": "1", "date": "10-06-2026"})
        with self.assertRaises(EventsError):
            validate_event({"id": "1", "date": "2026-06-10", "time": "morning"})
        with self.assertRaises(EventsError):
            validate_event({"id": "1", "date": "2026-06-10", "recur": "weekly"})

    def test_ac4_missing_file_self_heals_to_empty(self):
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "sub" / "events.json"
            out = load_events(str(target))
            self.assertEqual(out, [])
            self.assertEqual(json.loads(target.read_text()), [])

    def test_ac4_corrupt_body_raises_and_caller_keeps_last_good(self):
        last_good = [{"id": "1", "date": "2026-06-10", "endDate": "", "time": "",
                      "endTime": "", "text": "Keep", "recur": ""}]
        with tempfile.TemporaryDirectory() as tmp:
            target = Path(tmp) / "events.json"
            target.write_text("{not json", encoding="utf-8")
            kept = list(last_good)
            with self.assertRaises(EventsError):
                load_events(str(target), last_good=kept)
            self.assertEqual(kept, last_good)


if __name__ == "__main__":
    unittest.main()
