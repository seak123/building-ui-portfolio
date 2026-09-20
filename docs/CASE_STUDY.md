# Case study — a building is both a world object and an interface

[Overview](../README.md) · [Architecture](ARCHITECTURE.md)

<a id="context"></a>

## Feature background

Building in ProjectZ connected construction with the use of the objects players built. Structural pieces formed the environment; functional objects opened crafting, production, storage or item-selection interactions. The feature therefore included both actions in the world and the interfaces used to control and understand them.

### What the player does

- **Build or adjust an object.** Enter building mode, browse the catalogue, select a piece, position or snap its preview and confirm placement. Existing pieces can be selected for move/remove actions. The catalogue and placement view have different controls while the world remains visible.
- **Use a constructed object.** Interacting with an equipment workbench opens product categories, progression, requirements and actions; a consumable workbench has its own crafting presentation. Processing stations show recipes and queued work. Storage boxes put box contents beside the player's inventory, while weapon racks open an eligible-item selector.
- **Respond to conditions and changing state.** Placement may be invalid, ingredients may be missing, a station may need upgrading, or production may already be running or ready to collect. The interface needs to explain the current state and offer the appropriate next action.

The [five screenshots](../media/README.md) show the catalogue, placement, equipment workbench, consumable workbench and storage. Processing queues and weapon-rack selection are supporting code examples.

### Requirements and engineering context

The system had to connect these workflows while allowing their rules and layouts to differ.

- **Controls follow the active context.** Menu navigation, a held preview and an existing world selection expose different actions. Buttons and shortcuts must agree with the current building/HUD mode and placement rules.
- **Feedback explains the next step.** A failed placement needs a reason. Missing ingredients can lead to material tracking; a level requirement can lead to upgrade guidance. Existing production and collectable output must remain distinct from the requirements for starting another craft.
- **Every interaction keeps its identity.** A panel opens for a particular world object and action. Item transfers also carry container and slot information. Leaving the object, changing selection and receiving an update all need that context.
- **Gameplay owns ongoing work and items.** Panels display production and container state and send requests. A local progress display does not award an item, and closing a panel does not itself cancel a queued job.
- **Content can keep evolving.** Designers adjust object and recipe conditions; UI artists change layouts and animation. Workbench-specific layouts can evolve locally, while storage and selectors reuse stable item conventions through the existing UI framework.

The implementation used Unreal Engine 4 with C++ world and gameplay systems, Lua models and interface behaviours, and UMG widgets. The feature integrated existing inventory, recipes, configuration and UI facilities. [Layer responsibilities](ARCHITECTURE.md#engineering-context).

### My responsibilities

I initiated the building system and developed its gameplay and associated UI. That work connected the native building flow to catalogue selection, contextual controls and player feedback. I also developed and maintained constructed-object interaction logic and panels, including workbench actions, storage transfers and shared item selection.

My feature-level decisions included where to keep specialised panels, what inventory-shaped presentation to reuse, and how unmet requirements should guide the next player action. I connected these decisions to Lua/UMG bindings, native requests, configuration and lifecycle handling so they fitted the team's existing content workflow.

The sections below expand three parts of that work: keeping placement controls consistent, making production states actionable, and sharing object interfaces where the data and interaction rules support it.

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
