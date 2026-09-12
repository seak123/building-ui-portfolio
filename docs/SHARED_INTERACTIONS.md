# Weapon-rack interaction through a shared item selector

[Overview](../README.md) · [中文案例](README.zh-CN.md) · [Code tour](CODE_TOUR.md) · [Tests](TESTING.md)

## Design problem

A weapon rack asks the player which eligible item to display. It needs a title, candidates, counts and a selection action. Rebuilding that presentation for each object repeats binding and lifecycle work; making the common frame understand every object's rules concentrates unrelated logic in a generic widget.

The feature uses the shared `AdditionModel`, `AdditionFrame` and `AdditionItem` surface with a weapon-rack adapter. The shared infrastructure was maintained collaboratively by the team. This is a code-focused example; the supplied screenshots do not contain a weapon-rack selector.

## Shared presentation contract

The adapter constructs `ActorGuid`, `interactionID`, `InteractionType`, `TitleName`, `TitleIcon` and `interactionData`. Rows carry an interaction `Key`, item type/count and additional command data. The common frame supplies the title and list; a row emits `Ineraction_Addition_ItemClick`. The rack adapter checks its key before handling the selection. Existing event spellings are retained.

`CheckIsCurInteractionEntity` compares object GUID and interaction type before refreshing the open panel. An empty refreshed candidate list hides the view. `AdditionFrame` checks GUID and interaction ID on a leave event, hides when the main menu opens or the HUD is unavailable, and releases its interaction-prompt hide reason on destruction.

## Preserve source-item location

`GetWeaponShelfHangData` matches hangable-item configuration to the rack's object configuration. For permitted item types it scans the bag and shortcut-bar containers. Each candidate retains **container type and zero-based container position**, not just its icon/type.

Selection calls `OnWeaponShelfHang` with the rack GUID and source information. The included C++ bridge forwards it to the existing building RPC component. The adapter does not optimistically alter the displayed world object.

## Respond to a world that changes while the panel is open

Inventory changes refresh candidates only for the active rack/type context. A positive item-change notification for the cached rack closes the active selector. If its player ID differs from the local player, it also displays an occupied-slot notice.

That response is not server-side atomicity. The notice is inside the matching-rack check but outside the active-panel check, so it can also appear after the panel stops being active. A changed inventory position between display and click remains a native/server validation concern.

## Reuse boundary and trade-offs

The reusable unit is **presenting and selecting eligible items**, not executing every object's rules. Source-container selection, configuration filtering and occupancy feedback stay in the adapter; layout, row presentation and contextual closure stay shared. Other keys in the common module are context, not additional showcased features.

Global event routing and mutable current-context data require care. The asynchronous opening callback reads current shared data without request-generation cancellation. Row clicks do not independently validate an originating object GUID. Test closing/reopening and switching racks during loading.

The cooldown setter also returns after finding the configured duration before storing it. A characterisation test records that existing behaviour; it does not establish correct cooldown enforcement or imply a delivered fix.

Tests cover filtering, source routing, occupancy feedback, context matching and shared frame closure. They do not run real UI bindings, RPCs or multiplayer concurrency. No measured performance gain or invented historical fix is claimed.
