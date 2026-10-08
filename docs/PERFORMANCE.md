# Performance work: UI refresh and dynamic world changes

[Overview](../README.md) · [Storage implementation](../Content/Lua/GameLogics/StorageBox/StorageBoxWidget.lua) · [Tests](TESTING.md)

## Storage list: preserve structure, refresh content

Repeated container updates do not necessarily change capacity. Rebuilding a list on every transfer would recreate its slot data and repeat native list insertion work even when the structure is unchanged.

`StorageBoxWidget:SetContainerInfo` separates two paths:

1. **First population or changed capacity:** clear list/data, construct one slot record per capacity position, obtain the native data wrapper and add each list item.
2. **Same positive capacity:** retain the slot records and update their item IDs, then enumerate `GetDisplayedEntryWidgets()` and call `UpdateView(true)` on their Lua behaviours.

`OnBoxContainerUpdate` first checks the box GUID, avoiding unrelated box refreshes. The bag side follows a related structural-reuse approach.

### What improves, and what does not

For the stable-capacity branch, the implementation avoids calls to clear/re-add the list and avoids constructing new slot records in that function. View refresh work is directed at displayed entries. It still scans all capacity positions; this is **O(capacity) data work plus displayed-entry refresh**, not O(changed slots). There is no evidence here for a specific FPS, allocation-byte or memory improvement.

The test uses an instrumented list and real `SetContainerInfo` code. It checks first population, stable-capacity refresh and a capacity change separately. Its call counts describe the fake workload only, not a device benchmark.

### Trade-offs to validate

Stable capacity is used as the structural-reuse key. It does not, on its own, prove that the box identity and every other metadata field are unchanged. The frame lifecycle must rebuild/rebind correctly when switching boxes. A missing or replaced native container also needs a defined clearing policy. Recycled offscreen entries need to bind the updated slot record when displayed.

## Placement: compare before notifying

`Flow_UpdateOperationUI` computes the current operation mask, compares it with `BuildOpStateMask` and emits `BuildSpace_OpState_Change` only when different. This reduces redundant cross-layer notifications for an unchanged operation set. It does **not** remove the per-frame placement checks, traces or assistance rendering. The `HP_CHANGE` bit also makes the mask more than a simple set of persistent permissions.

## Production: smooth presentation between data updates

The queue row's `CustomTick` handler advances displayed workload only while `IsSimulating` is true. Native work data provides the starting workload, total and rate. Paused/done binding stops simulation, and destruction clears the delegate. This separates presentation cadence from service update cadence, but does not establish the cost of all visible rows or that hidden widgets stop ticking.

## UI measurement plan

Keep capacity, visible-entry count, input sequence and device constant. Record list clear/add calls, data-wrapper acquisitions, entry refreshes, Lua/native allocations and game-thread UI time separately. For placement, count native evaluation and Lua notifications separately. For production, include paused rows, reopened panels and rate changes. Only then report frame-time or allocation results.

## Dynamic navigation and world change cost

Building was one source of a wider DS cost. Construction, terrain edits, mining and tree removal could all invalidate navigation geometry. Restoring a developed area could trigger many rebuilds together. We regenerated dynamic navigation rather than persisting all dynamic navmesh data, so managing that work was important both during normal play and when entering a populated area.

### Control when work runs

I brought rebuild requests under common management, buffered nearby-in-time changes to the same region and spread submissions across updates. Rebuild work also used background workers where appropriate. This built on the engine's navigation facilities; it was not a new asynchronous navigation engine written from scratch.

Coalescing avoided repeating work for intermediate states. Scheduling reduced concentrated DS load, but could delay navigation becoming current. Neither step made the geometry of one rebuild inherently cheaper, so it was only part of the solution.

### Reduce the work inside a rebuild

Profiling directed attention to geometry gathering and voxelisation. I worked on:

- **Simpler navigation geometry:** reduced unnecessary collision detail in vegetation and environment assets, and provided suitable simple collision for rocks rather than collecting expensive visual geometry.
- **Fewer collected shapes:** intact mineable objects used an overall simple shape instead of contributing every fragment's collision to navigation.
- **Agent-appropriate precision:** adjusted voxelisation/navigation settings for different character sizes, checking that mechanical creatures could still navigate detailed player-built structures.
- **Repeatable asset standards:** worked with environment content production on collision requirements so later content would not quietly reintroduce the same cost.

The important distinction was **scheduling versus total work**. Request buffering and background execution addressed when CPU work affected the server; geometry simplification and precision choices addressed how much work a rebuild required.

### Quality and validation

I compared profiling runs of the same scene and rebuild workload while checking path validity through buildings. Navigation freshness, narrow passages and different agent sizes were part of the acceptance criteria, not just rebuild duration. The work reduced regeneration cost in those comparisons; numerical historical results are not presented as a reproduced benchmark here. [Performance evidence scope](EVIDENCE.md#verification-and-performance).

This is a gameplay/world-system optimisation connected to building, not a claim of a Slate or UMG rendering optimisation. [Building lifecycles and scale](LIFECYCLE_AND_SCALE.md).
