# Graph Report - .  (2026-05-25)

## Corpus Check
- 24 files · ~12,554 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 584 nodes · 905 edges · 46 communities (30 shown, 16 thin omitted)
- Extraction: 77% EXTRACTED · 23% INFERRED · 0% AMBIGUOUS · INFERRED: 207 edges (avg confidence: 0.83)
- Token cost: 48,809 input · 12,201 output

## Community Hubs (Navigation)
- [[_COMMUNITY_View Buffer Primitives|View Buffer Primitives]]
- [[_COMMUNITY_Framework Core & Overview|Framework Core & Overview]]
- [[_COMMUNITY_Generators & Spinner Tests|Generators & Spinner Tests]]
- [[_COMMUNITY_UI Style & Assigns|UI Style & Assigns]]
- [[_COMMUNITY_Generator File Helpers|Generator File Helpers]]
- [[_COMMUNITY_Counter Demo Controller|Counter Demo Controller]]
- [[_COMMUNITY_Command Palette Dispatch|Command Palette Dispatch]]
- [[_COMMUNITY_Viewport Scrolling|Viewport Scrolling]]
- [[_COMMUNITY_CLI & Generator Entry|CLI & Generator Entry]]
- [[_COMMUNITY_Layout & Modal Composition|Layout & Modal Composition]]
- [[_COMMUNITY_Generator Base & Naming|Generator Base & Naming]]
- [[_COMMUNITY_Charming Class Anchors|Charming Class Anchors]]
- [[_COMMUNITY_TextInput Component|TextInput Component]]
- [[_COMMUNITY_Memory Backend & Events|Memory Backend & Events]]
- [[_COMMUNITY_TTY Backend|TTY Backend]]
- [[_COMMUNITY_Routing & Router|Routing & Router]]
- [[_COMMUNITY_Runtime Event Loop|Runtime Event Loop]]
- [[_COMMUNITY_Command Palette Internals|Command Palette Internals]]
- [[_COMMUNITY_App Frame Component|App Frame Component]]
- [[_COMMUNITY_Terminal Lifecycle|Terminal Lifecycle]]
- [[_COMMUNITY_TTYBackend Spec Helpers|TTYBackend Spec Helpers]]
- [[_COMMUNITY_Home View|Home View]]
- [[_COMMUNITY_Layout & Style Specs|Layout & Style Specs]]
- [[_COMMUNITY_Repo Tooling & CI|Repo Tooling & CI]]
- [[_COMMUNITY_Charming Error & Run|Charming Error & Run]]
- [[_COMMUNITY_Full Repaint Renderer|Full Repaint Renderer]]
- [[_COMMUNITY_Generators Error|Generators Error]]
- [[_COMMUNITY_Renderable Contract Q&A|Renderable Contract Q&A]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 40|Community 40]]

## God Nodes (most connected - your core abstractions)
1. `Style` - 33 edges
2. `Viewport` - 32 edges
3. `TTYBackend` - 28 edges
4. `View` - 26 edges
5. `Runtime` - 22 edges
6. `to_s()` - 21 edges
7. `List` - 19 edges
8. `TextInput` - 16 edges
9. `AppGenerator` - 15 edges
10. `MemoryBackend` - 14 edges

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
- **AppGenerator template module composition** — generators_app_generator_appgenerator, app_generator_view_template, app_generator_basic_templates [EXTRACTED 1.00]
- **Demo app feature demonstration flow** — examples_demo_app_spec, concept_command_palette, concept_viewport_scrolling, concept_timer_driven_spinner [EXTRACTED 1.00]
- **Rails-like architecture documentation set** — readme_md, roadmap_md, context_md, concept_rails_like_public_api [INFERRED 0.95]
- **DemoApp MVC request flow** — controllers_home_controller, models_home_model, views_home_view [EXTRACTED 1.00]
- **DemoApp boot sequence** — exe_demo_app, lib_demo_app, demo_app_application, config_routes [EXTRACTED 1.00]
- **Home view composition** — views_home_view, components_app_frame_component, components_activity_log_content_component, charming_components_modal [EXTRACTED 1.00]

## Communities (46 total, 16 thin omitted)

### Community 0 - "View Buffer Primitives"
Cohesion: 0.06
Nodes (25): View, ActivityLogContentComponent, Block capture via swapped output buffer, Component as empty View subclass (component-as-view duck typing), Duck-typed render dispatch (renderable seam), Stateful component milestone (TextInputComponent), ActivityLogContentComponent, ActivityLogPanelComponent (+17 more)

### Community 1 - "Framework Core & Overview"
Cohesion: 0.05
Nodes (34): Charming::Application (production class), Charming::Controller (production class), Charming::KeyEvent (production class), Charming::Router (production class), Charming::Runtime (production class), Charming Project Overview, CounterApp README example, Explicit TTY and In-Memory Backends (+26 more)

