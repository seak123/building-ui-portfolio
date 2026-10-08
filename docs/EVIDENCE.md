# Evidence and implementation scope

[Portfolio overview](../README.md) · [Code tour](CODE_TOUR.md) · [Verification](TESTING.md)

## Historical work and code

This case describes specific past ProjectZ work, using the development account and checked implementation relationships. Selected Lua implementations retain module paths and calls. Native declarations and bridges include shortened interface outlines; omitted bodies are marked in the files.

The full Unreal runtime, services, binary UMG assets and complete shared inventory framework are outside this export. Box-side and bag-side binders remain distinct in the excerpts. [Dependency and implementation map](DEPENDENCIES.md).

## Historical system design

The system-design, spatial-rule, lifecycle/LiteMass and authoring chapters describe past work using the author's development account, contemporary design material and checked implementation relationships. They extend the context of the UI excerpts; they do not add full implementations of persistence, early placement rules, LiteMass or navigation to this repository.

The **early fixed-space version** and the **later free-form version** are separate stages. The SpaceUnit/Pivot/Space diagrams explain the early model; the public gameplay screenshots show later interfaces. The diagrams' sizes, subdivisions and arrangement are illustrative, not exact configuration or engine output. The early content path includes delivered runtime debugging; occupancy-painting and further authoring tools were future directions at that stage.

The new SVG and Mermaid illustrations were redrawn for explanation. Original internal slides, original prototype footage, source-history records and internal code screenshots are not included. The comparison with object-owned sockets is a comparison of design approaches, not a claim about another game's private implementation.

The five system responsibilities are architectural boundaries, not a claim that every historical call site was perfectly isolated. LiteMass is a shared framework described through its building-system integration. The tools team implemented the level-editor build/export stage of the whole-building content workflow.

## Verification and performance

Focused tests and instrumentation were added for this portfolio. They execute selected methods with controlled dependencies; they are not historical project tests, a complete runnable game or full Unreal validation. Any separately written reference material is explanatory rather than original game code.

The [test chapter](TESTING.md) records the executed checks and their boundaries. The [storage-cost discussion](PERFORMANCE.md) distinguishes record reuse from full-slot scanning. The navigation section describes historical profiling and optimisation work; original profiling captures are not reproduced and the current portfolio does not execute a navigation benchmark. No numerical FPS, CPU-time, bandwidth, development-time or defect-count improvement is established by these materials.

## Visual material

The [gallery and sources](../media/README.md) identify public gameplay footage and separately label the explanatory design illustrations. Original screenshot pixels and creator watermarks are preserved. Screenshots illustrate separate UI states, not a continuous interaction recording, a before/after fix or a verified match to the included code version. The weapon rack and semi-finished-goods queue are code-only supporting examples.

Game visuals and project material remain subject to their respective rights.
