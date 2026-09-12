# External dependencies and interface boundaries

This case preserves selected feature code, not a complete game build. C++ headers are readable method outlines, not full class declarations: inheritance, fields, reflected methods, generated definitions and other helper declarations are external.

## Lua / UMG runtime

- `ModelManager`, `CreateUIBehaviour` and list-item behaviour factories supply registration and lifecycle.
- `Elements` / `Behaviours` bind named UMG widgets; their binary widget trees and animations are not distributed.
- `UIUtil.AddUniqueFrameAsync` and `__BehaviourManager` create and resolve a frame; late-open cancellation is not assumed.
- `FrameManager:IsInModeHUDState` and native input-mode queries distinguish current input context.
- `EventSystem`, configured timers and native delegates deliver updates. Method-level tests do not prove settings were registered by the production runtime.
- `DataObjectPool` and the native ListView bridge carry Lua records and expose displayed widgets. Offscreen reuse is an external integration contract.
- Localisation/config APIs resolve symbolic keys and conditions. Generated data and item catalogues are not exported.

## Native services

- `PzBuildHoldFlowSystem`: held object, placement/collision/snap helpers, current mode and operation flags. Detailed spatial solvers and server creation are external.
- `InteractionExecutor(ABasePiece*, int32)`: general object-action dispatch. Its semi-production branch sends `OpenSemiProduceFrame(PieceID, PieceGuid, InteractionID)`; the full dispatcher is omitted.
- `PzBuildInteractionSystem`: typed requests converge on `SendInteractRequest` and `BuildingOptionReq`. Protocol types remain references, not distributed definitions.
- `APzCommonQueueWorkEntity`: zero-based work slots, current workload, work rate and finished quantity. Processing continues in the gameplay system independently of the panel.
- `PzLogicLibrary` / inventory manager: lookup by item-client ID, slot positions and storage identity; client eligibility is not server authority.
- `PzStorageBoxRPCComponent`: existing replicated transport. The selected server method illustrates some withdrawal checks, not all validation and mutation logic.

## Weapon-rack and workbench services

The rack uses hangable-item configuration and bag/shortcut container lookups. Its RPC server implementation is external. The general dispatcher delivers `WeaponShelf_OpenHangView(PieceID, Guid, InteractionID)`; the adapter is included, not the full dispatcher. Other common-selector keys remain as shared-module context.

The equipment-workbench excerpts include opening/cleanup, product action derivation, panel routing, guidance, model checks and the start/interruption boundary. `WorkBenchExport`, `EquipMadeExport`, recipe tracking, upgrade guidance, tables and actual widget behaviours remain external. Product population, progression-tree construction, complete success handling, native execution and server validation are omitted.

`WorkBenchProduct` keeps its binding table: the make/cancel/enhance/repair controls share `OnBtnMake`; native-production cancel and collect use distinct handlers. The retained make switcher assignments are 0 for the ordinary action, 1 for local-progress stop, 4 for native production/cancel and 5 for collect. Visual layout, localisation and the exact historical screenshot build remain separate media/runtime concerns.

`PalWorkBenchModel` includes the consumable-workbench opening and cleanup paths, not the equipment product's action implementation.

## Omitted functions

`-- Implementation omitted.` means the function body is outside the selected case. It must not be relied on as a successful operation. The original tests extract named included methods and reject omission markers; the added shared-interaction tests load their modules against controlled services. All Lua files are compiled separately. Neither approach constitutes a complete runtime implementation.

## Editing scope

The public case contains selected source methods and newly written explanations/tests. Development annotations and simple diagnostic prints are removed during preparation. Displayed-file checksums are local integrity checks only.

The [implementation map](source-manifest.json) lists retained methods and omitted bodies. [Verification](TESTING.md) records tests and full-runtime validation targets; [media notes](../media/README.md) distinguish captured states from transitions.
