---
type: "query"
date: "2026-05-24T13:15:20.418162+00:00"
question: "Why does Runtime bridge six communities at once - TTY Backend, Memory Backend and Renderer, Application, Controller, Router, and the Counter Example?"
contributor: "graphify"
source_nodes: ["Runtime", "TTYBackend", "Controller", "Router", "FullRepaint", "Application", "CounterApp"]
---

# Q: Why does Runtime bridge six communities at once - TTY Backend, Memory Backend and Renderer, Application, Controller, Router, and the Counter Example?

## Answer

Runtime is the only class that holds long-lived references to instances from multiple communities at once. Its constructor (lib/charming/runtime.rb:9-14) wires Application (community 2), TTYBackend (community 0), FullRepaint renderer (community 1), and a Router-resolved Route (community 6) in five lines. Its run loop (lines 16-31) then instantiates a fresh Controller (community 3) per event via @route.controller_class.new(...).dispatch_key, and pipes the returned Response back to @renderer.render. The counter examples (communities 2 and 8) only see Application and Runtime — Runtime is the sole connection between them and Router/Controller/Renderer/Backend. Other god nodes (TTYBackend 23 edges, Controller 15, Router 12) cluster their edges within one community; Runtime's 17 edges span six. This is a compressed Rails-like front controller pattern: event loop + router + dispatch + render all collapsed into one class.

## Source Nodes

- Runtime
- TTYBackend
- Controller
- Router
- FullRepaint
- Application
- CounterApp