# Case study — a building is both a world object and an interface

[Overview](../README.md) · [Architecture](ARCHITECTURE.md)

## Context

Players choose objects from a catalogue, place them in a three-dimensional world and then use what they built. The UI therefore spans catalogue navigation, placement feedback, HUD/input modes, world interactions and specialised panels. A processing station exposes recipes and a queue; a storage box exposes containers and transfer actions.

The work connected gameplay implementation with these interfaces. A useful boundary was to share framework services and state contracts while keeping object-specific actions explicit. A generic frame alone cannot explain whether a player is positioning an object, producing materials or transferring an item.

## 1. From catalogue selection to placement

**Problem.** Catalogue selection, the held preview and available actions can diverge. Changing categories must retire the previous selection; a keyboard shortcut should not act through an unrelated open panel; invalid placement needs an explanation rather than a silent button.

**Implementation.** `BuildSpaceModel` coordinates menu, catalogue and object selection. Selection passes into the native `PzBuildHoldFlowSystem`; clearing it also clears the held object. Custom selection callbacks support specialised entries without duplicating the entire catalogue.

The native flow separates position detection, condition checking, available operations and assistance drawing. `Flow_UpdateOperationUI` builds a bitmask from held/selected objects, validity and other conditions, and notifies Lua only when that mask changes. `RefreshOperateState` maps those bits to controls.

For PC actions, `CheckBuildActionValid` checks three different facts: PC interaction is active, the frame manager is in the building HUD state, and the native mode permits the action. Individual handlers then check the appropriate operation bit. This keeps a shared shortcut from bypassing the current interaction context.

**A subtle design choice.** Confirm is routed for both `CAN_BUILD` and `CANT_BUILD`. This is not permission to spawn an invalid object. `PlaceUnit` delegates to the native request path, where `RequestSpawnUnit` reports the stored invalidity reason and returns. The UI offers feedback while the native condition path controls whether a request is made. Moving an existing object is a separate branch.

**Result and trade-off.** The catalogue, operation controls and world preview have an inspectable contract. The bitmask is compact and cheap to compare, but requires stable enum definitions on both sides and is not a full state model for every possible mode. UI mode checks and native validation remain complementary.

## 2. A processing station with a meaningful primary action

**Problem.** A recipe may exist but be locked, hidden by conditions, impossible at the current station level, missing materials or blocked by queue capacity. Making every blocked state look the same leaves players unsure what to do next.

**Implementation.** The open-panel contract supplies `PieceID`, `PieceGuid` and `InteractionID`. `BuildProduceModel` constructs recipe data, filters display conditions and derives eligibility in a defined order: configuration → unlock → making conditions → materials. The frame combines this with queue capacity to determine the primary action.

Insufficient materials changes the action to material tracking. A full queue disables production. Condition failures produce a specific requirement message. Changing the requested quantity re-evaluates cost and state. Starting production sends the building GUID, interaction, recipe and quantity into `PzBuildInteractionSystem`; collecting sends queue-slot indices. Neither path grants inventory from the UI.

Queue rows show native work state and locally advance the displayed workload while doing work. Work-data refresh can re-anchor that presentation. Doing, paused and done are different states; locally filling a progress bar does not make a product collectable. The collection action queries the native entity's available finished quantity.

**Lifecycle.** The panel closes on a leave event only when both the object GUID and interaction ID match. Queue refresh filters by GUID. The amount-edit delegates and row tick delegate have explicit destruction cleanup.

**Result and trade-off.** The interface connects the reason an action is blocked to a useful response. It retains separate catalogue/recipe state and button state, so their contract must remain clear: a locked recipe is handled by a separate view switch, not a dedicated branch in `GetBtnState`. Some late-response and missing-entity assumptions need runtime validation; they are listed in [Debugging](DEBUGGING.md).

## 3. Storage: several gestures, one transfer boundary

**Problem.** Double-click, item-detail actions, drag/drop and bulk operations all work on the same underlying inventory. A local widget change cannot stand in for a confirmed transfer. Switching or walking away from a box also changes the validity of the interaction.

**Implementation.** `BoxModel` keeps the current box identity and dispatches operations. `StorageBoxFrame` composes box, bag and other inventory views. Its periodic range check hides the frame when the player leaves the interaction area; destruction requests exit from the box interaction.

Native `OnBoxDragMoveItem` distinguishes four routes: reorder inside the box, move out, move in, and move between the player's own containers. Both drag/drop and fast-deposit routes converge on `MoveToStorageBox`, which applies a common eligibility check and reports a UI error before dispatching a request. The included server quick-withdraw excerpt also checks that the box permits withdrawal and that a personal box belongs to the requesting player. This is not a complete server-security audit.

The storage view refreshes from container data, filters box-update notifications by GUID and retains existing slot-data objects when capacity has not changed. That last choice is a concrete optimisation of the refresh path, examined in [Performance](PERFORMANCE.md).

**Result and trade-off.** Gestures remain presentation choices; transfer meaning remains explicit in the command path. Reusing slot data reduces rebuild work, but still scans container slots and assumes capacity correctly indicates when the data structure must be rebuilt. It is not an incremental inventory diff.

## Cross-discipline workflow

The shared Lua/UMG framework was maintained collaboratively by the team. Widget names, child behaviours, event bindings, frame creation and list-data adapters form the integration contract. Designers can iterate on recipe conditions and feedback; UI artists can work on layout and animation; engineering keeps world identity, input state and request semantics consistent. Specialised panels reuse those facilities without losing their own lifecycle and action rules.

## What the case establishes

The selected code demonstrates cross-layer feature implementation, input-context checks, rule-driven controls, world-bound panel lifetimes and selective refresh work. The accompanying tests exercise specific paths in isolation. No measured frame-time reduction, historical bug-count reduction or complete in-engine validation is claimed.
