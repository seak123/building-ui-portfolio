# Guided code tour

[Overview](../README.md) · [Architecture](ARCHITECTURE.md)

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

## 6. Understand the boundary

[Implementation map](source-manifest.json) lists included methods and omitted bodies. Short omission comments preserve signatures, not working substitutes. [Dependencies](DEPENDENCIES.md) defines external contracts; [Tests](TESTING.md) specifies which code paths execute locally.
