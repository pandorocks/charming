# Graph Report - .  (2026-05-24)

## Corpus Check
- Corpus is ~1,832 words - fits in a single context window. You may not need a graph.

## Summary
- 146 nodes · 177 edges · 22 communities (17 shown, 5 thin omitted)
- Extraction: 85% EXTRACTED · 15% INFERRED · 0% AMBIGUOUS · INFERRED: 27 edges (avg confidence: 0.86)
- Token cost: 51,029 input · 2,686 output

## Community Hubs (Navigation)
- [[_COMMUNITY_TTY Backend & Spec|TTY Backend & Spec]]
- [[_COMMUNITY_Renderer & Memory Backend|Renderer & Memory Backend]]
- [[_COMMUNITY_Application & Counter Example|Application & Counter Example]]
- [[_COMMUNITY_Controller & Key Dispatch|Controller & Key Dispatch]]
- [[_COMMUNITY_Runtime Integration Tests|Runtime Integration Tests]]
- [[_COMMUNITY_Cross-Spec Production Refs|Cross-Spec Production Refs]]
- [[_COMMUNITY_Router & Path Resolution|Router & Path Resolution]]
- [[_COMMUNITY_Runtime Event Loop|Runtime Event Loop]]
- [[_COMMUNITY_Memory-Backed Counter Example|Memory-Backed Counter Example]]
- [[_COMMUNITY_Tooling & CI|Tooling & CI]]
- [[_COMMUNITY_Top-Level Module|Top-Level Module]]
- [[_COMMUNITY_Resize Event|Resize Event]]
- [[_COMMUNITY_MIT License|MIT License]]

## God Nodes (most connected - your core abstractions)
1. `TTYBackend` - 23 edges
2. `Runtime` - 17 edges
3. `Controller` - 15 edges
4. `MemoryBackend` - 15 edges
5. `Router` - 12 edges
6. `CounterController` - 8 edges
7. `Application` - 8 edges
8. `CounterController` - 7 edges
9. `FullRepaint` - 6 edges
10. `CounterApp` - 5 edges

## Surprising Connections (you probably didn't know these)
- `RuntimeSpecController (counter fixture)` --semantically_similar_to--> `CounterApp README example`  [INFERRED] [semantically similar]
  spec/runtime_spec.rb → README.md
- `Charming Version Spec` --conceptually_related_to--> `Charming Project Overview`  [INFERRED]
  spec/charming_spec.rb → README.md
- `Explicit TTY and In-Memory Backends` --rationale_for--> `Charming::Internal::Terminal::TTYBackend`  [INFERRED]
  README.md → lib/charming/internal/terminal/tty_backend.rb
- `Explicit TTY and In-Memory Backends` --rationale_for--> `Charming::Internal::Terminal::MemoryBackend`  [INFERRED]
  README.md → lib/charming/internal/terminal/memory_backend.rb
- `CounterController` --implements--> `Controller`  [EXTRACTED]
  examples/counter.rb → lib/charming/controller.rb

## Hyperedges (group relationships)
- **Request dispatch flow: Runtime resolves Route, instantiates Controller, returns Response** — charming_runtime_runtime, charming_router_router, charming_controller_controller, charming_response_response [INFERRED 0.95]
- **Render pipeline: Controller produces Response body, Runtime hands to FullRepaint which writes via Backend** — charming_controller_controller, charming_response_response, renderer_full_repaint_fullrepaint, terminal_tty_backend_ttybackend [INFERRED 0.90]
- **Backend abstraction with TTY and Memory implementations consumed by Renderer** — concept_terminal_backend_interface, terminal_tty_backend_ttybackend, terminal_memory_backend_memorybackend, renderer_full_repaint_fullrepaint [INFERRED 0.85]
- **Runtime End-to-End Counter Flow** — spec_runtime_spec_runtime_spec_controller, spec_runtime_spec_runtime_spec_app, terminal_memory_backend_memory_backend, lib_charming_runtime [INFERRED 0.90]
- **TTY Key Event Normalization Pattern** — terminal_tty_backend_spec_reader_stub, terminal_tty_backend_tty_backend, lib_charming_key_event [INFERRED 0.85]
- **CI Quality and Style Pipeline** — workflows_main_ci_workflow, rubocop_yml_rubocop_config, bin_setup_setup [INFERRED 0.75]

## Communities (22 total, 5 thin omitted)

### Community 0 - "TTY Backend & Spec"
Cohesion: 0.12
Nodes (5): clear_screen(), hide(), move_to(), read_keypress(), TTYBackend

### Community 1 - "Renderer & Memory Backend"
Cohesion: 0.12
Nodes (3): Terminal Backend Interface, FullRepaint, MemoryBackend

### Community 2 - "Application & Counter Example"
Cohesion: 0.14
Nodes (5): Application, routes(), Charming module, CounterApp, CounterController

### Community 3 - "Controller & Key Dispatch"
Cohesion: 0.21
Nodes (5): Controller, key(), key_bindings(), Charming::Response, MVC-like routing/controller pattern

### Community 4 - "Runtime Integration Tests"
Cohesion: 0.20
Nodes (12): Charming::KeyEvent (production class), Charming::Runtime (production class), Explicit TTY and In-Memory Backends, Charming::Internal::Renderer::FullRepaint, FullRepaint Renderer Spec, Failing Controller Restoration Test, Runtime Spec, Charming::Internal::Terminal::MemoryBackend (+4 more)

### Community 5 - "Cross-Spec Production Refs"
Cohesion: 0.18
Nodes (12): Charming::Application (production class), Charming::Controller (production class), Charming::Router (production class), Charming Project Overview, CounterApp README example, Rails-inspired Terminal UI Framework, Charming Version Spec, Controller Spec (+4 more)

### Community 8 - "Memory-Backed Counter Example"
Cohesion: 0.25
Nodes (3): Charming::KeyEvent, CounterApp, CounterController

### Community 9 - "Tooling & CI"
Cohesion: 0.50
Nodes (4): bin/console IRB launcher, bin/setup script, RuboCop Style Configuration, GitHub Actions Ruby CI Workflow

## Knowledge Gaps
- **13 isolated node(s):** `Error`, `Charming::Router::Route (Data class)`, `Charming::ResizeEvent`, `Terminal event loop with dispatch`, `RuntimeSpecApp (test application)` (+8 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TTYBackend` connect `TTY Backend & Spec` to `Memory-Backed Counter Example`, `Renderer & Memory Backend`, `Runtime Event Loop`?**
  _High betweenness centrality (0.210) - this node is a cross-community bridge._
- **Why does `Runtime` connect `Runtime Event Loop` to `TTY Backend & Spec`, `Renderer & Memory Backend`, `Application & Counter Example`, `Controller & Key Dispatch`, `Router & Path Resolution`, `Memory-Backed Counter Example`?**
  _High betweenness centrality (0.210) - this node is a cross-community bridge._
- **Why does `Controller` connect `Controller & Key Dispatch` to `Memory-Backed Counter Example`, `Application & Counter Example`, `Runtime Event Loop`?**
  _High betweenness centrality (0.144) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `TTYBackend` (e.g. with `FullRepaint` and `Terminal Backend Interface`) actually correct?**
  _`TTYBackend` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `MemoryBackend` (e.g. with `FullRepaint` and `Terminal Backend Interface`) actually correct?**
  _`MemoryBackend` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Error`, `Charming::Router::Route (Data class)`, `Charming::ResizeEvent` to the rest of the system?**
  _13 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `TTY Backend & Spec` be split into smaller, more focused modules?**
  _Cohesion score 0.12307692307692308 - nodes in this community are weakly interconnected._