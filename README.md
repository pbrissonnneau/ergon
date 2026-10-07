# Overdue

A fast, fully offline task manager for **Windows, Ubuntu/Linux and Android**, built with Flutter.

- **100% offline.** No accounts, sync, cloud, analytics, telemetry, crash reporting or ads. The app makes no
  network requests; the Android release manifest explicitly removes the `INTERNET` permission.
- **Local data only.** One SQLite database in the per-user application data directory. No admin/root rights.
- **One code base.** Domain logic, database, recurrence engine, agenda, search and almost all UI are shared;
  platform features sit behind a single interface.

## Features

| Area | What you get |
|---|---|
| Projects | Kanban board: one vertical column per project (plus *No project*). Drag cards between columns to move tasks (long-press on touch), collapse a column into a thin strip, add a task directly in a column, or open a project as a list. Each task shows its project colour in the agenda, lists and overlay. |
| Tasks | Title, Markdown description, project, type, status, priority, optional due date (date only or date + time), reminders, recurrence, subtasks, created/updated/completed timestamps. |
| Types | One-time, Ongoing (background, optionally undated), Recurring. |
| Statuses | Not Started, In Progress, Completed, Suspended, Waiting, Blocked, Cancelled. Completed/cancelled work is kept as history. |
| Priorities | Low, Normal, High, Urgent. |
| Subtasks | Any task can have subtasks with their own status, priority, due date and reminders; drag to reorder. |
| Recurrence | Daily, every N days, weekly, selected weekdays, every N weeks, monthly on a day (or last day), n-th weekday of the month, every N months, yearly; optional end date or count. A recurring task stays one task and materialises individual **occurrences** that are completed independently. |
| Reminders | Several per task: at a date/time, relative to the due time (e.g. 7 days / 2 hours before), or repeating on their own schedule (e.g. every day at 19:00, also without a due date). Notifications offer **Open**, **Complete** and **Snooze**. |
| Agenda | *Today* (urgent, due today, ongoing, recurring), *Overdue*, and optional *Upcoming* days (none / tomorrow / 3 / 7 / 14 / 30). Complete, change status/priority, snooze and expand subtasks inline. Completed work stays visible (green) for the rest of the day and disappears the next day; remove it earlier with its ×. Unfinished work is never dropped: it moves to *Overdue*. Postpone a task with its ↷ button (tomorrow, next Monday, a date or the backlog) or by dragging it onto another day; it leaves a red struck-through trace ("Postponed to Thu") on the day it left until the end of the day, and in the history. |
| Backlog | Open tasks without a date stay visible next to the agenda (side panel on wide windows, a section below the agenda on phones; toggle with the inbox button). Plan one by dragging it onto a day of the agenda or the mini calendar, or with its calendar button; drag a dated task back onto the backlog to remove its date. |
| Search | Instant full-text search (SQLite FTS5, prefix matching) across titles, descriptions and project names, combinable with project / status / priority / type / due date / completion filters and sorting. |
| Desktop overlay | Compact, movable, resizable, optionally always-on-top agenda summary with the mini calendar; click the circle to mark a task done (green check), type a title in the field at the bottom and press Enter to add a task for today, click an item to open it in the main app, right-click for Complete / Reschedule / Priority (right-click *OVERDUE* to move them all), drag a line onto a day square to move it. Shown by default when Overdue starts (its × hides it until the next start); the overlay button at the top right of the main window brings it back on top. Remembers position/size, opacity and visibility; can start at login. |
| Android widget | Home-screen widget with today's and overdue tasks; tap to open a task, **+** to create one. |
| Calendar | A month view (*Calendar* tab): one square per day with its tasks as tiny cells in project colours; opens on the current month with today highlighted. Click a day for its panel, double-click to add a task, drop a task (e.g. from the backlog shown beside it) on a day to move it. |
| Mini calendar | 14 grey squares (from 3 days ago; weekends darker) split into tiny cells in project colours (done = solid; a small number when there are too many). Hover for the list, click for the day, double-click to add a task on that day, drop a task on a day to move it. |
| History | Scroll *up* in the agenda to go back in time, day by day, through what was completed (weekly review). |
| Bulk actions | *Overdue ⋯*: move all overdue to today / tomorrow / next Monday / a date. Multi-select (toolbar button or Ctrl+click) to reschedule, change priority or project, or complete. Recurring occurrences are skipped rather than moved. |
| Drag and drop | Desktop: in the agenda, drag to reorder tasks within a day (the order is remembered) or onto another day to change its due date; drag onto a project (a drop bar appears), a project column, or a day of the mini calendar. |
| Follow-up | *Close + follow-up tomorrow* (right-click in the app or the overlay): completes the task and creates “[FU] title” for tomorrow in the same project. |
| Activity export | Optional (*Settings → Activity export*): a small YAML file per month or week with the tasks completed, postponed and created, written to a folder you choose when the period ends; *Export now* writes the current period so far. |
| Backups | Daily automatic copy of the database (default *Documents/Overdue backups*, 30 kept), *Back up now*, and *Restore* (a safety copy of the current data is made first). |

