# Case study — a building is both a world object and an interface

[Overview](../README.md) · [Architecture](ARCHITECTURE.md)

## Context

Players choose objects from a catalogue, place them in a three-dimensional world and then use what they built. The UI therefore spans catalogue navigation, placement feedback, HUD/input modes, world interactions and specialised panels. A processing station exposes recipes and a queue; a storage box exposes containers and transfer actions.

I initiated the building system and worked across gameplay and its associated UI. I also developed and maintained constructed-object interactions and panels. The key responsibility was connecting those layers into usable features, using the team's shared infrastructure.

Three decisions organise this case: derive controls from the current interaction context; give crafting requirements meaningful actions; share presentation without hiding object-specific commands.

## 1. From catalogue selection to placement

**Problem.** Catalogue selection, the held preview and available actions can diverge. Changing categories must retire the previous selection; a keyboard shortcut should not act through an unrelated open panel; invalid placement needs an explanation rather than a silent button.

**Implementation.** `BuildSpaceModel` coordinates menu, catalogue and object selection. Selection passes into the native `PzBuildHoldFlowSystem`; clearing it also clears the held object. Custom selection callbacks support specialised entries without duplicating the entire catalogue.

The native flow separates position detection, condition checking, available operations and assistance drawing. `Flow_UpdateOperationUI` builds a bitmask from held/selected objects, validity and other conditions, and notifies Lua only when that mask changes. `RefreshOperateState` maps those bits to controls.

For PC actions, `CheckBuildActionValid` checks three different facts: PC interaction is active, the frame manager is in the building HUD state, and the native mode permits the action. Individual handlers then check the appropriate operation bit. This keeps a shared shortcut from bypassing the current interaction context.

**A subtle design choice.** Confirm is routed for both `CAN_BUILD` and `CANT_BUILD`. This is not permission to spawn an invalid object. `PlaceUnit` delegates to the native request path, where `RequestSpawnUnit` reports the stored invalidity reason and returns. The UI offers feedback while the native condition path controls whether a request is made. Moving an existing object is a separate branch.

**Result and trade-off.** The catalogue, operation controls and world preview have an inspectable contract. The bitmask is compact and cheap to compare, but requires stable enum definitions on both sides and is not a full state model for every possible mode. UI mode checks and native validation remain complementary.

## 2. Equipment crafting: one action area, several meanings

**Problem.** A player may be choosing a recipe, waiting for production, dealing with a paused job, collecting output or resolving a requirement. A generic enabled/disabled button loses the meaning of those states.

**Implementation.** After opening with the workbench's world context, the product widget evaluates existing production before new-recipe requirements. Level and material failures remain actionable: they lead to workbench upgrade guidance or recipe tracking. A carry limit disables the action and is checked again by the model. Product clicks route through the panel's confirmation policy and model checks before native execution.

The execution path distinguishes native queue-backed work from local progress-driven crafting. The first dispatches a request and hides the panel; the second starts progress and updates controls. Production notifications and a scoped state poll update the action area from native job state. Collection is a separate request, not a consequence of a local timer finishing.

**Result and trade-off.** The action area explains what is possible and provides a useful next step when requirements are missing. It fits existing widgets and gameplay services, but spreads derived state across product, panel and model. The detailed chapter follows the actual methods and discusses this maintenance cost. [Workbench state and command path](WORKBENCH_INTERACTIONS.md).

## 3. A processing station with a meaningful primary action

This code-only extension covers the separate semi-finished-goods production panel.

**Problem.** A recipe may exist but be locked, hidden by conditions, impossible at the current station level, missing materials or blocked by queue capacity. Making every blocked state look the same leaves players unsure what to do next.

**Implementation.** The open-panel contract supplies `PieceID`, `PieceGuid` and `InteractionID`. `BuildProduceModel` constructs recipe data, filters display conditions and derives eligibility in a defined order: configuration → unlock → making conditions → materials. The frame combines this with queue capacity to determine the primary action.

