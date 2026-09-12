# Guided code tour

[Overview](../README.md) · [Architecture](ARCHITECTURE.md)

For a short review, read **steps 2–3 for input/placement**, then **step 7 for the equipment-workbench action path**. Storage and the shared selector provide supporting examples.

## 1. Select an object

[BuildSpaceListWidget](../Content/Lua/GameLogics/BuildSpace/BuildSpaceListWidget.lua) consumes menu/catalogue events and populates lists. [BuildSpaceUnitItem](../Content/Lua/GameLogics/BuildSpace/BuildSpaceUnitItem.lua) represents a selectable entry. In [BuildSpaceModel](../Content/Lua/GameLogics/BuildSpace/BuildSpaceModel.lua), follow `SetBuildSpaceMenuSelected`, `SetBuildSpaceCatalogSelected`, `SetBuildSpaceUnitSelected`, `HoldUnit` and `CancelHold`.

## 2. Keep the input context valid

[BuildSpaceMainFrame](../Content/Lua/GameLogics/BuildSpace/BuildSpaceMainFrame.lua) coordinates frame presentation and PC/touch controls. [BuildSpaceOperatWidget](../Content/Lua/GameLogics/BuildSpace/BuildSpaceOperatWidget.lua) checks input/HUD/native modes in `CheckBuildActionValid`, then operation bits in individual action handlers. `RefreshOperateState` maps the same operation summary to visible controls.

## 3. Follow the native decision

[PzBuildHoldFlowSystem](../Source/ProjectZ/GameLogic/Building/PzBuildHoldFlowSystem.cpp): `UpdateBuildingFlow` orders the stages; `Flow_CheckConditions` applies further rules; `Flow_UpdateOperationUI` publishes changed operation masks; `PlaceUnit` and `RequestSpawnUnit` separate confirmation from creation. Detailed collision/snap solvers remain external.

## 4. Use a processing station

[BuildProduceModel](../Content/Lua/GameLogics/BuildProduce/BuildProduceModel.lua) receives the open event, resolves the queue entity and derives recipe eligibility. [SemIProduceFrame](../Content/Lua/GameLogics/BuildProduce/SemiProduce/SemIProduceFrame.lua) retains object/interaction identity, quantity and button state; the filename's existing capitalisation is retained. Follow `SetData`, `GetBtnState`, `OnStartProduceBtn`, `OnGetProductionBtn` and the identity-filtered event handlers.

[SemiProduceSlotEntry](../Content/Lua/GameLogics/BuildProduce/SemiProduce/SemiProduceSlotEntry.lua) handles displayed work state, progress, cancel and collect. [SemiProduceRecipeEntry](../Content/Lua/GameLogics/BuildProduce/SemiProduce/SemiProduceRecipeEntry.lua) links a recipe-list selection back to the model.

[PzBuildInteractionSystem](../Source/ProjectZ/GameLogic/Building/PzBuildInteractionSystem.cpp) includes interaction validation and typed production/collect/cancel request adapters. The general dispatcher and full protocol definitions are external.

## 5. Open and use storage

[BoxModel](../Content/Lua/GameLogics/Box/BoxModel.lua) carries the current box GUID and dispatches fast, detail-panel and drag/drop actions. [StorageBoxFrame](../Content/Lua/GameLogics/StorageBox/StorageBoxFrame.lua) handles close/range lifecycle and composes the child views. [StorageBoxWidget](../Content/Lua/GameLogics/StorageBox/StorageBoxWidget.lua) and [StorageBagWidget](../Content/Lua/GameLogics/StorageBox/StorageBagWidget.lua) render both sides; [BoxContainerItemSlot](../Content/Lua/GameLogics/Box/BoxContainerItemSlot.lua) connects slot interaction to the parent/model.

[PzLogicLibrary](../Source/ProjectZ/GameLogic/LogicLibrary/PzLogicLibrary.cpp) chooses the transfer route and common deposit validation. [PzStorageBoxRPCComponent](../Source/ProjectZ/GameLogic/Building/RPC/PzStorageBoxRPCComponent.cpp) illustrates selected native withdrawal checks; other inventory mutation code is outside this case.

## 6. Share an interaction surface

[AdditionModel](../Content/Lua/GameLogics/Interaction/Addition/AdditionModel.lua) stores the common frame data and object/type context. [AdditionFrame](../Content/Lua/GameLogics/Interaction/Addition/AdditionFrame.lua) handles list/title and contextual closure. [AdditionItem](../Content/Lua/GameLogics/Interaction/Addition/AdditionItem.lua) binds item information and dispatches selection.

[AdditionWeaponShelfModel](../Content/Lua/GameLogics/Interaction/Addition/SubPartModel/AdditionWeaponShelfModel.lua) provides rack-specific candidate filtering, source-container data and occupancy feedback. Its native entry point is `OnWeaponShelfHang` in the included logic library. [Design discussion](SHARED_INTERACTIONS.md).

## 7. Follow the equipment-workbench action end to end

[WorkBenchModel](../Content/Lua/GameLogics/WorkBench/WorkBenchModel.lua): `OnSetUIVisible` → `MyShowPanel` establishes world context. [PalWorkBenchModel](../Content/Lua/GameLogics/PalWorkBench/PalWorkBenchModel.lua) shows the separate consumable-workbench lifecycle.

[WorkBenchProduct](../Content/Lua/GameLogics/WorkBench/WorkBenchProduct.lua): start with `RefreshProductBtnGroupForMake` for precedence and recovery actions. `OnBtnMake` routes requirements to guidance/tracking or emits the make event; `OnBtnInProducing` and `OnBtnMakeCanTake` route cancellation and collection. Follow `OnProduceInfoChanged` and `PalProduce_CountDownUpdate` for native-state refresh.

[WorkBenchPanel](../Content/Lua/GameLogics/WorkBench/WorkBenchPanel.lua): the event binding leads to `OnBtnMake`, which sets confirmation policy and delegates to the model. `OnBuildLvBtnClicked` preserves the workbench GUID for guidance. Back in the model, `OnMakeClicked` checks action/eligibility and `func_MyMakeStart` distinguishes native queue requests from local progress. `MyHidePanel` / `OnHidePanel` separate hiding from cleanup.

[Design discussion](WORKBENCH_INTERACTIONS.md) · [Focused action tests](../tests/test_workbench_actions.py).

## 8. Understand the boundary

[Implementation map](source-manifest.json) lists included methods and omitted bodies. Short omission comments preserve signatures, not working substitutes. [Dependencies](DEPENDENCIES.md) defines external contracts; [Tests](TESTING.md) specifies which code paths execute locally.
