# Workbench UI: turn crafting state into a useful next action

[Overview and screenshots](../README.md) · [中文案例](README.zh-CN.md) · [Code tour](CODE_TOUR.md)

## Context and contribution

The equipment workbench combines product categories, progression rows, selected-item details, materials and crafting controls. It is opened through interaction with a constructed world object. My work included development and maintenance of building-object interactions and their UI within the existing team-maintained systems.

The important engineering problem extends beyond opening a panel: **what should the player be able to do now, and what should happen if crafting cannot start?** The retained product, panel and model methods make that decision path inspectable.

## Why this panel is specialised

Weapon progression, equipment categories and data-dependent layouts required feature-specific composition and frequent iteration. I kept that complexity inside the workbench while reusing common item presentation and recipe tracking. Storage had a different boundary because its container/item data stayed consistent across object variants. [Full reuse decision](DECISIONS.md).

## 1. Establish the interaction context

Native interaction supplies the workbench GUID and operation context to `WorkBenchModel:OnSetUIVisible`. `MyShowPanel` starts a leave-distance check, initialises the selected workbench operation and asynchronously binds the panel.

The equipment workbench also has a main-menu entry point. The consumable/ammunition workbench uses `PalWorkBenchModel` with a separate panel lifecycle. The equipment action logic below is not assumed to implement both interfaces.

## 2. Distinguish an existing job from a new crafting attempt

`WorkBenchProduct:RefreshProductBtnGroupForMake` applies an ordered decision:

1. **No selected make ID:** hide the primary button.
2. **Native production in progress:** show the production/cancel action and start a state poll.
3. **Native production paused:** show the production/cancel action without that poll.
4. **Output available to collect:** show the collection action.
5. **Otherwise evaluate the selected recipe:** workbench requirement, materials, carry limit, then local crafting/start state.

Existing job state therefore takes priority over requirements for a new attempt. For example, missing materials must not replace the action for output that is already collectable, once a make ID is selected.

The inputs have different meanings. Native queries describe the interacting object's production state. `WorkBenchModel.m_State_ConditionEnough`, `m_State_MaterialEnough` and `m_State_ArriveTakeLimit` hold eligibility information for the current selection. The broader product-population path supplies those fields; its bodies are outside this excerpt. Keeping that distinction visible is essential when a button appears to show the wrong state.

## 3. Make requirements actionable

A blocked recipe does not always mean a disabled control:

- **Workbench level too low:** the button remains enabled and shows the requirement. `OnBtnMake` delegates to `WorkBenchPanel:OnBuildLvBtnClicked`, which opens the existing upgrade-guidance view with the current workbench GUID.
- **Materials missing:** the button remains enabled and opens recipe material tracking. The shared click handler also preserves the recipe, level and tracking type for its enhancement-material branch.
- **Carry limit reached:** the button is disabled. The model also rejects this condition if the handler is invoked directly.

This connects explanation to recovery: tell the player what is missing and give them the relevant next step. It also means that **enabled** is not synonymous with **will start crafting**.

## 4. Follow the command beyond the button

For an eligible make action, the included chain is:

`WorkBenchProduct:OnBtnMake` → `UIEvent_WorkBenchProduct_MakeClicked` → `WorkBenchPanel:OnBtnMake` → `WorkBenchModel:OnMakeClicked` → `func_MyMakeStart`.

The panel determines whether the selected category and first-use-experience state require confirmation. The model checks the current action state and eligibility, or delegates interruption if local crafting is already running.

The start function then separates two execution models:

- **Native queue-backed production:** dispatch the make ID, repeat count and equipment-material instance through `WorkBench_ReqMakeItemWithPal`, then hide the panel.
- **Local progress-driven crafting:** initialise local progress state, request the native progress bar, update controls and presentation, and retain the current make ID.

Cancellation and collection have their own handlers. `OnBtnInProducing` sends the current object's GUID and operation type to the cancellation event; `OnBtnMakeCanTake` requests collection for the current GUID. The interface does not grant the item itself.

## 5. Refresh from production state, not an invented completion time

`OnProduceInfoChanged` refreshes the action group. While production is active, the methods named `PalProduce_*CountDown` also poll native state once per second using a scoped timer. In this selected implementation, the timer is a **state check**, not a visible countdown calculation.

If native data says output is collectable, the action changes to collection and the timer stops. If production ends without collectable output, the action group is re-evaluated. There is no rule that awards an item because a displayed timer reached zero.

Panel cleanup stops its leave check and clears interaction context. The close threshold includes a 30-world-unit margin beyond interaction range. Local progress interruption and queue-backed production are separate lifetimes: hiding the panel after a native request does not mean cancelling the queued job.

## Result and trade-offs

The implementation provides a coherent primary-action area across crafting, requirements, cancellation and collection. It connects the selected item to gameplay rules and offers a route forward when requirements are unmet, while fitting the existing UMG/Lua authoring workflow.

The complexity remains real: eligibility is shared between product, panel and model; production state comes from native queries; numeric switcher indices depend on the widget asset. This is practical cross-layer UI engineering, not a pure view-model architecture. A future refactor could centralise the derived action and its reason, provided it preserves the existing bindings and command checks. That is a proposal, not a historical change.

## Inspect and verify

Start with [WorkBenchProduct](../Content/Lua/GameLogics/WorkBench/WorkBenchProduct.lua), then [WorkBenchPanel](../Content/Lua/GameLogics/WorkBench/WorkBenchPanel.lua) and [WorkBenchModel](../Content/Lua/GameLogics/WorkBench/WorkBenchModel.lua).

The [focused action tests](../tests/test_workbench_actions.py) exercise state precedence, recovery actions, panel/model routing, confirmation, both start branches and native-state polling. [Dependencies](DEPENDENCIES.md) describes omitted population, widget and execution services; [Debugging](DEBUGGING.md) records late-confirmation and context-lifetime checks that still require the complete runtime.
