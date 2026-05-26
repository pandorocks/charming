---
type: "query"
date: "2026-05-26T01:48:21.104012+00:00"
question: "Are the 3 inferred relationships involving TTYBackend (FullRepaint, MemoryBackend, Terminal Backend Interface) actually correct?"
contributor: "graphify"
source_nodes: ["TTYBackend", "MemoryBackend", "FullRepaint", "Terminal Backend Interface"]
---

# Q: Are the 3 inferred relationships involving TTYBackend (FullRepaint, MemoryBackend, Terminal Backend Interface) actually correct?

## Answer

All three verified correct against source. (1) FullRepaint->TTYBackend (0.95): full_repaint.rb:12-14 calls @output.clear / move_cursor(1,1) / write_frame(frame); all three methods exist on TTYBackend at tty_backend.rb:66,70,45. (2) MemoryBackend~TTYBackend semantically_similar (0.95): 100% method-signature match - both expose initialize, read_event, write_frame, enter_alt_screen, leave_alt_screen, show_cursor, hide_cursor, clear, move_cursor, size. README documents the intentional dual-backend pattern. (3) TTYBackend->implements->Terminal Backend Interface (0.95): MemoryBackend carries the same edge. AUDIT GAP: FullRepaint also has a 0.95 INFERRED 'calls' edge to MemoryBackend - both concrete-implementation edges are individually true (duck-typed @output) but the honest relation is FullRepaint->depends-on->Terminal Backend Interface. Graph has the abstraction node but only the two backends connect to it; FullRepaint should too. Missing edge would correctly model dependency-inversion. Pattern: when LLM extractor finds duck-typed callsites, it tends to enumerate concrete implementations rather than infer the implicit contract - watch for clusters of (Caller->ImplA, Caller->ImplB) edges that should collapse to (Caller->depends-on->Interface).

## Source Nodes

- TTYBackend
- MemoryBackend
- FullRepaint
- Terminal Backend Interface