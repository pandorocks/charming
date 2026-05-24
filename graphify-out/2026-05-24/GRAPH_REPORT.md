# Graph Report - .  (2026-05-24)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 246 nodes · 386 edges · 22 communities (19 shown, 3 thin omitted)
- Extraction: 78% EXTRACTED · 22% INFERRED · 0% AMBIGUOUS · INFERRED: 83 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3c42bee1`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_UI Subsystem & Counter View|UI Subsystem & Counter View]]
- [[_COMMUNITY_Application & Router|Application & Router]]
- [[_COMMUNITY_Controller & Dispatch|Controller & Dispatch]]
- [[_COMMUNITY_View & UI Rendering|View & UI Rendering]]
- [[_COMMUNITY_Architecture & README|Architecture & README]]
- [[_COMMUNITY_TTY Backend|TTY Backend]]
- [[_COMMUNITY_View Method Surface|View Method Surface]]
- [[_COMMUNITY_Renderer & Memory Backend|Renderer & Memory Backend]]
- [[_COMMUNITY_UI Layout Helpers|UI Layout Helpers]]
- [[_COMMUNITY_Tooling & CI|Tooling & CI]]
- [[_COMMUNITY_Response Object|Response Object]]
- [[_COMMUNITY_Resize Event|Resize Event]]
- [[_COMMUNITY_MIT License|MIT License]]

## God Nodes (most connected - your core abstractions)
1. `Style` - 32 edges
2. `View` - 26 edges
3. `TTYBackend` - 22 edges
4. `Runtime` - 17 edges
5. `MemoryBackend` - 14 edges
6. `Router` - 12 edges
7. `CounterCardComponent` - 12 edges
8. `measure()` - 10 edges
9. `CounterController` - 8 edges
10. `Charming::UI module` - 8 edges

## Surprising Connections (you probably didn't know these)
- `RuntimeSpecController (counter fixture)` --semantically_similar_to--> `CounterApp README example`  [INFERRED] [semantically similar]
  spec/runtime_spec.rb → README.md
- `Explicit TTY and In-Memory Backends` --rationale_for--> `Charming::Internal::Terminal::TTYBackend`  [INFERRED]
  README.md → lib/charming/internal/terminal/tty_backend.rb
- `Rails-inspired public API principle` --rationale_for--> `View`  [INFERRED]
  ROADMAP.md → lib/charming/view.rb
- `.rubocop.yml configuration` --references--> `Charming top-level module / run`  [INFERRED]
  .rubocop.yml → lib/charming.rb
- `Backend seam for terminal I/O` --rationale_for--> `Charming::UI module`  [INFERRED]
  ROADMAP.md → lib/charming/ui.rb

## Hyperedges (group relationships)
- **Counter request render flow (Controller -> View -> Component)** — examples_counter_counter_card_component, examples_counter_counter_controller, examples_counter_counter_view [EXTRACTED 1.00]
- **Renderable duck-typing seam (Component, View, render_component, controller dispatch)** — charming_component_component, charming_view_view, charming_view_view_render_component [INFERRED 0.85]
- **Component inherits full View surface (assigns + helpers)** — charming_component_component, charming_view_view, charming_view_view_define_assign_readers [INFERRED 0.85]

## Communities (22 total, 3 thin omitted)

### Community 0 - "UI Subsystem & Counter View"
Cohesion: 0.08
Nodes (23): View, Block capture via swapped output buffer, Component as empty View subclass (component-as-view duck typing), Duck-typed render dispatch (renderable seam), Keyword assigns as singleton reader methods, Stateful component milestone (TextInputComponent), Charming Roadmap, CounterCardComponent (+15 more)

### Community 1 - "Application & Router"
Cohesion: 0.11
Nodes (5): Border, UI::Style spec suite, Style, measure(), strip_ansi()

### Community 2 - "Controller & Dispatch"
Cohesion: 0.10
Nodes (20): Charming top-level module / run, Charming.run, key(), key_bindings(), Charming::UI module, Rails-style key bindings snapshot inheritance, Rails-inspired TUI framework direction, CounterApp (example) (+12 more)

### Community 3 - "View & UI Rendering"
Cohesion: 0.09
Nodes (23): Charming::Application (production class), Charming::Controller (production class), Charming::KeyEvent (production class), Charming::Router (production class), Charming::Runtime (production class), Charming Project Overview, CounterApp README example, Explicit TTY and In-Memory Backends (+15 more)

### Community 4 - "Architecture & README"
Cohesion: 0.10
Nodes (8): routes(), Charming::Response, Charming::Router::Route (Data class), Router, Runtime, Terminal event loop with dispatch, MVC-like routing/controller pattern, CounterApp

### Community 5 - "TTY Backend"
Cohesion: 0.13
Nodes (5): clear_screen(), hide(), move_to(), read_keypress(), TTYBackend

### Community 6 - "View Method Surface"
Cohesion: 0.13
Nodes (3): Terminal Backend Interface, FullRepaint, MemoryBackend

### Community 7 - "Renderer & Memory Backend"
Cohesion: 0.14
Nodes (5): Charming module, Charming::KeyEvent, CounterController, CounterApp, CounterController

### Community 8 - "UI Layout Helpers"
Cohesion: 0.39
Nodes (6): block_height(), block_widths(), horizontal_line(), join_horizontal(), join_vertical(), normalize_blocks()

### Community 9 - "Tooling & CI"
Cohesion: 0.50
Nodes (4): bin/console IRB launcher, bin/setup script, RuboCop Style Configuration, GitHub Actions Ruby CI Workflow

## Knowledge Gaps
- **23 isolated node(s):** `Error`, `Charming::Router::Route (Data class)`, `Charming::ResizeEvent`, `Terminal event loop with dispatch`, `RuntimeSpecApp (test application)` (+18 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `View` connect `UI Subsystem & Counter View` to `Controller & Dispatch`, `View & UI Rendering`?**
  _High betweenness centrality (0.346) - this node is a cross-community bridge._
- **Why does `Runtime` connect `Architecture & README` to `Controller & Dispatch`, `TTY Backend`, `View Method Surface`, `Renderer & Memory Backend`?**
  _High betweenness centrality (0.220) - this node is a cross-community bridge._
- **Why does `Style` connect `Application & Router` to `Controller & Dispatch`?**
  _High betweenness centrality (0.199) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `View` (e.g. with `controller.rb` and `Rails-inspired public API principle`) actually correct?**
  _`View` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `TTYBackend` (e.g. with `FullRepaint` and `MemoryBackend`) actually correct?**
  _`TTYBackend` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `MemoryBackend` (e.g. with `FullRepaint` and `Terminal Backend Interface`) actually correct?**
  _`MemoryBackend` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Error`, `Charming::Router::Route (Data class)`, `Charming::ResizeEvent` to the rest of the system?**
  _31 weakly-connected nodes found - possible documentation gaps or missing edges._