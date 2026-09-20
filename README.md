# Building UI: from placement to useful objects

A connected building feature: browse and place an object, then use its crafting, storage or item-selection interface in the world.

**Evan (Yaxin) Ge · C++ / Lua / UMG · ProjectZ**

[中文 README](docs/README.zh-CN.md) · [System background](#system-background) · [Feature screenshots](#gameplay-screenshots) · [My work](#my-work) · [Decisions](#three-questions-and-decisions) · [Code and tests](#deeper-reading)

## System background

ProjectZ's building feature let players construct structures and functional objects, then use those objects as part of gameplay. Players opened a catalogue, selected a piece, positioned or snapped its preview in the world, and confirmed placement. They could also select existing pieces to move or remove them. Once built, workbenches provided crafting and production, storage boxes provided inventory transfers, and weapon racks provided item selection.

The requirements connected several kinds of interaction: world placement needed clear controls and validity feedback; crafting needed product details, requirements and job status; storage needed consistent item handling. These screens also had to keep track of the particular object being used and react when the player left it. Designers needed to adjust recipes and rules, while UI artists iterated on layouts and animation.

I initiated the building system and developed its gameplay and associated UI using Unreal Engine 4, C++, Lua and UMG. Native systems handled world operations and gameplay data; Lua connected that data and player actions to UMG controls through the existing project UI framework.

[Player journey, requirements and responsibilities](docs/CASE_STUDY.md#feature-background) · [Engineering context](docs/ARCHITECTURE.md#engineering-context)

## Gameplay screenshots

Three complementary views show the feature's scope. Each image links to the relevant implementation story. [All five screenshots, English labels and footage credits](media/README.md).

### Building catalogue and contextual controls

![Building catalogue at the bottom of the world view, with categories and contextual move and delete controls.](media/screenshots/Building_Catalogue.png)

**What the player does:** browse categories and select a placeable object while the world remains visible. The selected world piece exposes **Delete** and **Move**; menu visibility and building mode determine the available controls.

**Work behind this view:** catalogue selection and cancellation, input/HUD context checks, and the connection between native placement operations and Lua controls.

[Feature: catalogue to placement](docs/CASE_STUDY.md#1-from-catalogue-selection-to-placement) · [Code: selection and input](docs/CODE_TOUR.md#1-select-an-object) · [See the separate placement-state screenshot](media/README.md#world-placement--adjustment)

### Equipment workbench: progression, requirements and crafting

![Equipment-workbench interface with weapon progression rows, product categories, selected-item details and materials.](media/screenshots/Equipment_Workbench.png)

**What the player does:** interact with an equipment workbench, choose among **Weapons / Armour / Accessories / Tools**, inspect a progression path and act on the selected product. The image shows **Stop crafting**.

**Work behind this view:** a specialised panel layout, product selection and material data, and an action area that distinguishes ongoing production, collection, requirements and recovery actions.

[Feature: workbench states and actions](docs/WORKBENCH_INTERACTIONS.md) · [Decision: specialised layout versus shared UI](docs/DECISIONS.md#1-keep-workbench-composition-specialised) · [Code: action to model to native dispatch](docs/CODE_TOUR.md#7-follow-the-equipment-workbench-action-end-to-end)

### Storage box: shared inventory interaction in world context

![Storage-box contents on the left and the player's inventory on the right, with the open chest visible between them.](media/screenshots/Storage_Box.png)

**What the player does:** compare box contents with their own inventory and transfer items through individual or bulk actions such as **Quick store** and **Take all**.

**Work behind this view:** box/bag composition, container and slot identity, transfer-command routing, and interaction lifetime when the player moves away or changes the active object.

[Feature: gestures and transfer rules](docs/CASE_STUDY.md#4-storage-several-gestures-one-transfer-boundary) · [Code: storage path](docs/CODE_TOUR.md#5-open-and-use-storage) · [Performance: slot-record reuse](docs/PERFORMANCE.md)

**More views and features — direct links:**

- [World placement / adjustment — screenshot and controls](media/README.md#world-placement--adjustment): confirm, cancel and rotate a preview with material and validity feedback.
- [Consumable / ammunition workbench — screenshot and description](media/README.md#crafting-workbench): potion/arrow categories, selected-product details, material counts and quantity controls. [Workbench lifecycle](docs/WORKBENCH_INTERACTIONS.md).
- [Weapon rack — feature and code](docs/SHARED_INTERACTIONS.md): a shared item selector with rack-specific filtering and source-slot identity; code-only example.
- [Processing queue — feature and actions](docs/CASE_STUDY.md#3-a-processing-station-with-a-meaningful-primary-action): recipe eligibility, quantity, queue capacity and production progress; code-only example.

## My work

My responsibility covered the feature from building an object to using it. I initiated the building system, developed the connected gameplay and UI, and continued developing and maintaining the interaction logic and panels used by constructed objects.

- **Building flow and controls:** worked across the native placement flow and Lua catalogue, connecting selection, previews, placement checks, cancellation, move/remove actions and contextual feedback. Kept shortcuts and buttons aligned with the current input and building mode.
- **Crafting and processing:** developed and maintained workbench interfaces, selected-product details, materials, production-state presentation and start/cancel/collect paths. Kept an existing job separate from the requirements for starting a new one.
- **Storage and weapon-rack interactions:** connected world-object entry points to box/bag views and item selectors. Carried object, container and slot identity through individual, drag/drop and bulk actions and their native requests.
- **UI design decisions:** kept equipment progression and category layouts in specialised panels, reused stable inventory and item-selection conventions, and connected missing materials to shared recipe tracking and level requirements to upgrade guidance.
- **Lifecycle and maintenance:** handled opening and leaving an object interaction, panel cleanup and state refreshes. Worked with gameplay-owned production/container data so closing a view did not become an unintended gameplay command.
- **Content integration:** connected configuration, Lua models, events and UMG bindings so designers could iterate on conditions and UI artists on layout and animation within the established project workflow.

## Three questions and decisions

### 1. How should menu controls and world actions stay aligned?

I connected the native placement operation mask to Lua controls and checked the active input and HUD context before dispatching actions. A confirm attempt at an invalid location can explain why placement failed, while native validation prevents object creation.

This keeps **feedback** and **execution permission** distinct. [Placement path](docs/CASE_STUDY.md#1-from-catalogue-selection-to-placement).

### 2. What should a crafting button do when the player cannot craft?

I distinguished existing production from eligibility for a new craft. Producing, paused and collectable states take precedence; otherwise the action reflects level, material and carry-limit requirements.

A level requirement leads to upgrade guidance, missing materials lead to recipe tracking, and a carry limit blocks crafting. The interface gives the player a useful next step instead of treating every restriction as the same disabled button. [Workbench state and actions](docs/WORKBENCH_INTERACTIONS.md).

### 3. Where should specialised UI stop and reuse begin?

I kept workbench composition specialised: weapon progression and category-dependent layouts changed frequently within that feature. Storage instead shared stable item/container conventions and configurable inventory presentation. Material tracking reused a common recipe-based recovery flow; the weapon rack reused selection presentation while retaining its own compatibility rules.

The boundary follows **the shape of the data and the scope of change**, not visual similarity alone. [Decision rationale](docs/DECISIONS.md) · [Weapon-rack interaction](docs/SHARED_INTERACTIONS.md).

## Outcomes

- Catalogue selection, contextual controls and native validation connect through an explicit operation contract.
- Crafting actions distinguish ongoing work, collectable output and recovery from unmet requirements.
- Equipment-specific layout changes stay local, while storage and item selection reuse stable data and interaction conventions.

## Deeper reading

For a walkthrough: **system and player journey → my work → placement or object interaction → design decisions and code**.

- **Start with the background:** [Feature, requirements and responsibilities](docs/CASE_STUDY.md#feature-background) · [C++ / Lua / UMG roles](docs/ARCHITECTURE.md#engineering-context).
- **Feature and architecture:** [Case study](docs/CASE_STUDY.md) · [Architecture](docs/ARCHITECTURE.md) · [Decision rationale](docs/DECISIONS.md).
- **Implementation:** [Guided code tour](docs/CODE_TOUR.md) · [Workbench actions](docs/WORKBENCH_INTERACTIONS.md) · [Shared interactions](docs/SHARED_INTERACTIONS.md).
- **Reliability and cost:** [Debugging](docs/DEBUGGING.md) · [Storage refresh costs](docs/PERFORMANCE.md).
- **Verification:** [Focused tests — added for this portfolio](docs/TESTING.md).
- **Evidence scope:** [Historical work, excerpts, tests and footage](docs/EVIDENCE.md).

**Related cases:** [Multiplayer UI](https://github.com/seak123/multiplayer-ui-portfolio) · [Mechanical workers and world-space UI](https://github.com/seak123/mechanical-workers-ui-portfolio).
