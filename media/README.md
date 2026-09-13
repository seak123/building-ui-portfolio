# Gameplay screenshots and English label guide

[Portfolio overview](../README.md) · [Featured views](../README.md#gameplay-screenshots)

Jump to: [Catalogue](#building-catalogue) · [Placement](#world-placement--adjustment) · [Equipment workbench](#equipment-workbench) · [Crafting workbench](#crafting-workbench) · [Storage](#storage-box)

Five original stills supplied for this case study. No cropping, generated replacement UI or watermark removal has been applied. They are separate examples, not a continuous flow recording. The portfolio author supplied the source-video links below; playback timestamps and exact build versions were not supplied. Test-build notices visible in the images are preserved.

Source videos:

- **ENFANT TERRIBLE captures** — [YouTube gameplay video](https://www.youtube.com/watch?v=QLgoOZu9biw): building catalogue, world placement and crafting workbench.
- **11的游戏世界 captures** — [Bilibili gameplay video, part 2](https://www.bilibili.com/video/BV1KQkFY4Ezw/?p=2): equipment workbench and storage box.

These source links identify the footage. Exact timestamps and a source-code/build match are not established; the images document visible UI states rather than completed commands or transitions.

## Building catalogue

![Building catalogue over the world with category tabs and contextual controls.](screenshots/Building_Catalogue.png)

[Feature and decisions](../docs/CASE_STUDY.md#1-from-catalogue-selection-to-placement) · [Selection and input code](../docs/CODE_TOUR.md#1-select-an-object)

[Open full image](screenshots/Building_Catalogue.png). Visible creator mark: **ENFANT TERRIBLE**.

Caption: “The building catalogue remains over the world while the player browses categories. Contextual actions for the selected world piece remain visible.”

Labels: 建造模式 — Building mode; 建造 — Build; 地形 — Terrain; 种植 — Planting; 搬家 — Relocate; 生产 — Production; 烹饪 — Cooking; 关闭菜单 — Close menu; 拆除 — Delete; 移动 — Move.

## World placement / adjustment

![Roof-piece placement with confirm, cancel and rotate prompts beside the preview.](screenshots/Building_Placement.png)

[Placement and validity feedback](../docs/CASE_STUDY.md#1-from-catalogue-selection-to-placement) · [Native decision path](../docs/CODE_TOUR.md#3-follow-the-native-decision)

[Open full image](screenshots/Building_Placement.png). Visible creator mark: **ENFANT TERRIBLE**.

Caption: “With the catalogue closed, the player positions or adjusts a roof piece using world-space feedback and contextual confirm, cancel and rotate controls.”

Labels: 木屋顶1 — Wooden roof 1; 消耗材料 — Required materials; 确认 — Confirm; 取消 — Cancel; 旋转 — Rotate; 呼出菜单 — Open menu; 切为弱吸附 — Switch to weak snapping; 隐藏吸附点 — Hide snap points; 切为自由视角 — Switch to free camera.

The catalogue-open and placement images are separately labelled states. The available input follows the current UI and building mode, keeping world actions distinct from menu navigation.

## Equipment workbench

![Equipment crafting with progression rows, selected-product details and materials.](screenshots/Equipment_Workbench.png)

[Workbench interaction story](../docs/WORKBENCH_INTERACTIONS.md) · [Specialised layout decision](../docs/DECISIONS.md#1-keep-workbench-composition-specialised)

[Open full image](screenshots/Equipment_Workbench.png). Visible attribution: **11的游戏世界 / bilibili**.

Caption: “Interacting with an equipment workbench opens a crafting interface with product categories, progression rows, item details and material requirements. The current action is Stop crafting.”

Labels: 装备台 / 打造 — Equipment workbench / Crafting; 武器 — Weapons; 防具 — Armour; 饰品 — Accessories; 工具 — Tools; 升级 — Upgrade; 消耗材料 — Required materials; 更换 — Change; 停止打造 — Stop crafting.

## Crafting workbench

![Potion and arrow crafting with a product grid, materials and quantity controls.](screenshots/Crafting_Workbench.png)

[Workbench models and lifecycle](../docs/WORKBENCH_INTERACTIONS.md) · [Implementation tour](../docs/CODE_TOUR.md#7-follow-the-equipment-workbench-action-end-to-end)

[Open full image](screenshots/Crafting_Workbench.png). Visible creator mark: **ENFANT TERRIBLE**.

Caption: “The crafting workbench combines a product catalogue with descriptions, material requirements and quantity controls. Potions and arrows are separate categories.”

Labels: 工艺台 / 工艺 — Crafting workbench / Crafting; 药剂 — Potions; 箭矢 — Arrows; 简介 — Description; 消耗材料 — Required materials; 停止制造 — Stop crafting.

The distinct workbench lifecycles and equipment action path are discussed in [Workbench interactions](../docs/WORKBENCH_INTERACTIONS.md).

## Storage box

![Storage box contents and player inventory shown together in world context.](screenshots/Storage_Box.png)

[Storage interaction story](../docs/CASE_STUDY.md#4-storage-several-gestures-one-transfer-boundary) · [Refresh costs](../docs/PERFORMANCE.md)

[Open full image](screenshots/Storage_Box.png). Visible attribution: **11的游戏世界 / bilibili**.

Caption: “The storage view presents the box and player inventory together, while retaining the chest in world context. Quick store and Take all expose bulk-transfer actions.”

Labels: 储物箱 — Storage box; 背包道具 — Bag items; 快速收纳 — Quick store; 全部取出 — Take all; 饰品 — Accessories; 防具 — Armour.

## Additional media

The weapon-rack selector and the separate semi-finished-goods production queue remain code-only examples.

Project visuals and creator overlays remain the property of their respective rights holders. Attribution here identifies visible marks, not permission to redistribute the underlying footage.
