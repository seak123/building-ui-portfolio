// Selected implementation; native types and services are external.
#include "PzLogicLibrary.h"

UPzInventoryContainerBase* UPzLogicLibrary::GetContainerDataFromBox(UObject* ContextObject,FGuid BoxGuid)
{
	if (auto BuildManager = GameUtil::GetGameInstanceSubsystem<UPzBuildingManager>(ContextObject))
	{
		if (ABasePiece* Piece = BuildManager->GetPieceByGUID(BoxGuid))
		{
			if (ABoxPiece* Box = Cast<ABoxPiece>(Piece))
			{
				return  Box->ClientBoxContainer;
			}
		}
	}
	return nullptr;
}

void UPzLogicLibrary::OnBoxDragMoveItem(UObject* ContextObject, FGuid BoxID, int SrcItemClintID, int DstContainerType,
                                        int DstItemClientID, int DstContainerPos)
{
	if (auto InventoryManager = GameUtil::GetGameInstanceSubsystem<UPzInventoryManager>(ContextObject))
	{
		if (auto SrcItem = InventoryManager->GetItemByClientId(SrcItemClintID))
		{
			if (SrcItem->ContainerType == E_CONTAINER_TYPE::E_CONT_STORAGE_BOX && DstContainerType == E_CONTAINER_TYPE::E_CONT_STORAGE_BOX)
			{
				ChangeInStorageBox(ContextObject, BoxID, SrcItem->ContainerPos, DstContainerPos, SrcItem->GetCount());
			}
			else if (SrcItem->ContainerType == E_CONTAINER_TYPE::E_CONT_STORAGE_BOX && DstContainerType != E_CONTAINER_TYPE::E_CONT_STORAGE_BOX)
			{
				MoveOutStorageToDstContainer(ContextObject, BoxID, DstContainerType, SrcItem->ContainerPos, DstContainerPos, SrcItem->GetCount());
			}
			else if (SrcItem->ContainerType != E_CONTAINER_TYPE::E_CONT_STORAGE_BOX && DstContainerType == E_CONTAINER_TYPE::E_CONT_STORAGE_BOX)
			{
				MoveToStorageBox(ContextObject, BoxID, SrcItem->ContainerType, SrcItem->ContainerPos, DstContainerPos, SrcItem->GetCount());
			}
			else
			{
				InventoryManager->ContainerMoveReq(SrcItem->ContainerType, SrcItem->ContainerPos,
				                                   DstContainerType, DstContainerPos, SrcItem->GetCount());
			}
		}
	}
}

void UPzLogicLibrary::MoveToStorageBox(UObject* ContextObject, const FGuid& BoxGuid, const int SrcContainerType, const int SrcPos, const int DstPos, const int Count)
{
	int CheckResult = UPzLogicLibrary::CheckEnableMoveToStorageBoxByPos(ContextObject, BoxGuid, SrcContainerType, SrcPos);
	if (CheckResult != 0)
	{
		PZ_FIRE_EVENT_LUA_OneParam(ContextObject, "LogicEvent_MoveToStorageBox_ErrorCode", CheckResult);
		return;
	}
	if (APlayerController* PlayerController = GameUtil::GetSelfPlayerController(ContextObject))
	{
		auto StorageBoxRPCComponent = Cast<UPzStorageBoxRPCComponent>(PlayerController->GetComponentByClass(UPzStorageBoxRPCComponent::StaticClass()));
		if (IsValid(StorageBoxRPCComponent))
		{
			StorageBoxRPCComponent->MoveToStorageBox(BoxGuid, SrcContainerType, SrcPos, DstPos, Count);
		}
	}
}

void UPzLogicLibrary::MoveOutStorageToDstContainer(UObject* ContextObject, const FGuid& BoxGuid, const int DstContainerType, const int SrcPos, const int DstPos, const int Count)
{
	if (APlayerController* PlayerController = GameUtil::GetSelfPlayerController(ContextObject))
	{
		auto StorageBoxRPCComponent = Cast<UPzStorageBoxRPCComponent>(PlayerController->GetComponentByClass(UPzStorageBoxRPCComponent::StaticClass()));
		if (IsValid(StorageBoxRPCComponent))
		{
			StorageBoxRPCComponent->MoveOutStorageBox(BoxGuid, DstContainerType, SrcPos, DstPos, Count);
		}
	}
}

void UPzLogicLibrary::FastMoveOutStorage(UObject* ContextObject, const FGuid& BoxGuid, const int ItemClientID, int Count)
{
	if (auto InventoryManager = GameUtil::GetGameInstanceSubsystem<UPzInventoryManager>(ContextObject))
	{
		if (auto ClientItem = InventoryManager->GetItemByClientId(ItemClientID))
		{
			if (Count <= 0)
			{
				Count = ClientItem->GetCount();
			}
			int SrcContainerPos = ClientItem->ContainerPos;
			if (APlayerController* PlayerController = GameUtil::GetSelfPlayerController(ContextObject))
			{
				auto StorageBoxRPCComponent = Cast<UPzStorageBoxRPCComponent>(PlayerController->GetComponentByClass(UPzStorageBoxRPCComponent::StaticClass()));
				if (IsValid(StorageBoxRPCComponent))
				{
					StorageBoxRPCComponent->S_FastMoveoutStorage(BoxGuid, SrcContainerPos, Count);
				}
			}
		}
	}
}

void UPzLogicLibrary::ChangeInStorageBox(UObject* ContextObject, const FGuid& BoxGuid, const int SrcPos, const int DstPos, const int Count)
{
	if (APlayerController* PlayerController = GameUtil::GetSelfPlayerController(ContextObject))
	{
		auto StorageBoxRPCComponent = Cast<UPzStorageBoxRPCComponent>(PlayerController->GetComponentByClass(UPzStorageBoxRPCComponent::StaticClass()));
		if (IsValid(StorageBoxRPCComponent))
		{
			StorageBoxRPCComponent->ChangeInStorageBox(BoxGuid, SrcPos, DstPos, Count);
		}
	}
}

int UPzLogicLibrary::CheckEnableMoveToStorageBoxByPos(UObject* ContextObject, const FGuid& BoxGuid, const int SrcContainerType, const int SrcContainerPos)
{
	int SrcItemTypeID = 0;
	bool bSrcItemBind = false;
	UPzInventoryManager* pInventoryManager = UPzInventoryLibrary::GetInventoryManager(ContextObject);
	if (pInventoryManager)
	{
		UPzInventoryItemBase* pItemObj = pInventoryManager->GetContainerItem(SrcContainerType, SrcContainerPos);
		if (pItemObj)
		{
			SrcItemTypeID = pItemObj->GetItemTypeID();
			bSrcItemBind = pItemObj->IsBind();
		}
	}
	if (SrcItemTypeID == 0)
	{
		return 1;
	}
	return CheckEnableMoveToStorageBoxByID(ContextObject, BoxGuid, SrcItemTypeID, bSrcItemBind);
}
