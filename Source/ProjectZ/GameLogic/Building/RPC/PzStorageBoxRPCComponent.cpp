// Selected implementation; native types and services are external.
#include "PzStorageBoxRPCComponent.h"

void UPzStorageBoxRPCComponent::S_FastMoveoutStorage_Implementation(const FGuid& BoxGuid, const int SrcPos, const int Count)
{
	auto PC = Cast<APzPlayerController>(GetOwner());
	if (!PC)
	{
		return;
	}
	auto PS = PC->GetPlayerState<APzPlayerState>();
	if (!IsValid(PS))
	{
		return;
	}
	auto BoxPiece = Cast<ABoxPiece>(UPzBuildUtil::GetPieceActor(this, BoxGuid));
	if (!IsValid(BoxPiece))
	{
		return;
	}
	if (!FKBinHomelandStorageBoxTable::CanUserTakeOut(this, BoxPiece->PieceID(),
	                                                  tagRES_HOMELAND_STORAGE_BOX_USER::E_HSBU_PLAYER))
	{
		PZ_LOG_PLAYER_PS(PS, LogHouse, Log,
		                 TEXT(
			                 "S_FastMoveoutStorage_Implementation PLAYER is not allowed to take out from Storage Box[%d]"
		                 ),
		                 BoxPiece->PieceID());
		C_ContainerMoveRet(PZ_ERROR_STORAGE_NO_TAKE_OUT_PERMISSION);
		return;
	}
	auto MakerId = BoxPiece->GetMakerRoleId();
	auto PlayerId = PS->GetRoleID();
	if (BoxPiece->IsPersonalBox() && MakerId != PlayerId)
	{
		PZ_LOG_PLAYER_PS(PS, LogHouse, Log,
		                 TEXT(
			                 "S_FastMoveoutStorage_Implementation: Personal box can not be Requested by other, boxMakerid = %lld, playerid = %lld"
		                 ),
			   MakerId, PlayerId);
		return;
	}
	BoxPiece->S_FastMoveOut(PS, SrcPos, Count, true);
}
