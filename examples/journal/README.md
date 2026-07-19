# Journal

A daily-writing TUI and the canonical Charming demo app — what the blog tutorial
is to Rails, this is to Charming. Write entries in Markdown, tag them with a mood,
browse and reread them, track your streak, and export everything to a Markdown file.

```sh
bundle install
bundle exec charming db:setup   # create + load schema + seed
bundle exec journal
```

## Keys

| Key | Where | Does |
|---|---|---|
| `j` / `k`, arrows | lists & reading | move / scroll |
| `enter` | list | open entry |
| `n` | list | new entry |
| `e` | reading | edit entry |
| `f` | list & reading | toggle favorite (with toast) |
| `d` | list & reading | delete (confirm modal) |
| `x` | stats | export journal to `tmp/journal_export.md` |
| `tab` | everywhere | cycle focus (content ↔ sidebar) |
| `ctrl+p` | everywhere | command palette (fuzzy search) |
| `?` | everywhere | keyboard shortcut overlay |
| `enter` | compose body | new line (twice for a blank line) |
| `tab` | compose | next field |
| `ctrl+s` / `esc` | compose | save / cancel |
| `q` | everywhere | quit |

## What it exercises

Every major framework feature, on purpose — this app doubles as Charming's
integration test:

- **Generators** — the app, model, migrations, and stats screen were scaffolded
  with `charming new --database sqlite3`, `g model`, `g migration`, and `g screen`
- **ActiveRecord** — validations, scopes, seeds, env-specific databases,
  `db/schema.rb`, transactional test isolation
- **Controller hooks** — `before_action` loads entries; `rescue_from
  ActiveRecord::RecordNotFound` renders a friendly screen for bad ids
- **Forms** — compose is a `form(:entry)` with input/select/textarea/confirm,
  validation, and edit-mode pre-seeding
- **Components** — List, EmptyState, Markdown, Viewport, Modal, Toast, StatusBar,
  Breadcrumbs, Badge, Progressbar, HelpOverlay, ActivityIndicator, plus a custom
  app component (`DeleteConfirm`) that captures keys via a modal focus scope
- **Async tasks** — the stats export streams per-entry progress
  (`run_task` + `on_task_progress`) into a live Progressbar and finishes with a toast
- **Theming** — four built-in themes plus one derived via `extends:`; switch live
  from the command palette
- **Session persistence** — your theme survives restarts (`tmp/session.json`)

## Tests

```sh
bundle exec rspec
```

Specs run against `db/test.sqlite3` (the generated `spec_helper` pins
`CHARMING_ENV=test`, loads the schema, and rolls back each example).
`spec/journeys_spec.rb` drives the whole app through a `MemoryBackend` —
real keystrokes, full runtime, no TTY.