Insufficient materials changes the action to material tracking. A full queue disables production. Condition failures produce a specific requirement message. Changing the requested quantity re-evaluates cost and state. Starting production sends the building GUID, interaction, recipe and quantity into `PzBuildInteractionSystem`; collecting sends queue-slot indices. Neither path grants inventory from the UI.

Queue rows show native work state and locally advance the displayed workload while doing work. Work-data refresh can re-anchor that presentation. Doing, paused and done are different states; locally filling a progress bar does not make a product collectable. The collection action queries the native entity's available finished quantity.

**Lifecycle.** The panel closes on a leave event only when both the object GUID and interaction ID match. Queue refresh filters by GUID. The amount-edit delegates and row tick delegate have explicit destruction cleanup.

**Result and trade-off.** The interface connects the reason an action is blocked to a useful response. It retains separate catalogue/recipe state and button state, so their contract must remain clear: a locked recipe is handled by a separate view switch, not a dedicated branch in `GetBtnState`. Some late-response and missing-entity assumptions need runtime validation; they are listed in [Debugging](DEBUGGING.md).

## 4. Storage: several gestures, one transfer boundary

**Problem.** Double-click, item-detail actions, drag/drop and bulk operations all work on the same underlying inventory. A local widget change cannot stand in for a confirmed transfer. Switching or walking away from a box also changes the validity of the interaction.

**Implementation.** `BoxModel` keeps the current box identity and dispatches operations. `StorageBoxFrame` composes box, bag and other inventory views. Its periodic range check hides the frame when the player leaves the interaction area; destruction requests exit from the box interaction.

Native `OnBoxDragMoveItem` distinguishes four routes: reorder inside the box, move out, move in, and move between the player's own containers. Both drag/drop and fast-deposit routes converge on `MoveToStorageBox`, which applies a common eligibility check and reports a UI error before dispatching a request. The included server quick-withdraw excerpt also checks that the box permits withdrawal and that a personal box belongs to the requesting player.

The storage view refreshes from container data, filters box-update notifications by GUID and retains existing slot-data objects when capacity has not changed. That last choice is a concrete optimisation of the refresh path, examined in [Performance](PERFORMANCE.md).

**Result and trade-off.** Gestures remain presentation choices; transfer meaning remains explicit in the command path. Reusing slot data reduces rebuild work, but still scans container slots and assumes capacity correctly indicates when the data structure must be rebuilt. It is not an incremental inventory diff.

## 5. Weapon rack: apply shared presentation to object-specific rules

**Problem.** A rack needs an eligible-item selector, but a generic selection widget should not own rack compatibility, source-container coordinates or world occupancy.

**Implementation.** Its adapter provides a title/list/context record to `AdditionModel` and `AdditionFrame`. Rows route selections by interaction key. Shared view logic handles contextual closure; the rack adapter retains item location and occupied-slot feedback.

**Result and trade-off.** Layout and lifecycle services remain shared while item selection and execution remain specific. Global events and mutable context still require stale-callback tests. [Full example](SHARED_INTERACTIONS.md).

## Cross-discipline workflow

The shared Lua/UMG framework was maintained collaboratively by the team. Widget names, child behaviours, event bindings, frame creation and list-data adapters form the integration contract. Designers can iterate on recipe conditions and feedback; UI artists can work on layout and animation; engineering keeps world identity, input state and request semantics consistent. Specialised panels reuse those facilities without losing their own lifecycle and action rules.

## Outcome

The work connected a building catalogue, contextual world controls and usable constructed objects. The code makes the important boundaries traceable: an input becomes an intent, an intent is checked against the current context, and the UI reflects state from the responsible gameplay system. Storage and weapon-rack examples show where shared presentation is useful and where commands must remain specific.

[Verification results](TESTING.md) separate tested excerpt behaviour from full-runtime checks. [Dependencies](DEPENDENCIES.md) defines the source-reading scope.