### Community 2 - "Generators & Spinner Tests"
Cohesion: 0.07
Nodes (33): AppGeneratorTemplates::BasicTemplates, AppGeneratorTemplates::ComponentTemplates, AppGeneratorTemplates::ControllerTemplate, AppGeneratorTemplates::ModelTemplates, AppGeneratorTemplates::ViewTemplate, Charming::CLI spec, Spinner spec, Spinner (+25 more)

### Community 3 - "UI Style & Assigns"
Cohesion: 0.09
Nodes (12): Charming::UI module, Keyword assigns as singleton reader methods, Backend seam for terminal I/O, View exposes keyword assigns as reader methods, Border, UI layout/join spec suite, UI::Style spec suite, Style (+4 more)

### Community 4 - "Generator File Helpers"
Cohesion: 0.07
Nodes (10): gemspec(), readme(), controller(), executable(), requires_for(), root_file(), version(), view() (+2 more)

### Community 5 - "Counter Demo Controller"
Cohesion: 0.07
Nodes (5): Charming module, HomeController, CounterController, CounterModel, CounterController

### Community 6 - "Command Palette Dispatch"
Cohesion: 0.09
Nodes (15): Charming top-level module / run, command_bindings(), key(), key_bindings(), Charming.run, Rails-style key bindings snapshot inheritance, Rails-inspired TUI framework direction, CounterApp (example) (+7 more)

### Community 8 - "CLI & Generator Entry"
Cohesion: 0.10
Nodes (5): CLI, Charming::Generators module, Charming::Components::CommandPalette, List, Charming::Components::TextInput

### Community 9 - "Layout & Modal Composition"
Cohesion: 0.13
Nodes (14): block_height(), block_width(), center(), draw_lines(), horizontal_line(), join_horizontal(), join_vertical(), normalize_blocks() (+6 more)

### Community 10 - "Generator Base & Naming"
Cohesion: 0.12
Nodes (3): Base, Name, ViewGenerator

### Community 11 - "Charming Class Anchors"
Cohesion: 0.12
Nodes (23): Charming::Application, Charming::ApplicationModel, Charming::Component, Charming::Components::Spinner, Charming::Components::Viewport, Charming::Controller, Charming::UI, Charming::View (+15 more)

### Community 13 - "Memory Backend & Events"
Cohesion: 0.13
Nodes (4): Charming::KeyEvent, Terminal Backend Interface, CounterApp, MemoryBackend

### Community 15 - "Routing & Router"
Cohesion: 0.20
Nodes (4): routes(), Charming::Router::Route (Data class), Router, MVC-like routing/controller pattern

### Community 16 - "Runtime Event Loop"
Cohesion: 0.24
Nodes (4): Charming::Response, Runtime, Charming::Screen, Terminal event loop with dispatch

### Community 23 - "Repo Tooling & CI"
Cohesion: 0.50
Nodes (4): bin/console IRB launcher, bin/setup script, RuboCop Style Configuration, GitHub Actions Ruby CI Workflow

## Knowledge Gaps
- **44 isolated node(s):** `Error`, `Charming::Router::Route (Data class)`, `Charming::ResizeEvent`, `Terminal event loop with dispatch`, `RuntimeSpecApp (test application)` (+39 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **16 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `View` connect `View Buffer Primitives` to `Framework Core & Overview`, `Generators & Spinner Tests`, `UI Style & Assigns`, `Command Palette Dispatch`?**
  _High betweenness centrality (0.144) - this node is a cross-community bridge._
- **Why does `to_s()` connect `Layout & Modal Composition` to `View Buffer Primitives`, `Framework Core & Overview`, `UI Style & Assigns`, `Command Palette Dispatch`, `Viewport Scrolling`, `Generator Base & Naming`, `TTY Backend`, `Routing & Router`?**
  _High betweenness centrality (0.121) - this node is a cross-community bridge._
- **Why does `Runtime` connect `Runtime Event Loop` to `Framework Core & Overview`, `Generator File Helpers`, `Counter Demo Controller`, `Command Palette Dispatch`, `Memory Backend & Events`, `TTY Backend`, `Routing & Router`, `Terminal Lifecycle`, `Full Repaint Renderer`?**
  _High betweenness centrality (0.108) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `Style` (e.g. with `Charming::UI::Width` and `Modal`) actually correct?**
  _`Style` has 2 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `TTYBackend` (e.g. with `FullRepaint` and `MemoryBackend`) actually correct?**
  _`TTYBackend` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `View` (e.g. with `controller.rb` and `Rails-inspired public API principle`) actually correct?**
  _`View` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `Runtime` (e.g. with `controller.rb` and `Terminal event loop with dispatch`) actually correct?**
  _`Runtime` has 3 INFERRED edges - model-reasoned connections that need verification._