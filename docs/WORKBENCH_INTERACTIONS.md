# Workbench interaction: from a world object to a crafting interface

[Overview and screenshots](../README.md) · [中文案例](README.zh-CN.md) · [Code tour](CODE_TOUR.md)

## Which interface is this?

The equipment screenshot shows **装备台 / 打造**: equipment crafting opened by interacting with a workbench. Weapon, armour, accessory and tool categories feed a selected product's details and material requirements. It is not the character equipment-slot UI. The other workbench screenshot shows **工艺台 / 工艺**, with potions, arrows, materials and quantity controls.

The integration code distinguishes `WorkBenchModel` from `PalWorkBenchModel`. Native dispatch saves the interacting piece's GUID, configuration, level and operation type before emitting `LogicEvent_WorkBenchUI_SetVisible` or `LogicEvent_PalWorkBenchUI_SetVisible`. The full dispatcher is external; the included model methods show how those events enter the UI lifecycle.

The screenshot versions are not pinned to a source revision. They illustrate the player-facing feature, while the selected code explains its integration. Neither screenshot is relabelled as the separate semi-finished-goods production queue panel.

## Design problem

A crafting screen is attached to a world interaction. It needs context to initialise the correct workbench behaviour, and must stop being usable when that interaction is no longer valid. Conversely, small movement at the moment of opening should not immediately close the screen.

## Equipment-workbench path

`WorkBenchModel:OnSetUIVisible` marks the opening context as a piece interaction and passes the GUID and operation type to `MyShowPanel`. That method starts a leave-distance check, initialises workbench data for the operation type, asynchronously opens the panel, binds its model and invokes `OnMyShowPanel`.

The model also has a separate main-menu entry point. This case covers the world-interaction path; it does not claim that every opening of the interface requires standing at a bench.

## Crafting-workbench path

`PalWorkBenchModel:MyShowPanel` starts its own named leave check. If its panel already exists it invokes the panel's show method; otherwise it opens the frame asynchronously and binds the behaviour. It uses a distinct frame path and model rather than treating the equipment and consumable catalogues as identical views.

## A lifecycle detail with a clear purpose

Both methods set the leave threshold to the interaction trace limit **plus 30 world units**. This creates a small opening/closing distance margin: opening the UI near the interaction boundary should not instantly satisfy the close condition. This is a usability integration choice, not a measured performance optimisation or a claim of a newly fixed historical bug.

`MyHidePanel` requests hiding. `OnHidePanel` stops the leave check, clears native interaction context, lets the panel clean up, interrupts an in-progress local crafting flow when applicable, and resets model data. Full interruption and crafting implementations are not exported here; their signatures remain visible. Native queue-backed crafting and local progress-driven crafting have different paths in the larger system, so closing the UI is not described as universally cancelling all production.

## What the excerpt establishes

It explains object-bound opening, panel/model binding, a leave-distance margin and explicit cleanup boundaries. Product rendering, progression-tree construction, all crafting rules, server execution and actual UMG assets remain external. Focused tests verify selected opening/leave/cleanup handlers with controlled services; they do not execute the screenshot's full interface.
