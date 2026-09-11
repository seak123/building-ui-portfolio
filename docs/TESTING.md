# Focused verification

The suite executes selected methods from the included Lua modules with controlled dependencies. It is not a replacement implementation of the feature, an Unreal integration test or a device benchmark. Tests and instrumentation are new portfolio material.

Local verification on 11 September 2026: **19 tests passed**, using Lupa 2.6. All 14 included Lua files passed syntax compilation. Native C++ and Unreal integration were not executed by this suite.

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

## Instrumentation boundary

Tests load named method bodies into a Lua table and supply only their required collaborators. They do not run module initialisers, framework event registration, UMG construction, native traces or RPCs. Full Lua files are separately syntax-checked. List-call counts describe the instrumented test workload, not measured allocations or shipping performance.

## In-engine regression targets

1. Switch catalogue/object while rotating or moving; attempt confirm on every invalidity reason. Verify no spawn request and correct feedback.
2. Open another panel over building mode; press build/rotate/delete shortcuts. Verify input is not consumed by the wrong context.
3. Close or switch stations while frame creation or request completion is pending; delete the world object or move out of range.
4. Fill/clear a queue, change station level, consume materials elsewhere, pause work and change work rate. Verify selected recipe, quantity and button text remain aligned.
5. Open two same-capacity boxes in succession; move, split, sort, deposit and withdraw. Test container disappearance and entry recycling.
6. Verify localisation, long labels, keyboard/mouse and touch behaviour, DPI/aspect ratios and focus.
7. Measure native placement cost, Lua refresh work and visible queue-row updates separately before reporting performance gains.

These are validation targets, not claims that the full game was executed or all targets passed.
