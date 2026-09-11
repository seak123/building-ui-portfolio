// Selected implementation; native types and services are external.
#include "PzBuildHoldFlowSystem.h"

void UPzBuildHoldFlowSystem::UpdateBuildingFlow(float DeltaTime)
{
	if (CurHoldUnit)
	{
		EBuildingFlowUnitState CacheState = FlowUnitState;
		Flow_PrepareAssistInfo(DeltaTime);
		Flow_DetectValidPosition();
		BuildFlowUnitSetDefaultRotate();
		BuildFlowRevisedPieceTransform();
		Flow_DetectValidPosition_Condition();
		Flow_CheckConditions();
		Flow_DrawAssistantObjects();
		if (CacheState != FlowUnitState)
		{
			SwitchUnitViewType(FlowUnitState < EBuildingFlowUnitState::ValidState ? EBuildingUnitViewType::ESelectedUnValidViewType : EBuildingUnitViewType::ESelectedValidViewType);
		}
	}

	Flow_TraceSelectUnit();
	if (SystemMode == EBuildingSystemMode::BuildMode || SystemMode == EBuildingSystemMode::FarmMode)
	{
		if (CurBuildSpaceMenuType == static_cast<int>(tagHOMELAND_FIRST_MENU_TYPE::HOMELAND_FIRST_MENU_COAT))
		{
			CheckCoatCondition();
		}
		Flow_UpdateOperationUI();
	}
}

void UPzBuildHoldFlowSystem::Flow_CheckConditions()
{
	if (FlowUnitState <= EBuildingFlowUnitState::InvalidState)
	{
		return;
	}
	switch (CurHoldUnit->UnitType)
	{
	case EBuildingUnitType::Piece:
		CheckUnitCommonCondition();
		break;
	case EBuildingUnitType::Vehicle:
		if (CheckUnitCommonCondition())
		{
			if (const APzBaseVehicle* Vehicle = Cast<APzBaseVehicle>(CurHoldUnit.GetObject()))
			{
				if (Vehicle->VehicleLevel() < FlowTemp_DetectingWaterLevel)
				{
					FlowUnitState = EBuildingFlowUnitState::InvalidState;
					UnValidTag = EBUILD_UNIT_CONDITION_REASON::WATER_LEVEL_RESTRICTED;
					return;
				}
			}
		}
		break;
	case EBuildingUnitType::PackagedHouse:
		if (!UBuildConditionCheckSystem::CheckPackagedHouseCondition(this, Cast<APzPlayerState>(GameUtil::GetSelfPlayerState(this)),
		                                                             CurHoldUnit, UnValidTag))
		{
			FlowUnitState = EBuildingFlowUnitState::InvalidState;
		}
		break;
	case EBuildingUnitType::Max:
		break;
	}
}

void UPzBuildHoldFlowSystem::Flow_UpdateOperationUI()
{
	int OpBtnMask = 0;
	if (CurHoldUnit)
	{
		if (CurSelectedUnit.IsValid() && CurSelectedUnit.CanBeDeleted())
		{
			OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::DEL));
		}
		OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::CANCEL));
		OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::ROT));
		OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::REVERSE_ROT));
		if (FlowUnitState >= EBuildingFlowUnitState::ValidState)
		{
			OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::CAN_BUILD));
		}
		else
		{
			OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::CANT_BUILD));
		}
		if (NeedEarthgrab)
		{
			OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::EARTHGRAB));
			if (UnValidTag != EBUILD_UNIT_CONDITION_REASON::EARTHGRAB_BOT && UnValidTag != EBUILD_UNIT_CONDITION_REASON::IN_AIR)
			{
				OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::EARTHGRAB_UP));
			}
			if (UnValidTag != EBUILD_UNIT_CONDITION_REASON::UNDER_TERRAIN)
			{
				OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::EARTHGRAB_DOWN));
			}
		}
		if (CurHoldUnit->UnitType == EBuildingUnitType::PackagedHouse)
		{
			OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::HOUSE_GROUP));
		}
	}
	else
	{
		if (CurSelectedUnit)
		{
			if (CurSelectedUnit.CanBeDeleted())
			{
				OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::DEL));
			}
			if (CurSelectedUnit.AlreadyCoat(CurSelectedUnitSectionIndex))
			{
				OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::TEAR_COAT));
			}
			if (CurBuildSpaceMenuType == static_cast<int>(tagHOMELAND_FIRST_MENU_TYPE::HOMELAND_FIRST_MENU_COAT))
			{
				if (CurSelectedCoatId > 0)
				{
					if (CoatInCondition)
					{
						if (CurCoatPreviewUnitGuid.IsValid() && CurCoatPreviewUnitGuid == CurSelectedUnit.SelectedPieceGuid)
						{
							OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::CAN_COAT));
						}
					}
					else
					{
						OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::CANT_COAT));
					}
				}
			}
			else
			{
				OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::MOVE));
				if (CurSelectedUnit.NeedRepairing())
				{
					OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::REPAIR));
					float HpPercent = CurSelectedUnit.GetHpPercent();
					if (HpPercent != SelectedHpPercent)
					{
						OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::HP_CHANGE));
						SelectedHpPercent = HpPercent;
					}
				}
			}
		}

		if (CurSelectedCoatId > 0)
		{
			OpBtnMask |= (1 << static_cast<int>(EBUILD_OP_MASK::CANCEL));
		}
	}
	if (OpBtnMask != BuildOpStateMask)
	{
		BuildOpStateMask = OpBtnMask;
		PZ_FIRE_EVENT_LUA_OneParam(this, "BuildSpace_OpState_Change", BuildOpStateMask);
	}
}

