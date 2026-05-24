---
type: "query"
date: "2026-05-24T14:00:11.954082+00:00"
question: "Why did View's betweenness centrality jump from 0.287 to 0.363 with the Component addition, and what is Component for?"
contributor: "graphify"
source_nodes: ["View", "Component", "Controller", "CounterCardComponent", "CounterView"]
---

# Q: Why did View's betweenness centrality jump from 0.287 to 0.363 with the Component addition, and what is Component for?

## Answer

Component is currently an empty View subclass (lib/charming/component.rb, 4 lines). The betweenness jump comes from a NEW METHOD on View, not from Component itself: View#render_component at view.rb:41-43 implements the same duck-typed pattern as Controller#render_body — component.render.to_s. This creates a SECOND render seam stacked below the Controller-View seam. examples/counter.rb refactor demonstrates: CounterController -> render CounterView.new -> CounterView#render calls render_component CounterCardComponent.new -> CounterCardComponent#render does the box/style work. The chain went from 1-hop (Controller→View→UI) to 2-hop (Controller→View→Component→View-methods→UI). Every shortest path from Controller-side to Style-side now traverses View twice: once as render_component, once via inherited methods on View that Component inherits. Component itself adds zero behavior — it's a name/type/future-extension-point. The Component/View distinction is committed at API level before implementation diverges, so future stateful Components won't break user code subclassing Charming::Component. Architectural pattern: recursive renderable contract — anything responding to #render is composable. Cost: each new layer adds betweenness to View. Fragility: spec/component_spec.rb only tests inheritance, so reverting Component to a View alias would still pass; needs behavior spec once Component diverges. ALSO AUDIT NOTE: confirmed graph has ~10 ghost-duplicate node pairs (charming_view_view_render AST vs charming_view_render semantic, etc.) because AST and semantic extractors disagreed on whether to include class name in entity portion of node ID. Community 6 (23 nodes) is mostly populated by these duplicates; should fix with graphify extract --force.

## Source Nodes

- View
- Component
- Controller
- CounterCardComponent
- CounterView