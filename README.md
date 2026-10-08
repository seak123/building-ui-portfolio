# Building system: from placement to persistent worlds

A connected gameplay and UI feature: choose and place an object, preserve it in the world, then use its crafting, storage or item-selection interface.

**Evan (Yaxin) Ge · C++ / Lua / UMG · ProjectZ**

[中文 README](docs/README.zh-CN.md) · [System background](#system-background) · [Feature screenshots](#gameplay-screenshots) · [My work](#my-work) · [System design](#system-design-and-evolution) · [Code and tests](#deeper-reading)

## System background

ProjectZ's building feature let players construct structures and functional objects, then use those objects as part of gameplay. Players opened a catalogue, selected a piece, positioned or snapped its preview in the world, and confirmed placement. They could also select existing pieces to move or remove them. Once built, workbenches provided crafting and production, storage boxes provided inventory transfers, and weapon racks provided item selection.

The requirements connected several kinds of interaction: world placement needed clear controls and validity feedback; crafting needed product details, requirements and job status; storage needed consistent item handling. These screens also had to keep track of the particular object being used and react when the player left it. Designers needed to adjust recipes and rules, while UI artists iterated on layouts and animation.

I initiated the building system and developed its gameplay and associated UI using Unreal Engine 4, C++, Lua and UMG. Native systems handled world operations and gameplay data; Lua connected that data and player actions to UMG controls through the existing project UI framework.

The wider system also had to preserve buildings beyond an individual interaction or loaded area, support content-authoring workflows, and remain practical as the world accumulated more objects. Its design evolved from an early fixed-space, modular building model to later free-form construction, streaming-aware persistence and batched runtime representation.

[Player journey and responsibilities](docs/CASE_STUDY.md#feature-background) · [Whole-system design](docs/SYSTEM_DESIGN.md) · [C++ / Lua / UMG integration](docs/ARCHITECTURE.md#engineering-context)

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

- [World placement / adjustment — screenshot and controls](media/README.md#world-placement--adjustment): confirm, cancel and rotate a preview with material and validity feedback. [Full image](media/screenshots/Building_Placement.png).
- [Consumable / ammunition workbench — screenshot and description](media/README.md#crafting-workbench): potion/arrow categories, selected-product details, material counts and quantity controls. [Full image](media/screenshots/Crafting_Workbench.png) · [Workbench lifecycle](docs/WORKBENCH_INTERACTIONS.md).
- [Weapon rack — feature and code](docs/SHARED_INTERACTIONS.md): a shared item selector with rack-specific filtering and source-slot identity; code-only example.
- [Processing queue — feature and actions](docs/CASE_STUDY.md#3-a-processing-station-with-a-meaningful-primary-action): recipe eligibility, quantity, queue capacity and production progress; code-only example.

## My work

My responsibility covered the feature from building an object to using it. I initiated the building system, developed the connected gameplay and UI, and continued developing and maintaining the interaction logic and panels used by constructed objects.

- **System design and rules:** separated player input, the client building flow, shared rule checks, object management and server persistence. Implemented the early spatial-slot model and evolved the building rules as the gameplay changed.
- **Building flow and controls:** worked across the native placement flow and Lua catalogue, connecting selection, previews, placement checks, cancellation, move/remove actions and contextual feedback. Kept shortcuts and buttons aligned with the current input and building mode.
- **Crafting and processing:** developed and maintained workbench interfaces, selected-product details, materials, production-state presentation and start/cancel/collect paths. Kept an existing job separate from the requirements for starting a new one.
- **Storage and weapon-rack interactions:** connected world-object entry points to box/bag views and item selectors. Carried object, container and slot identity through individual, drag/drop and bulk actions and their native requests.
- **UI design decisions:** kept equipment progression and category layouts in specialised panels, reused stable inventory and item-selection conventions, and connected missing materials to shared recipe tracking and level requirements to upgrade guidance.
- **Lifecycle and maintenance:** handled opening and leaving an object interaction, panel cleanup and state refreshes. Worked with gameplay-owned production/container data so closing a view did not become an unintended gameplay command.
- **Content integration:** connected configuration, Lua models, events and UMG bindings so designers could iterate on conditions and UI artists on layout and animation within the established project workflow.
- **Persistence and scale:** managed building data separately from its runtime representation, integrated saving/restoration with server streaming regions, and worked on the building-side integration of LiteMass for logical entities, replication and batched representation.
- **Authoring and performance:** developed building configuration/debugging and layout-authoring workflows, including save/edit/export and later player blueprints. Worked with the tools team on level integration, and optimised dynamic-navigation work triggered by changes in the world.

## System design and evolution

I started from one complete action: **choose → preview and adjust → validate → create → preserve**. Input/UI communicates intent, the building flow manages the current operation, and rules serve both client feedback and server checks. Object management provides gameplay operations; server data handles saving and restoring. These responsibilities have different reasons to change and different lifetimes.

[Walk through the five responsibilities and their interfaces](docs/SYSTEM_DESIGN.md).

### Early rules: spatial slots, dependencies and occupancy

The early version used a fixed building space. Instead of growing a list of special relationships between walls, floors and stairs, I composed objects from **required/provided Pivots** and **occupied Spaces**. Placement and removal could then operate on explicit spatial relationships.

[![Reconstructed illustration of spatial slots and a wall's requirements, capabilities and occupancy.](media/diagrams/spatial-slots-and-wall.svg)](docs/SPATIAL_RULES.md)

*Early-version design illustration, redrawn for this portfolio. The gameplay screenshots above show the later version.*

[Model and wall example](docs/SPATIAL_RULES.md) · [Structural versus furniture granularity](docs/SPATIAL_RULES.md#different-granularity-for-structure-and-furniture) · [Spatial slots versus object-owned sockets](docs/SPATIAL_RULES.md#why-spatial-slots-rather-than-only-object-owned-sockets)

### Persistent data, runtime scale and content workflows

- **Data survives a representation change.** Moving from player-owned records to server streaming regions did not need to redefine the preview interaction. Later, simple buildings could use logical data and shared representation through LiteMass, while complex functional buildings retained Actors. [Lifecycle, LiteMass and one wall's full path](docs/LIFECYCLE_AND_SCALE.md).
- **Content needs an end-to-end workflow.** Designers could construct, save, reopen and export a layout, then place it through the editor pipeline. The tools team owned the level build/export stage; later player blueprints extended the runtime layout workflow. [Authoring and responsibilities](docs/AUTHORING_WORKFLOW.md).
- **World changes have downstream costs.** Navigation work required both scheduling/coalescing and reductions in collected collision geometry, with path quality checked alongside cost. [Navigation and UI performance work](docs/PERFORMANCE.md#dynamic-navigation-and-world-change-cost).

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

- The early structural/furniture building model worked through common dependency and occupancy rules; visual debugging made configuration relationships inspectable.
- Rules, persistence and runtime representation could evolve in their own main areas while retaining the overall player interaction flow.
- Layout authoring connected runtime construction to editable content and the level pipeline, then supported later player-blueprint work.
- Catalogue selection, contextual controls and native validation connect through an explicit operation contract.
- Crafting actions distinguish ongoing work, collectable output and recovery from unmet requirements.
- Equipment-specific layout changes stay local, while storage and item selection reuse stable data and interaction conventions.

## Deeper reading

For a walkthrough: **player journey → system responsibilities → one design decision → UI or runtime detail**.

- **Start with the background:** [Feature, requirements and responsibilities](docs/CASE_STUDY.md#feature-background) · [C++ / Lua / UMG roles](docs/ARCHITECTURE.md#engineering-context).
- **Whole-system design:** [Responsibilities and evolution](docs/SYSTEM_DESIGN.md) · [Early spatial rules and trade-offs](docs/SPATIAL_RULES.md).
- **World and content:** [Lifecycles and LiteMass](docs/LIFECYCLE_AND_SCALE.md) · [Authoring workflow](docs/AUTHORING_WORKFLOW.md).
- **Feature and architecture:** [Case study](docs/CASE_STUDY.md) · [Architecture](docs/ARCHITECTURE.md) · [Decision rationale](docs/DECISIONS.md).
- **Implementation:** [Guided code tour](docs/CODE_TOUR.md) · [Workbench actions](docs/WORKBENCH_INTERACTIONS.md) · [Shared interactions](docs/SHARED_INTERACTIONS.md).
- **Reliability and cost:** [Debugging](docs/DEBUGGING.md) · [UI refresh and navigation costs](docs/PERFORMANCE.md).
- **Verification:** [Focused tests — added for this portfolio](docs/TESTING.md).
- **Evidence scope:** [Historical work, excerpts, tests and footage](docs/EVIDENCE.md).

**Related cases:** [Multiplayer UI](https://github.com/seak123/multiplayer-ui-portfolio) · [Mechanical workers and world-space UI](https://github.com/seak123/mechanical-workers-ui-portfolio).
