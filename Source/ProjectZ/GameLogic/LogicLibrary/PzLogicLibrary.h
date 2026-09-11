// Interface outline only: selected signatures, not a compilable full class.
#pragma once

class UPzLogicLibrary
{
public:
    static UPzInventoryContainerBase* GetContainerDataFromBox(UObject* ContextObject,FGuid BoxGuid);
    static void OnBoxDragMoveItem(UObject* ContextObject, FGuid BoxID, int SrcItemClintID, int DstContainerType,
                                        int DstItemClientID, int DstContainerPos);
    static void MoveToStorageBox(UObject* ContextObject, const FGuid& BoxGuid, const int SrcContainerType, const int SrcPos, const int DstPos, const int Count);
    static void MoveOutStorageToDstContainer(UObject* ContextObject, const FGuid& BoxGuid, const int DstContainerType, const int SrcPos, const int DstPos, const int Count);
    static void FastMoveOutStorage(UObject* ContextObject, const FGuid& BoxGuid, const int ItemClientID, int Count);
    static void ChangeInStorageBox(UObject* ContextObject, const FGuid& BoxGuid, const int SrcPos, const int DstPos, const int Count);
    static int CheckEnableMoveToStorageBoxByPos(UObject* ContextObject, const FGuid& BoxGuid, const int SrcContainerType, const int SrcContainerPos);
    // State, helper declarations, reflection and base classes are external.
};