Keyboard (desktop): `Ctrl+Alt+N` new task from anywhere (Windows global shortcut; on Linux bind a system shortcut to `overdue --new-task`), `Ctrl+N` new task, `Ctrl+Enter` saves (new-task dialog and editor, also from description fields), `Ctrl+F` search,
`Ctrl+1…5` switch sections, `Esc` closes the editor.

## Building

Requires Flutter 3.47+ (Dart 3.13+).

```sh
flutter pub get
flutter test                      # 134 tests: domain, database, reminders, migrations, UI, privacy
flutter build linux --release     # Ubuntu: needs clang, cmake, ninja, libgtk-3-dev
flutter build windows --release   # on Windows with Visual Studio (Desktop C++)
flutter build apk --release       # Android SDK + NDK
```

Linux per-user install (no root): `linux/packaging/install-user.sh` copies the bundle to `~/.local/share/overdue`
and adds a desktop launcher (with *New task* and *Show overlay* actions).

Notes:
- The `sqlite3` package's build hook fetches a prebuilt SQLite library **at build time**. The built
  application itself never accesses the network.
- `timezone` (required by the notification plugin) depends on `http` only for its web entry point, which is never
  imported; `test/privacy_test.dart` guards this.
- Generated code (`*.g.dart`, `test/drift/generated/`) is committed. After changing tables run
  `dart run build_runner build` and see *Database migrations* below.
- Run the tests in DST-heavy zones too, e.g. `TZ=Europe/Paris flutter test` or `TZ=Australia/Lord_Howe flutter test`.

## Windows test builds (CI)

`.github/workflows/release-windows.yml` analyses and tests the code on Ubuntu, then builds the Windows app and
publishes it as an **AES-256 encrypted 7z archive** (file names encrypted too).

1. Once: add the repository secret `RELEASE_ARCHIVE_PASSWORD` (*Settings → Secrets and variables → Actions*).
2. Push, or run *Actions → Windows release → Run workflow*. Pushing a `v*` tag also attaches the archive to a
   GitHub Release.
3. Download the artifact from the run page, unzip the GitHub wrapper, then open `overdue-windows-x64-*.7z` with 7-Zip
   using your password and run `overdue.exe` (keep the folder together; no installation or admin rights needed).
   A `.sha256` checksum is included.

## Command line (desktop)

```
overdue                  open the main window, or focus the running one
overdue --open-task=ID   open a task (forwarded to the running window)
overdue --new-task       open the quick-add dialog
overdue --overlay        run the compact overlay
```

## Architecture

```
lib/
  main.dart                     entry point: argument handling, single instance, overlay mode
  src/core/                     LocalDate / minute-of-day civil time types, injectable Clock
  src/domain/                   models, enums, RecurrenceRule + RecurrenceEngine, AgendaBuilder, TaskQuery
  src/data/                     Drift schema, migrations, repositories, live agenda service, settings
  src/services/notifications/   ReminderPlanner (pure), NotificationReconciler, gateways, payloads
  src/services/reminder_host.dart  owns reminder delivery for the process
  src/platform/                 PlatformIntegration + Android / desktop / headless implementations
  src/app/                      composition root (AppServices) and root widget
  src/ui/                       screens and widgets (agenda, tasks, projects, editor, settings, overlay)
android/…/kotlin/               MainActivity bridge + home-screen widget (RemoteViewsService)
linux/runner, windows/runner    native window setup for the overlay mode
```

Key decisions:

- **Civil time.** Due dates, occurrence dates and reminder times are stored as epoch-day + minute-of-day (wall
  clock), not instants. "Pay rent on the 25th at 09:00" stays 09:00 across timezone and DST changes. Instants are
  computed only when scheduling, with the *current* timezone. Whole-day reminder offsets ("7 days before") are
  calendar based; sub-day offsets ("2 hours before") are exact durations.
