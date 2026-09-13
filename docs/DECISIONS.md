# Decision rationale: reuse follows the shape of change

[Overview](../README.md) · [Workbench implementation](WORKBENCH_INTERACTIONS.md) · [Code tour](CODE_TOUR.md)

This chapter records my reasoning from the actual work. The linked excerpts show implementation relationships; complete widget assets and configuration bodies are omitted.

## Context

Constructed objects shared an interaction entry point, but their interfaces did not all have the same structure. The decision was not simply whether to reuse UI. It was **which parts were stable enough to share, and where future changes were likely to remain local**.

## 1. Keep workbench composition specialised

Equipment crafting required weapon-progression relationships, product categories and layouts driven by different equipment data. These arrangements were likely to change frequently, but their unusual requirements were concentrated in the workbench feature.

I treated that as a reason for a dedicated panel. Putting those rules into a universal building-object panel would have made other interactions carry complexity they did not need. A specialised composition could still use common item widgets, details, materials and guidance services.

The trade-off was more feature-specific layout and binding work. I accepted that cost to keep equipment-specific changes local rather than expand a generic panel into a growing collection of exceptions.

**Implementation connection:** `WorkBenchModel` and `WorkBenchPanel` own the equipment-workbench context and composition; `WorkBenchProduct` handles selected-product actions. The consumable/ammunition workbench has its own `PalWorkBenchModel` lifecycle. [Follow the actual action path](WORKBENCH_INTERACTIONS.md).

## 2. Share the inventory-shaped part of storage

Storage was the opposite case. Many kinds of boxes could exist, and their presentation could vary, but the underlying data remained largely the same: containers, slots and item records, filtered and displayed for the current context.

My reuse boundary was a shared, bag-like child panel with defined configuration inputs for presentation, rather than a separate inventory implementation for every box. The surrounding panel could vary without changing what an item or container position meant.

That does not mean every transfer rule is generic. Permissions, capacity and the identity of the current world object still belong to the relevant model or native validation path. Shared display data must retain source-container and slot information so a click acts on the correct item.

**Implementation connection:** `StorageBoxFrame` composes box and bag child views. `StorageBoxWidget:SetContainerInfo` and `StorageBagWidget:SetBagInfo` bind container data through item records carrying container type, position and capacity. `SetUIElementsVisible` consults box configuration. `BoxModel` routes transfer gestures. [Inspect the storage path](CODE_TOUR.md#5-open-and-use-storage).

**Scope:** the excerpts demonstrate common container conventions and configurable behaviour, but do not include the complete configurable child-panel framework. They retain distinct box-side and bag-side binders; this is not presented as a single fully generic implementation.

## 3. Reuse the recovery journey for missing materials

Missing materials should lead to the same tracking experience wherever the crafting action originates. The recipe already provides the material relationship, so there was no reason for each workbench to invent a separate way to explain how to obtain ingredients.

I kept material tracking available as the next action. The workbench supplies recipe context and opens the shared tracking subpage. This makes the behaviour consistent for players and gives the common data structure a concrete use beyond code reuse.

**Implementation connection:** `WorkBenchProduct:OnBtnMake` calls `RecipeModel:AddMaterialTrackingFrame` when materials are insufficient. The ordinary branch supplies the recipe ID; the enhancement branch also preserves level and tracking type. The control remains actionable, but it does not start crafting in that branch.

## Outcome and boundary

The resulting feature combined specialised workbench layout, shared inventory conventions and a common material-recovery flow. My criterion was the stability of the data and the expected scope of change—not whether two screens happened to look similar.

No measured reduction in development time or defect count is claimed. The contribution is a deliberate reuse boundary that fits the feature's actual data and iteration needs.
