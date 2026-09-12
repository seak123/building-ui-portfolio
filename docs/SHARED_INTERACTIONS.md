# One selection surface, two different interactions

[Overview](../README.md) · [中文案例](README.zh-CN.md) · [Code tour](CODE_TOUR.md) · [Tests](TESTING.md)

## Design problem

A weapon rack asks the player which item to display. An incubator asks which egg to insert. Both need a title, eligible items, counts and a selection action. Duplicating that presentation would repeat binding and lifecycle work. Making the frame understand every object's rules would instead concentrate unrelated gameplay logic in a generic widget.

The feature uses the shared `AdditionModel`, `AdditionFrame` and `AdditionItem` surface with object-specific adapters. The shared infrastructure was maintained collaboratively by the team.

## Shared contract

Each adapter constructs `ActorGuid`, `interactionID`, `InteractionType`, `TitleName`, `TitleIcon` and `interactionData`. Rows carry an interaction `Key`, item type/count and any additional command data. The shared frame supplies the title and list. A row emits `Ineraction_Addition_ItemClick`; each adapter checks its own key before handling it. Existing event spellings are retained in code.

`CheckIsCurInteractionEntity` compares both object GUID and interaction type before an adapter refreshes the open panel. An empty refreshed candidate list hides the view. `AdditionFrame` checks GUID and interaction ID on a leave event, hides when the main menu opens or the HUD is unavailable, and releases its interaction-prompt hide reason on destruction.

These responsibilities are shared. Eligibility and execution are not.

## Weapon rack: preserve the identity of the source item

`AdditionWeaponShelfModel:GetWeaponShelfHangData` first matches the hangable-item configuration to the rack's object configuration. For those permitted item types it scans the bag and shortcut-bar containers. Each candidate retains **container type and zero-based container position**, not just the item icon/type.

Selection calls `OnWeaponShelfHang` with the rack GUID and that source information. The included C++ bridge forwards it to the existing building RPC component. The adapter does not optimistically alter the displayed world object.

Inventory notifications refresh candidates only for the active rack/type context. A positive item-change notification for the cached rack closes the active selection view. If its player ID differs from the local player, it also displays an occupied-slot notice. This is useful when the world changes while the player is deciding.

**Boundary:** this client response does not prove server-side atomicity. The notice is inside the matching-rack check but outside the active-panel check; it can therefore also appear after the panel has ceased to be active. A changed inventory position between display and click remains a server-validation concern.

## Incubator: compatibility first, available slot at action time

`AdditionEggModel:RefreshPutEggData` resolves the actual incubator's configuration ID. It filters eggs by their configured incubator compatibility and by positive quantity returned by the existing totem-aware item-count service. This differs from the rack's per-container-position candidates.

When the player selects an egg, `GetNextSlotIndex` queries the native entity's current available slots. Only a non-negative result sends `SendPutEggReq(Guid, InteractionId, EggId, SlotIndex)`. The adapter then activates the use ability and plays local audio. These effects follow request dispatch, not a confirmed successful insertion.

Checking incubation is a separate world interaction. `OnEggCheck` queries native remaining time and formats a completion/minute/second notice for the **first returned incubating slot**. It is not a live progress panel or a display of all slots. Collecting uses `GetMatureCompletedSlotIndex`; a non-negative result is passed to `SendGetPalReq`. The native request adapters select the configured operation type and package the slot data for existing transport.

**Boundary:** no available slot means no request, but this method has no explicit full-slot notice. `OnPalIncubateCompleted` is empty in the included code; it must not be described as an implemented automatic refresh mechanism. A local free-slot query cannot reserve capacity against another player.

## Why these two belong together

The reusable unit is **presenting and selecting eligible items**, not a universal crafting workflow. The rack needs source-item location and occupancy feedback. The incubator needs compatibility, available capacity and a later maturity query. Their adapters express those differences without putting them into the shared frame.

This lets layout and list presentation evolve together while object rules remain separately inspectable. It also has a cost: global event routing, mutable current-context data and asynchronous frame creation require disciplined lifecycle handling. Reuse does not automatically make those paths race-free.

## Verification and remaining checks

Focused tests execute the included shared/model modules with controlled services and the frame's selected methods. They cover rack filtering/source routing, occupancy feedback, egg compatibility, current-slot selection, collection gating, notice formatting and shared frame closure. They do not run native RPCs, actual UI bindings or multiplayer concurrency.

Two useful hardening targets remain visible in the implementation:

- `ShowAdditionPanel`'s asynchronous callback reads the shared current data; it has no request-generation cancellation. Test close/reopen and switching object types while loading. Row click payloads also do not independently validate an originating object GUID.
- `SetInteractionColdTime` returns when it finds a configured duration before assigning `InteractionColdTime`. The focused test characterises that current behaviour. Do not claim that a configured cooldown is reliably enforced, or silently change the excerpt to imply a historical fix.

No frame-time gain, completed historical bug fix or complete server authority guarantee is inferred from these examples.
