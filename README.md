# Building UI: from placement to useful objects

![Equipment-workbench UI with weapon progression, product categories, selected-item details and crafting materials.](media/screenshots/Equipment_Workbench.png)

From browsing and placing an object to crafting equipment or transferring items, the UI connects the player's next action to the current world context.

**Evan (Yaxin) Ge · C++ / Lua / UMG · ProjectZ**

[中文 README](docs/README.zh-CN.md) · [Screenshots](#gameplay-screenshots) · [Explore the work](#deeper-reading)

*Equipment workbench: interacting with a constructed workbench opens product categories, progression rows, item details and material requirements. The action shown is **Stop crafting**. [Footage credit and English label guide](media/README.md).*

## My work

I initiated the building system and developed its gameplay and associated UI. I also developed and maintained building-object interactions and their panels, connecting C++ world operations, Lua interface logic and UMG widgets.

This case covers catalogue and placement controls, equipment and crafting workbenches, storage, and the weapon-rack selector.

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

- **Feature and architecture:** [Case study](docs/CASE_STUDY.md) · [Architecture](docs/ARCHITECTURE.md) · [Decision rationale](docs/DECISIONS.md).
- **Implementation:** [Guided code tour](docs/CODE_TOUR.md) · [Workbench actions](docs/WORKBENCH_INTERACTIONS.md) · [Shared interactions](docs/SHARED_INTERACTIONS.md).
- **Reliability and cost:** [Debugging](docs/DEBUGGING.md) · [Storage refresh costs](docs/PERFORMANCE.md).
- **Verification:** [Focused tests — added for this portfolio](docs/TESTING.md).
- **Evidence scope:** [Historical work, excerpts, tests and footage](docs/EVIDENCE.md).

## Gameplay screenshots

<details>
<summary>Open the five-state gallery with English captions</summary>

### 1. Building catalogue open

![Building catalogue over the world with category tabs and a grid of objects.](media/screenshots/Building_Catalogue.png)

The bottom catalogue supports category browsing while the world remains visible. The selected world piece exposes **Delete** and **Move**.

### 2. World placement / adjustment

![Roof-piece placement with confirm, cancel and rotate prompts.](media/screenshots/Building_Placement.png)

With the catalogue closed, **Confirm**, **Cancel**, **Rotate** and **Delete** accompany material information and world feedback. The available input follows the current UI and building mode, keeping world actions distinct from menu navigation.

### 3. Equipment workbench — crafting

![Equipment crafting interface with progression rows and material requirements.](media/screenshots/Equipment_Workbench.png)

**Weapons / Armour / Accessories / Tools** organise products. Details and materials appear on the right; the current action reads **Stop crafting**.

### 4. Crafting workbench — consumables and ammunition

![Crafting workbench with potion and arrow categories and quantity controls.](media/screenshots/Crafting_Workbench.png)

**Potions / Arrows** lead to product details, material requirements and quantity controls. The current action reads **Stop crafting**.

### 5. Storage box and player inventory

![Storage box contents on the left and player inventory on the right.](media/screenshots/Storage_Box.png)

**Quick store** and **Take all** accompany the box contents. The player's inventory appears on the right, with the chest still visible in the world.

[Footage sources and label translations](media/README.md). These are separately labelled stills.

</details>

**Related cases:** [Multiplayer UI](https://github.com/seak123/multiplayer-ui-portfolio) · [Mechanical workers and world-space UI](https://github.com/seak123/mechanical-workers-ui-portfolio).
