---
type: "query"
date: "2026-05-24T13:21:21.259677+00:00"
question: "Verify the snapshot semantics of Controller.key_bindings inheritance (controller.rb:11)"
contributor: "graphify"
source_nodes: ["Controller", "CounterController"]
---

# Q: Verify the snapshot semantics of Controller.key_bindings inheritance (controller.rb:11)

## Answer

Verified by writing a Ruby script exercising 5 inheritance scenarios. Confirmed: (1) child gets a separate hash with parent bindings + own; (2) parent additions AFTER child snapshot are invisible to child; (3) three-level chains cumulate correctly; (4) siblings get independent hashes — mutating one does not affect the other. (5) Subtlety: snapshot is taken LAZILY on first read of key_bindings, not at class definition. A subclass with no  macros of its own does not snapshot until something (explicit read, dispatch_key, or a key macro) triggers it. This means parent additions BETWEEN child definition and child first-read ARE picked up, but additions after first-read are not. Behavior is order-dependent in a non-obvious way. Not a bug, but fragility worth a comment at controller.rb:11 or a spec to lock in intent. Currently no spec covers this — controller_spec.rb sits in graph community 12 with only 3 nodes and no edges into Controller.key_bindings class-side method.

## Source Nodes

- Controller
- CounterController