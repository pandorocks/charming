---
type: "query"
date: "2026-05-24T13:38:51.491329+00:00"
question: "Why does View have higher betweenness centrality than Runtime despite fewer edges?"
contributor: "graphify"
source_nodes: ["View", "Runtime", "Controller", "Style", "Charming::UI module"]
---

# Q: Why does View have higher betweenness centrality than Runtime despite fewer edges?

## Answer

Runtime is a high-degree fan-out hub whose neighbors are internally connected to each other (Application owns Router, FullRepaint composes Backend, Controller talks to Response), so most shortest paths don't need to pass through Runtime — they take internal shortcuts. View is a low-degree chokepoint. The duck-typed render dispatch at controller.rb:50-52 (body.respond_to?(:render) ? body.render.to_s : body.to_s) is the SINGLE edge between Controller community (3) and the UI/Style/Border/Width community (1) and UI Layout Helpers community (7). View fans out into Style (via apply_style/text/box/style methods), UI.join_horizontal (via #row), and UI.join_vertical (via #column). There is no direct Controller→Style or Controller→UI edge — every shortest path between these subgraphs MUST pass through View. Architectural consequence: controller.rb does not require or mention View — they are file-level decoupled but graph-level tightly coupled. The duck-typed seam is load-bearing: a 'simplification' to body.to_s would cut every Controller→UI path. Style (degree 32, highest in the graph) is downstream of View — high degree but lower betweenness because it's a destination, not a chokepoint.

## Source Nodes

- View
- Runtime
- Controller
- Style
- Charming::UI module