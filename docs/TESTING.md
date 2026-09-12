# Focused verification

The suite executes selected methods from the included Lua modules with controlled dependencies. It is not a replacement implementation of the feature, an Unreal integration test or a device benchmark. Tests and instrumentation are new portfolio material.

Local verification on 13 September 2026: **34 tests passed**, using Lupa 2.6. All 20 included Lua files passed syntax compilation; all five gallery images passed PNG dimension/link checks. The suite covers workbench integration, the weapon-rack selector, and supporting placement, storage and production excerpts. Native C++ and Unreal integration were not executed.

## Run

```sh
python -m venv .venv
# Activate the virtual environment for your platform.
python -m pip install -r requirements-test.txt
python -m unittest discover -s tests -v
```

## Covered paths

- Syntax compilation of all included Lua modules; displayed-file checksums; local documentation links and private-metadata exclusions.
- Rejection of omitted methods by the test loader.
- PC interaction, HUD context and native building mode: 16 combinations.
- Validity-feedback dispatch versus coating actions; inactive HUD blocks dispatch.
- Recipe eligibility precedence, queue capacity, production-request arguments and material tracking.
- Object/interaction filtering for panel closure and queue refresh.
- Explicit characterisation of the missing-native-entity button-state return.
- Storage population, stable-capacity data reuse, capacity rebuild and unrelated-object event filtering.
- Storage range-based close behaviour and production progress re-anchoring/start/stop.
- Shared selector object/type matching, empty-list closure and frame HUD/leave checks.
- Weapon-rack candidate filtering, bag/shortcut positions, command dispatch and occupancy notices.
- Equipment/crafting workbench opening, world context, leave-distance margin, panel reuse and delegated cleanup.
- Five full-resolution PNG files and their gallery links.
- Characterisation of the shared cooldown setter's early return; a passing test records existing behaviour, not a successful cooldown implementation.

## Instrumentation boundary

The original suite loads named method bodies into Lua tables and supplies their required collaborators. The shared-interaction suite loads the included shared/model modules and calls their initialisers against controlled model factories; it invokes handlers explicitly. Neither suite performs real framework event registration, UMG construction, native traces or RPCs. Full Lua files are separately syntax-checked. List-call counts describe the instrumented test workload, not measured allocations or shipping performance.

## In-engine regression targets

1. Switch catalogue/object while rotating or moving; attempt confirm on every invalidity reason. Verify no spawn request and correct feedback.
2. Open another panel over building mode; press build/rotate/delete shortcuts. Verify input is not consumed by the wrong context.
3. Close or switch stations while frame creation or request completion is pending; delete the world object or move out of range.
4. Fill/clear a queue, change station level, consume materials elsewhere, pause work and change work rate. Verify selected recipe, quantity and button text remain aligned.
5. Open two same-capacity boxes in succession; move, split, sort, deposit and withdraw. Test container disappearance and entry recycling.
6. Verify localisation, long labels, keyboard/mouse and touch behaviour, DPI/aspect ratios and focus.
7. Measure native placement cost, Lua refresh work and visible queue-row updates separately before reporting performance gains.
8. Open a rack selector, move the source item or occupy the rack from another client, then select. Verify native validation and visible recovery.
9. Open equipment and crafting workbenches near the interaction boundary, move away, and close during loading/crafting. Verify local and native production paths independently.
10. Switch racks during asynchronous frame creation, close before completion, and test queued row clicks. Validate cooldown configuration separately from method characterisation.

These are validation targets, not claims that the full game was executed or all targets passed.