- **Bounded recurrence.** Occurrences are materialised for a rolling window (14 days, or the agenda range if larger)
  plus always the next one. Changing a rule deletes only *untouched future* occurrences; completed or edited ones
  and the past are kept. After a long absence at most ~2 months of missed occurrences are back-filled, and the agenda
  collapses them into one overdue line ("+3 missed").
- **Reminder reconciliation.** Reminder *definitions* are persisted. The planner expands them into concrete instances
  (windowed, capped below Android's alarm limit); the reconciler diffs that plan against a bookkeeping table by
  stable instance key and content signature, then schedules/cancels only the difference and cross-checks the OS's
  pending list (restoring lost alarms, cancelling orphans). It runs at start-up, on resume, after data changes
  (debounced), every 15 minutes and at midnight — idempotent, no duplicates.
- **Platform delivery.** Android and Windows schedule with the OS (fires while the app is closed; Android
  reschedules after reboot; *Complete*/*Snooze* run in a background isolate without opening the UI). Linux
  notification daemons cannot schedule, so delivery is in-process: from the main window **or** the overlay
  (whichever holds the `notifier` lock), with a 12-hour catch-up for instances missed while nothing was running.
  Enable *Start overlay when I log in* to keep reminders running without the main window.
- **Performance.** SQLite runs on a background isolate (WAL mode); every list is a live, indexed query (status/due,
  parent, project, type, occurrence status/date indexes; FTS5 for search) that only re-runs when relevant tables
  change, and widgets subscribe once per query (`LiveQuery`). Lists are lazy, tabs are kept alive, start-up defers
  everything but the first query until after the first frame. Tests assert the agenda over 10,000 tasks and FTS
  search stay fast.
- **Desktop processes.** Main window and overlay are the same executable. They coordinate through OS file locks
  (`main`, `overlay`, `notifier`) and small JSON command files in the data directory — no sockets of any kind — and
  notice each other's database writes through SQLite's `data_version`.

## Platform notes and limitations

- **Overlay on Linux** uses GTK hints (undecorated utility window, skip taskbar, keep above). X11 window managers
  honour them; Wayland compositors may ignore positioning and always-on-top, in which case the overlay behaves as a
  small normal window. The main application is unaffected.
- **Windows overlay** is a native tool window (`WS_EX_TOOLWINDOW`, topmost; no taskbar/Alt+Tab entry). The overlay
  calls `AllowSetForegroundWindow` so the main window can come to the front when you click a task.
- **Windows notifications** are registered for the current user (AUMID `Overdue.TaskManager`), no installer or
  elevation required.
- **Android** asks for notification permission and (Android 12+) exact alarms from *Settings → Check notification
  permission*; without exact alarms reminders still fire, possibly a few minutes late. Cloud backup of app data is
  disabled. Floating overlays are intentionally not provided on Android — use the home-screen widget.
- Monthly rules on days 29–31 fall on the last day of shorter months; yearly Feb 29 falls on Feb 28 in common years.

## Data location

| Platform | Location |
|---|---|
| Linux | `~/.local/share/app.overdue.overdue/` |
| Windows | `%APPDATA%\Overdue\Overdue\` |
| Android | app-private storage (excluded from cloud backup) |

The exact path is shown in *Settings → Data location*. Copy `overdue.sqlite` (with the app closed) to back up.

**Coming from Ergon** (the app's former name): on Linux and Windows, the first start without data copies the old
folder (`~/.local/share/app.ergon.ergon/`, `%APPDATA%\Ergon\Ergon\`), which is left in place; the default
*Ergon backups* / *Ergon activity* folders are renamed and the overlay's start-at-login entry is re-registered.
Old `ergon-….sqlite` backups stay listed in *Restore*. On Android the new id makes it a separate app with its own
storage: use *Back up now* in Ergon, copy the file from `Android/data/app.ergon.ergon/files/backups/` to
`Android/data/app.overdue.overdue/files/backups/` (USB / file manager), then *Restore* it in Overdue.

## Database migrations

The schema version lives in `lib/src/data/migrations.dart`. To change the schema:

1. Edit the tables in `database.dart`, bump `Migrations.currentVersion`, add a `from < N` step in `onUpgrade`
   (additive / transforming only — never drop user data).
2. `dart run build_runner build && dart run drift_dev make-migrations` — stores a new snapshot in `drift_schemas/`
   and regenerates `test/drift/generated/`.
3. Extend `test/drift/migration_test.dart` (the generic test already upgrades every stored version and validates the
   resulting schema).
