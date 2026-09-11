// Interface outline only: selected signatures, not a compilable full class.
#pragma once

class UPzBuildHoldFlowSystem
{
public:
    void UpdateBuildingFlow(float DeltaTime);
    void Flow_CheckConditions();
    void Flow_UpdateOperationUI();
    void PlaceUnit();
    void RequestSpawnUnit();
    // State, helper declarations, reflection and base classes are external.
};
