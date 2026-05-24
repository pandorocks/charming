---
type: "query"
date: "2026-05-24T13:18:02.769382+00:00"
question: "Where does counter state survive between keypresses, given Controller is instantiated fresh per event?"
contributor: "graphify"
source_nodes: ["Application", "Controller", "CounterController", "Runtime"]
---

# Q: Where does counter state survive between keypresses, given Controller is instantiated fresh per event?

## Answer

State lives in Application#@session, a plain Ruby hash created once in application.rb:15-17. The Application instance is created at process start (Charming.run(CounterApp.new)) and held by Runtime as @application across the entire run loop (runtime.rb:10). Fresh Controllers receive that same Application by reference at runtime.rb:36 and runtime.rb:40. Controller#session (controller.rb:42-44) is a delegate to application.session, so session[:count] += 1 in CounterController#increment mutates the Application-owned hash. Two layers of persistent state: (1) Application#@session — per-run, mutable, lives because Runtime keeps the reference; (2) class-level state — Controller.key_bindings and Application.routes — initialized once at class load. Non-obvious detail at controller.rb:11: @key_bindings ||= superclass.key_bindings.dup means each subclass takes a snapshot at first read, not a live reference. Minor smell: Controller#dispatch returns response || render('') (controller.rb:26), so an action that forgets to call render silently produces a blank screen rather than an error.

## Source Nodes

- Application
- Controller
- CounterController
- Runtime