# Debugging through state, identity and lifetime

[Overview](../README.md) · [Tests](TESTING.md)

These examples explain inspectable behaviour and targeted checks. They are not invented historical incident timelines.

## Confirm reaches the handler, but the object should not be built

**Observed implementation:** the PC confirm handler accepts both the valid-build and invalid-build bits. Native `RequestSpawnUnit` reports the invalidity reason and returns without a spawn request.

**Investigation:** distinguish input eligibility, operation availability and placement validity. Log the input/HUD mode, operation mask, held object, `FlowUnitState` and `UnValidTag`. A clickable invalid-state action may be intentional feedback, not a missing disabled flag.

**Verification:** the Lua test checks mode gating and dispatch. Native condition/no-spawn behaviour is read from the included C++ and requires an in-engine test; the Python harness does not execute C++.

## A notification from another station must not close this panel

**Implemented protection:** `OnBuildInteractionLeave` compares both GUID and interaction ID before hiding. `OnQueueWorkEntityWorkDataChanged` compares the GUID before refreshing.

**Verification:** tests vary matching and mismatched identities. The create-response handler is weaker: it filters success and interaction ID, not building GUID or request generation. A delayed response after switching stations is therefore a useful runtime regression target, not a protection already established by this case.

## A missing-material button should explain the recovery path

**Implemented behaviour:** `GetCraftProduceItemState` distinguishes unlock, making conditions and materials. Queue capacity is applied in `GetBtnState`. The material-shortage action opens material tracking with the selected quantity instead of sending a production command.

**Verification:** tests cover eligibility precedence, full-queue precedence, normal dispatch and material-tracking dispatch. `GetBtnState` returns Normal when the native work entity is absent; the separate locked-recipe view switch also matters. Do not interpret that one method as a complete validation gate.

## Storage refresh should not rebuild the list on every transfer

**Implemented behaviour:** stable positive capacity takes the reuse path and refreshes displayed entries. The [performance chapter](PERFORMANCE.md) explains costs and assumptions.

**Verification:** instrument list population and row refresh, then change contents without changing capacity. Separately test capacity changes, switching to another box of the same size, and native-container disappearance. The first two population paths are covered locally; switching/disappearance needs the full lifecycle contract.

## A shared selector can outlive its original context

The weapon rack handles matching-object occupancy notifications, but a client click is not an atomic reservation. Check inventory movement between display and selection, another player's occupation of the rack, and object switches during asynchronous loading. The common cooldown setter has an early return before storing a configured duration. [Current-code observations and test boundaries](SHARED_INTERACTIONS.md).

## A workbench panel should not immediately close at the interaction boundary

The selected equipment/crafting workbench opening methods use the interaction distance plus a 30-unit leave margin. Test opening at the boundary, small movement, moving fully away and cleanup. This applies to a world-object crafting screen, not the character equipment slots. [Workbench example](WORKBENCH_INTERACTIONS.md).

## Remaining lifecycle checks

- `BoxModel:SetBoxInteractiveState(true)` requests entry and then clears its stored GUID/config; the false branch requests exit. The visible frame destruction calls the false branch. Retained names alone do not establish the complete entry sequence.
- A unique asynchronously created frame can still complete after the original open intent has changed. Test close/reopen and station switching during loading.
- Queue-row progress divides by native total workload without a local zero guard or clamp. Validate configuration and overshoot expectations; do not silently change the excerpt to suggest a delivered fix.
- The queue row declares an `Event` setting while other behaviours use `Events`. Confirm that the shared runtime accepts that key before relying on the re-anchoring subscription. Method-level tests do not validate framework binding.

These are explicit integration questions, not claims of confirmed production crashes. They keep the implemented paths separate from proposed hardening.
