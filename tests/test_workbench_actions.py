"""Selected production-action paths with explicit widget/native test doubles.

These checks exercise the exported handlers, not an Unreal widget tree or server.
"""
import unittest
from lupa import LuaRuntime
from test_portfolio import LUA, selected


class WorkbenchActions(unittest.TestCase):
    def setUp(self):
        self.assertIn('local TabCategory_Accessory = 8',
                      (LUA / 'WorkBench/WorkBenchPanel.lua').read_text(encoding='utf-8'))
        self.vm = LuaRuntime(unpack_returned_tuples=True)
        self.model = selected(self.vm, 'WorkBench/WorkBenchModel.lua', 'WorkBenchModel',
                              ['OnMakeClicked', 'func_MyMakeStart', 'func_MyMakeInterrupt', 'MyHidePanel'])
        self.panel = selected(self.vm, 'WorkBench/WorkBenchPanel.lua', 'WorkBenchPanel',
                              ['OnBtnMake', 'OnBuildLvBtnClicked', 'Func_RefreshAllBtn'])
        self.product = selected(self.vm, 'WorkBench/WorkBenchProduct.lua', 'WorkBenchProduct',
                                ['RefreshProductBtnGroup', 'RefreshProductBtnGroupForMake', 'OnBtnMake',
                                 'OnBtnInProducing', 'OnBtnMakeCanTake', 'PalProduce_StartCountDown',
                                 'PalProduce_StopCountDown', 'PalProduce_CountDownFinished',
                                 'PalProduce_CountDownUpdate', 'OnProduceInfoChanged'])
        self.vm.execute('''
            state={producing=false,paused=false,collectable=false,actionAllowed=true,
                   popupCloses=0,hides=0,requests=0,interrupts=0,progressStarts=0}
            WorkType_Make=1; WorkType_Enhance=2; WorkType_Repair=3; TabCategory_Accessory=8
            ItemMakeTable={BenchWorkType_Make=1, BenchWorkType_Enhance=2, BenchWorkType_Repair=3,
                MakeText_ConditionError='Requires level %d', MakeText_MaterialError='Track materials',
                MakeText_BagLimitError='Carry limit', MakeText_StartMake='Start crafting',
                MakeText_ConfirmMsgText='Confirm crafting',
                CheckExecuteMakeByActionType=function() return state.actionAllowed end}
            ESlateVisibility={Hidden='hidden',Visible='visible'}
            UE4={EPzTrackingRecipeType={TRACK_RECIPE_ENHANCE=7},
                 PzAudioUtil={PlayAudio=function() return 'audio-handle' end}}
            Timer={Always=function(_,interval) return interval end}
            EquipMadeExport={
                InteractivePiece_IsProducing=function() return state.producing end,
                InteractivePiece_IsPausing=function() return state.paused end,
                InteractivePiece_IsCanTake=function() return state.collectable end,
                InteractivePiece_GetPieceGUID=function() return 'bench-A' end,
                InteractivePiece_GetPieceOpType=function() return 2 end,
                CraftRecipe_GetCraftIdByItemTypeId=function(_,item) state.recipeItem=item; return 88 end,
                CarryMake_GetMakeTime=function() return 3 end,
                CarryMake_BeginProgressBar=function(_,id,time)
                    state.progressStarts=state.progressStarts+1; state.progressId=id; state.duration=time end,
                CarryMake_InterruptProgressBar=function() state.interrupts=state.interrupts+1 end}
            WorkBenchExport={
                WorkBench_ReqTakeProductWithPal=function(_,guid) state.collectGuid=guid end,
                WorkBench_ReqMakeItemWithPal=function(_,id,count,material)
                    state.requests=state.requests+1; state.makeId=id; state.count=count; state.material=material end}
            recipeModel={AddMaterialTrackingFrame=function(_,...) state.tracking={...} end}
            levelModel={LevelDescType={Make=6},ActiveBuildLevelFrame=function(_,data) state.guidance=data end}
            ModelManager={GetModel=function(_,name)
                if name=='RecipeModel' then return recipeModel end
                if name=='BuildLevelModel' then return levelModel end
                if name=='WorkBenchModel' then return WorkBenchModel end
                error('Unexpected model: '..name)
            end}
            EventSystem={Fire=function(name,...)
                state.lastEvent=name; state.args={...}
                if name=='UIEvent_WorkBenchProduct_MakeClicked' then WorkBenchPanel:OnBtnMake() end
                if name=='UIEvent_MessageBox_Show' then state.confirm=state.args[1].ConfirmLambda end
            end}
            WorkBenchProduct.UIBtnGroupSwitcher={SetActiveWidgetIndex=function(_,n) state.group=n end}
            WorkBenchProduct.UIBtnMakeSwitcher={SetActiveWidgetIndex=function(_,n) state.action=n end}
            WorkBenchProduct.UIBtnMake={
                SetVisibility=function(_,v) state.visibility=v end,
                SetText=function(_,v) state.text=v end,
                CommonButton={SetIsEnabled=function(_,v) state.enabled=v end}}
            WorkBenchProduct._visibleScope={
                CloseEvent=function(_,key) state.timer=nil; state.timerKey=key end,
                ListenEvent=function(_,key,interval,callback)
                    state.timerKey=key; state.interval=interval; state.timer=callback end}
            -- Explicit presentation boundary; popup widget assets are outside this test.
            WorkBenchProduct.HideAllPopPanel=function() state.popupCloses=state.popupCloses+1 end
            WorkBenchProduct.m_WorkType=1; WorkBenchProduct.m_WorkBench_NeedLevel=3
            WorkBenchProduct.m_MakeRecipeID=77
            WorkBenchPanel.m_BindModel=WorkBenchModel; WorkBenchPanel.m_UIProductGroup=WorkBenchProduct
            WorkBenchPanel.m_CurMakeRepeat=2
            WorkBenchPanel._target={Hide=function() state.hides=state.hides+1 end}
            WorkBenchPanel.PlayProductMakeEffect=function(_,id,play,time) state.effectId=id end
            WorkBenchPanel.SetBtnVisible_BlockClickOnMake=function(_,value) state.blocked=value end
            WorkBenchModel.Panel=WorkBenchPanel; WorkBenchModel.m_BenchMakeId=42
            WorkBenchModel.m_State_ConditionEnough=true; WorkBenchModel.m_State_MaterialEnough=true
            WorkBenchModel.m_State_ArriveTakeLimit=false; WorkBenchModel.m_State_InMaking=false
            WorkBenchModel.m_BenchWorkType=1; WorkBenchModel.m_TabCategory=8
            WorkBenchModel.m_ProductItemTypeId=99; WorkBenchModel.m_EquipClientIDForMaterial=123
            WorkBenchModel.IsItemMakeWithPal=true
            -- Context lookup / native make-ID binding are external collaborators here.
            WorkBenchModel.GetCurWorkBenchGuid=function() return 'bench-A' end
            WorkBenchModel.SetCurrMakeID=function(_,id) state.currentMake=id end
        ''')
        self.state = self.vm.globals().state

    def refresh(self):
        self.product.RefreshProductBtnGroup(self.product)

    def test_no_selection_hides_primary_action(self):
        self.model.m_BenchMakeId = 0
        self.refresh()
        self.assertEqual(self.state.visibility, 'hidden')
        self.assertIsNone(self.state.timer)

    def test_producing_precedes_paused_collectable_and_shortage(self):
        self.state.producing = self.state.paused = self.state.collectable = True
        self.model.m_State_MaterialEnough = False
        self.refresh()
        self.assertEqual((self.state.action, self.state.interval), (4, 1))
        self.assertIsNotNone(self.state.timer)
        self.assertIsNone(self.state.text)

    def test_paused_precedes_collectable_without_polling(self):
        self.state.paused = self.state.collectable = True
        self.refresh()
        self.assertEqual(self.state.action, 4)
        self.assertIsNone(self.state.timer)

    def test_collectable_precedes_new_recipe_requirements(self):
        self.state.collectable = True
        self.model.m_State_ConditionEnough = False
        self.refresh()
        self.assertEqual(self.state.action, 5)
        self.assertIsNone(self.state.timer)

    def test_level_failure_keeps_guidance_action_enabled(self):
        self.model.m_State_ConditionEnough = self.model.m_State_MaterialEnough = False
        self.refresh()
        self.assertEqual((self.state.text, self.state.enabled), ('Requires level 3', True))
        self.product.OnBtnMake(self.product)
        self.assertEqual((self.state.guidance.PieceGuid, self.state.guidance.LevelDescType), ('bench-A', 6))
        self.assertEqual(self.state.requests, 0)

    def test_material_failure_opens_tracking_not_a_make_request(self):
        self.model.m_State_MaterialEnough = False
        self.refresh()
        self.product.OnBtnMake(self.product)
        self.assertEqual((self.state.text, self.state.enabled), ('Track materials', True))
        self.assertEqual(self.state.tracking[1], 77)
        self.assertEqual((self.state.requests, self.state.popupCloses), (0, 1))

    def test_enhancement_material_tracking_preserves_level_and_type(self):
        self.model.m_State_MaterialEnough = False
        self.product.m_EnhanceChangeData = self.vm.table_from({'EnhanceLevelA': 4, 'ItemTypeId': 99})
        self.product.OnBtnMake(self.product)
        self.assertEqual([self.state.tracking[i] for i in (1, 2, 3)], [88, 4, 7])
        self.assertEqual(self.state.recipeItem, 99)

    def test_carry_limit_disables_button_and_model_also_blocks_dispatch(self):
        self.model.m_State_ArriveTakeLimit = True
        self.refresh()
        self.assertEqual((self.state.text, self.state.enabled), ('Carry limit', False))
        self.product.OnBtnMake(self.product)  # Simulate direct invocation past the widget gate.
        self.assertEqual(self.state.requests, 0)

    def test_ready_click_reaches_native_request_through_panel_and_model(self):
        self.refresh()
        self.assertEqual((self.state.text, self.state.enabled), ('Start crafting', True))
        self.product.OnBtnMake(self.product)
        self.assertEqual((self.state.requests, self.state.makeId, self.state.count, self.state.material),
                         (1, 42, 2, 123))
        self.assertEqual(self.state.hides, 1)
        self.assertEqual(self.state.progressStarts, 0)

    def test_current_action_gate_blocks_start(self):
        self.state.actionAllowed = False
        self.product.OnBtnMake(self.product)
        self.assertEqual(self.state.requests, 0)

    def test_confirmation_defers_native_request(self):
        self.model.m_TabCategory = 1
        self.model.m_SuccessGainFirstUseExpNum = 0
        self.product.OnBtnMake(self.product)
        self.assertEqual(self.state.requests, 0)
        self.assertIsNotNone(self.state.confirm)
        self.state.confirm()
        self.assertEqual(self.state.requests, 1)
        self.assertFalse(self.model.m_IsShowConfirmMsgBox)

    def test_local_progress_path_is_distinct_from_native_queue_request(self):
        self.model.IsItemMakeWithPal = False
        self.product.OnBtnMake(self.product)
        self.assertEqual((self.state.requests, self.state.progressStarts, self.state.progressId), (0, 1, 42))
        self.assertEqual((self.state.action, self.state.blocked), (1, True))
        self.assertFalse(self.model.m_State_ReceivedSuccessMsg)

    def test_local_stop_requests_interruption_only_before_progress_completion(self):
        self.model.m_State_InMaking = True
        self.model.m_State_ReceivedPrograssMsg = False
        self.refresh()
        self.assertEqual(self.state.action, 1)
        self.product.OnBtnMake(self.product)
        self.assertEqual(self.state.interrupts, 1)
        self.model.m_State_ReceivedPrograssMsg = True
        self.product.OnBtnMake(self.product)
        self.assertEqual(self.state.interrupts, 1)

    def test_cancel_and_collect_use_current_object_context(self):
        self.product.OnBtnInProducing(self.product)
        self.assertEqual(self.state.lastEvent, 'LogicEvent_WorkBenchUI_CancelMake')
        self.assertEqual((self.state.args[1], self.state.args[2]), ('bench-A', 2))
        self.product.OnBtnMakeCanTake(self.product)
        self.assertEqual(self.state.collectGuid, 'bench-A')

    def test_poll_uses_native_collectability_not_elapsed_time(self):
        self.state.producing = True
        self.refresh()
        callback = self.state.timer
        callback()
        self.assertEqual(self.state.action, 4)
        self.state.producing = False
        self.state.collectable = True
        callback()
        self.assertEqual(self.state.action, 5)
        self.assertIsNone(self.state.timer)

    def test_production_notification_replaces_poll_with_current_state(self):
        self.state.producing = True
        self.refresh()
        self.state.producing = False
        self.state.paused = True
        self.product.OnProduceInfoChanged(self.product)
        self.assertEqual(self.state.action, 4)
        self.assertIsNone(self.state.timer)


if __name__ == '__main__':
    unittest.main(verbosity=2)