void UPzBuildHoldFlowSystem::PlaceUnit()
{
	if (CurMoveUnit.IsValid())
	{
		RequestMoveUnit();
		return;
	}
	if (Flow_Build_Cold_Time > BUILD_TIME_INTERVAL)
	{
		RequestSpawnUnit();
		Flow_Build_Cold_Time = 0;
	}
}

void UPzBuildHoldFlowSystem::RequestSpawnUnit()
{
	if (FlowUnitState < EBuildingFlowUnitState::ValidState)
	{
		UBuildConditionCheckSystem::C_NoticeCondition(this, CurHoldUnit, UnValidTag);
		if (UnValidTag == EBUILD_UNIT_CONDITION_REASON::RECIPE_LOCK)
		{
			PZ_FIRE_EVENT_LUA_OneParam(this, "BUILD_UNIT_RECIPE_LOCK", CurHoldUnit->UnitID);
		}
		if (UnValidTag == EBUILD_UNIT_CONDITION_REASON::IN_OTHER_TOTEM_AREA)
		{
			const FGuid TotemGuid = UHomelandTotemSubSystem::CheckInAnyTotemArea(this,
																		CurHoldUnit->GetUnitTransform().GetLocation(),
																		AnyTotem);
			if (TotemGuid.IsValid())
			{
				const uint64 MakerId = UHomelandTotemSubSystem::GetTotemMakerId(this, TotemGuid);
				PZ_FIRE_EVENT_LUA_TwoParams(this,
					"NetEvent_PlayWorld_NO_Permission",
					tagE_WORLD_AUTHORITY_ITEM_TYPE::E_WORLD_AUTHORITY_ITEM_BUILD_PLACE_IN_OTHER_TOTEM,
					MakerId)
			}
			else
			{
				UE_LOG(LogPzBuilding, Error,TEXT("RequestSpawnUnit|Cannot find any totem around while it walked"
									 "in case CantBuildPersonalInOtherTotemArea"));
			}
		}
		return;
	}
	switch (CurHoldUnit->UnitType)
	{
	case EBuildingUnitType::Piece:
		{
			FBuildingPieceSyncData SpawnData;
			SpawnData.PieceID = CurHoldUnit->UnitID;
			SpawnData.SpawnTransform = CurHoldUnit->GetUnitTransform();
			SpawnData.SpawnTransform.SetLocation(UGameplayStatics::RebaseLocalOriginOntoZero(this, SpawnData.SpawnTransform.GetLocation()));
			SpawnData.bPreset = false;
			if (HoldUnitBindPalGuid.IsValid())
			{
				SpawnData.bMimicry = true;
				SpawnData.GUID = HoldUnitBindPalGuid;
			}
			if (APzPlayerController* SelfPlayerController = Cast<APzPlayerController>(GameUtil::GetSelfPlayerController(this)))
			{
				if(SpawnData.SpawnTransform.ContainsNaN())
				{
					UE_LOG(LogPzBuilding, Error, TEXT("RequestSpawnUnit|ServerCreateNewPiece|SpawnTransform ContainsNaN|%s"), *SpawnData.SpawnTransform.ToString());
				}
				else
				{
					SelfPlayerController->ServerCreateNewPiece(SelfPlayerController->GetPlayerState<APzPlayerState>(), SpawnData);
				}
			}
		}
		break;
	case EBuildingUnitType::Vehicle:
		{
			FVehicleSpawnData SpawnData;
			SpawnData.VehicleID = CurHoldUnit->UnitID;
			SpawnData.SpawnTransform = CurHoldUnit->GetUnitTransform();
			SpawnData.SpawnTransform.SetLocation(SpawnData.SpawnTransform.GetLocation() + FVector(0, 0, 400));
			SpawnData.SpawnTransform.SetLocation(UGameplayStatics::RebaseLocalOriginOntoZero(this, SpawnData.SpawnTransform.GetLocation()));
			if (APzPlayerController* SelfPlayerController = Cast<APzPlayerController>(GameUtil::GetSelfPlayerController(this)))
			{
				GameUtil::GetGameInstanceSubsystem<UPzVehicleManager>(this)->GetRPCComponent()->Server_CreateVehicle(SelfPlayerController->GetPlayerState<APzPlayerState>(), SpawnData);
			}
		}
		break;
	case EBuildingUnitType::PackagedHouse:
		if (auto HomelandTotemSystem = GameUtil::GetGameInstanceSubsystem<UHomelandTotemSubSystem>(this))
		{
			FTransform HouseTransform = CurHoldUnit->GetUnitTransform();
			HouseTransform.SetLocation(GameUtil::ZeroRebase(this, HouseTransform.GetLocation()));
			HomelandTotemSystem->C_ReqPackagedTotemPlaced(this, HouseTransform);
		}
		break;
	default:
		break;
	}
}
