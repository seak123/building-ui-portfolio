# Refresh work: update what changed without losing state

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

## Measurement plan

Keep capacity, visible-entry count, input sequence and device constant. Record list clear/add calls, data-wrapper acquisitions, entry refreshes, Lua/native allocations and game-thread UI time separately. For placement, count native evaluation and Lua notifications separately. For production, include paused rows, reopened panels and rate changes. Only then report frame-time or allocation results.
