# Charming TODO

Ruby TUI framework for Ruby 4+. Track of work to make this a proper production-ready framework.

## Priority 1 — Critical

- [x] Add mouse event support to TTYBackend
- [x] Add diffing renderer (or at minimum partial repaint option)
- [ ] Add API documentation and getting started guide

## Priority 2 — Important

- [x] Add Table component — most requested widget in TUI frameworks
- [ ] Add missing common widgets: progress bar, checkbox, tabs, status bar
- [x] Add formal backend interface module instead of duck-typing
- [ ] Add route parameters (`/users/:id`) for dynamic routing
- [ ] Separate view state from application state (don't store Viewport/Spinner in session)

## Priority 3 — Minor

- [ ] Fix inconsistent key types (symbols for named keys, strings for characters)
- [ ] Fix generator templates — use template engine instead of string concatenation
- [ ] Add CI/CD with GitHub Actions
- [ ] Explicitly define `module Charming` in `lib/charming.rb`
- [ ] Add fuzzy search to command palette
- [ ] Add property-based tests for UI styling system
- [ ] Add visual regression tests for rendered output

## Completed

- [ ] Clean architecture with Application → Router → Controller → Model → View → Component → UI → Backend
- [ ] Backend abstraction (TTYBackend, MemoryBackend)
- [ ] Lip Gloss-inspired styling system
- [ ] Generators for scaffolding
- [ ] Command palette with filtering
- [ ] Timer system with clock injection
- [ ] Comprehensive test suite with MemoryBackend
