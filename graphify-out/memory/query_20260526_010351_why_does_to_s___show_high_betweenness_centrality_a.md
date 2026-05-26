---
type: "query"
date: "2026-05-26T01:03:51.978231+00:00"
question: "Why does to_s() show high betweenness centrality across Layout/Modal and 8 other communities?"
contributor: "graphify"
source_nodes: ["to_s()", "View", "Controller", "Modal"]
---

# Q: Why does to_s() show high betweenness centrality across Layout/Modal and 8 other communities?

## Answer

Red herring — to_s() is Ruby's universal stringification method, present on every object. The high betweenness comes from duck-typed render dispatch (controller.rb:50-52: body.respond_to?(:render) ? body.render.to_s : body.to_s) and the same pattern in View#render_component, Modal, Viewport, etc. Every render path terminates in .to_s(), so shortest paths across the graph collapse onto it. This is a graph-extraction artifact, not an architectural insight. The architectural chokepoint is View (see saved Q&A from 2026-05-24 13:38). Treat to_s() as noise when scanning betweenness rankings — same goes for other universal Ruby methods (inspect, hash, ==). Architectural bridge detection: look for high-betweenness nodes that are NOT universal language methods.

## Source Nodes

- to_s()
- View
- Controller
- Modal