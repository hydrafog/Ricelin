# Events contract

Ricelin persists calendar entries as a JSON array in `~/.local/state/ricelin/events.json`. Vortex reads and writes the same shape in its own `calendar.json`. The helper `ricelin-events.py` validates the shape and converts between the two files without network sync.

## Entry keys

Each entry holds `id`, `date`, `endDate`, `time`, `endTime`, `text`, and `recur`. `date` is `YYYY-MM-DD`. `endDate` is `YYYY-MM-DD` or an empty string for a single day, and holds the last day a multi-day span covers. `time` is `HH:MM` or an empty string for an all-day entry. `endTime` is `HH:MM` or an empty string for an open-ended entry. `text` is the title. `recur` is empty for a one-off entry, `year` for a yearly entry, and `month` for a monthly entry. Missing string fields read as empty strings.

## Recurrence and spans

A yearly entry appears on its month and day in every year, matched on the `MM-DD` tail. A monthly entry appears on its day in every month, matched on the `DD` tail where the day exists. A one-off entry covers the inclusive string range from `date` to `lastDay`, where `lastDay` is `endDate` when set and `date` otherwise. A recurring entry ignores `endDate`. Zero-padded `YYYY-MM-DD` keys order with plain string comparison, so span tests use no date parsing. New ids continue past the highest numeric id on disk.

## Missing and corrupt files

A missing file self-heals to an empty list. The helper creates parent directories and writes `[]` on first run, and the QML singleton does the same on `FileNotFound`. A truncated or corrupt body never wipes the in-memory list. The helper reports the failure to stderr as a typed error and the caller keeps its last-good list intact.

## Helper usage

`load_events(path)` reads and validates the file. `validate_event(obj)` checks one entry against the allowlist regex for `YYYY-MM-DD` and `HH:MM`. `to_vortex(events)` normalizes Ricelin entries for Vortex. `from_vortex(items)` normalizes Vortex entries for Ricelin. Both directions are key-for-key with empty-string defaults. The test file `test_ricelin_events.py` covers round-trip and validation with temp-file fixtures.

## See also

- `Singletons/Events.qml` implements the live list, recurrence match, and persistence.
- `Calendar.qml` renders the month grid and the day editor.
