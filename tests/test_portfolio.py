"""Focused checks of included Lua methods; not a simulated Unreal runtime."""
from pathlib import Path
import hashlib
import itertools
import json
import re
import unittest
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
LUA = ROOT / 'Content/Lua/GameLogics'


def text(path):
    return path.read_text(encoding='utf-8')


def method_chunks(path):
    source = text(path)
    result = {}
    for match in re.finditer(r'^function\s+([\w.:]+)\s*\([^\n]*\)[^\n]*', source, re.M):
        close = re.search(r'^end\b[^\n]*', source[match.end():], re.M)
        if not close:
            raise AssertionError(f'Missing method end: {match.group(1)}')
        result[match.group(1)] = source[match.start():match.end()+close.end()]
    return result


def selected(vm, rel, cls, methods):
    chunks = method_chunks(LUA/rel)
    bodies = []
    for name in methods:
        chunk = chunks[f'{cls}:{name}']
        if '-- Implementation omitted.' in chunk:
            raise AssertionError(f'Omitted body requested: {name}')
        bodies.append(chunk)
    return vm.execute(f'{cls}={{}}\n'+'\n'.join(bodies)+f'\nreturn {cls}')


def enum(vm, rel, name):
    match = re.search(r'local\s+'+name+r'\s*=\s*(\{.*?\})', text(LUA/rel), re.S)
    assert match, name
    vm.execute(name+'='+match.group(1))


class PublicFiles(unittest.TestCase):
    def test_all_lua_parses(self):
        vm = LuaRuntime()
        compile_only = vm.eval('function(s,n) local f,e=load(s,n); assert(f,e) end')
        for path in LUA.rglob('*.lua'):
            with self.subTest(path=path.name):
                compile_only(text(path), path.name)

    def test_manifest_and_checksums(self):
        manifest = json.loads(text(ROOT/'docs/source-manifest.json'))
        for source in manifest['sources']:
            self.assertEqual(set(source), {'path','retained_methods','omitted_bodies','sha256'})
            self.assertEqual(hashlib.sha256(text(ROOT/source['path']).encode()).hexdigest(), source['sha256'])

    def test_local_links(self):
        paths = [ROOT/'README.md', *list((ROOT/'docs').glob('*.md')), *list((ROOT/'media').glob('*.md'))]
        for path in paths:
            for link in re.findall(r'\]\(([^)]+)\)', text(path)):
                if '://' not in link and not link.startswith('#'):
                    with self.subTest(path=path.name, link=link):
                        self.assertTrue((path.parent/link.split('#')[0]).exists())

    def test_no_internal_metadata(self):
        files = [ROOT/'README.md']
        for directory in ['Content','Source','docs','media']:
            files += [p for p in (ROOT/directory).rglob('*') if p.is_file() and p.suffix in {'.md','.json','.lua','.cpp','.h'}]
        for path in files:
            with self.subTest(path=path.name):
                self.assertNotRegex(text(path), r'(?i)(?:ssh|git)://|git@[^\s:]+:|original_revision|--(?:bug|story)=\d+|[A-Z]:[\\/]Users[\\/]|Created by\s+\w+')

    def test_omitted_method_cannot_be_loaded_as_working_code(self):
        with self.assertRaisesRegex(AssertionError, 'Omitted body'):
            selected(LuaRuntime(), 'BuildSpace/BuildSpaceModel.lua', 'BuildSpaceModel', ['ShowBuildSpaceDebugFrame'])


class PlacementInput(unittest.TestCase):
    def setUp(self):
        self.vm = LuaRuntime(unpack_returned_tuples=True)
        self.vm.execute('''
            state={pc=true,hud=true,mode=1}; calls={}
            UE4={EBuildingSystemMode={BuildMode=1,FarmMode=2},PzPCInteractionLibrary={IsUsePCInteraction=function() return state.pc end}}
            FrameManager={IsInModeHUDState=function(_,name) assert(name=="BuildSystem"); return state.hud end}
            BuildHoldFlowSystem={GetCurSystemMode=function() return state.mode end}
            BuildSpaceOpBitState={CAN_BUILD=1,CANT_BUILD=2,CAN_COAT=3,CANT_COAT=4}
            bits={}
        ''')
        self.item = selected(self.vm,'BuildSpace/BuildSpaceOperatWidget.lua','BuildSpaceOperatWidget',['CheckBuildActionValid','OnBuildActionConfirm'])
        self.vm.execute('''
            BuildSpaceOperatWidget.CheckOpBitMask=function(_,key) return bits[key] or false end
            BuildSpaceOperatWidget.OnBuildBtn=function() calls.build=(calls.build or 0)+1 end
            BuildSpaceOperatWidget.OnUnitCoat=function() calls.coat=(calls.coat or 0)+1 end
            BuildSpaceOperatWidget.OnUnValidCoat=function() calls.invalidCoat=(calls.invalidCoat or 0)+1 end
        ''')

    def test_pc_hud_and_native_mode_matrix(self):
        state = self.vm.globals().state
        for pc,hud,mode in itertools.product([False,True],[False,True],[0,1,2,3]):
            state.pc,state.hud,state.mode = pc,hud,mode
            with self.subTest(pc=pc,hud=hud,mode=mode):
                self.assertEqual(self.item.CheckBuildActionValid(self.item),pc and hud and mode in (1,2))

    def test_invalid_placement_routes_to_feedback_handler(self):
        self.vm.globals().bits[2] = True
        self.item.OnBuildActionConfirm(self.item)
        self.assertEqual(self.vm.globals().calls.build,1)
        self.vm.globals().state.hud = False
        self.item.OnBuildActionConfirm(self.item)
        self.assertEqual(self.vm.globals().calls.build,1)

    def test_coating_actions_are_distinct(self):
        g=self.vm.globals()
        g.bits[3]=True
        self.item.OnBuildActionConfirm(self.item)
        self.assertEqual(g.calls.coat,1)
        g.bits[3]=False
        g.bits[4]=True
        self.item.OnBuildActionConfirm(self.item)
        self.assertEqual(g.calls.invalidCoat,1)


class Processing(unittest.TestCase):
    MODEL='BuildProduce/BuildProduceModel.lua'
    FRAME='BuildProduce/SemiProduce/SemIProduceFrame.lua'

    def setUp(self):
        self.vm=LuaRuntime(unpack_returned_tuples=True)
        enum(self.vm,self.MODEL,'RecipeState')
        enum(self.vm,self.FRAME,'BtnState')
        self.vm.execute('''
            state={exists=true,unlocked=true,conditions=true,materials=true,slots=0,maxSlots=3,entity=true}
            calls={condition=0,material=0}; sent={}; tracked={}
            CraftConfig={GetRowByKey=function() if state.exists then return {CraftRecipeId=10} end end}
            UE4={DimensionalDataExport={IsRecipeUnlock=function() return state.unlocked end}}
            LuaLibrary={CheckGuidIsEqualValid=function(a,b) return a~=nil and a==b end}
        ''')
        self.model=selected(self.vm,self.MODEL,'BuildProduceModel',['GetCraftProduceItemState','GetRecipeState'])
        self.vm.execute('''
            BuildProduceModel.GetCraftConditionValid=function() calls.condition=calls.condition+1; return state.conditions end
            BuildProduceModel.GetCraftMaterialValid=function(_,_,count) calls.material=calls.material+1; calls.quantity=count; return state.materials end
            work={GetAllQueueWorkData=function() return {Num=function() return state.slots end} end}
            BuildProduceModel.GetQueueWorkEntityByGuid=function() if state.entity then return work end end
            BuildProduceModel.GetQueueWorkSlotMaxCount=function() return state.maxSlots end
            BuildProduceModel.GetSmeiCreateInteractID=function() return 7 end
            BuildInteractionSystem={SendCraftMakeReq=function(_,guid,id,recipe,count) sent={guid,id,recipe,count} end}
            RecipeModel={AddMaterialTrackingFrame=function(_,id) tracked.recipe=id end}
            EventSystem={Fire=function() calls.notice=true end}; EKGNoticeType={Normal=1}
            LocalizationFText={FromStr=function(s) return s end}
        ''')
        self.frame=selected(self.vm,self.FRAME,'SemiProduceFrame',['GetBtnState','OnStartProduceBtn','OnBuildInteractionLeave','OnQueueWorkEntityWorkDataChanged'])
        self.vm.execute('''
            SemiProduceFrame.PieceGuid='station-A'; SemiProduceFrame.InteractionID=99
            SemiProduceFrame.SelectCraftData={CraftID=5,RecipeID=10,MakeCount=4,RecipeState=RecipeState.CanMake}
            SemiProduceFrame.Hide=function() calls.hide=(calls.hide or 0)+1 end
            SemiProduceFrame.RefreshQueueWorkData=function() calls.refresh=(calls.refresh or 0)+1 end
        ''')

    def test_recipe_eligibility_precedence(self):
        g=self.vm.globals()
        cases=[(False,False,False,False,0),(True,False,False,False,1),(True,True,False,False,2),(True,True,True,False,3),(True,True,True,True,4)]
        for exists,unlock,cond,mat,expected in cases:
            g.state.exists,g.state.unlocked,g.state.conditions,g.state.materials=exists,unlock,cond,mat
            with self.subTest(expected=expected):
                self.assertEqual(self.model.GetCraftProduceItemState(self.model,5,'station-A',4),expected)
        self.assertEqual(g.calls.quantity,4)

    def test_full_queue_precedes_material_shortage(self):
        g=self.vm.globals()
        self.frame.SelectCraftData.RecipeState=g.RecipeState.CanNotMake_Material
        self.assertEqual(self.frame.GetBtnState(self.frame),g.BtnState.CanNotMake_Material)
        g.state.slots=3
        self.assertEqual(self.frame.GetBtnState(self.frame),g.BtnState.WorkFull)

    def test_create_and_material_tracking_are_different_actions(self):
        g=self.vm.globals()
        self.frame.CurStartBtnState=g.BtnState.CanNotMake_Material
        self.frame.OnStartProduceBtn(self.frame)
        self.assertEqual(g.tracked.recipe,10)
        self.assertEqual(g.RecipeModel.trackNum,4)
        self.assertIsNone(g.sent[1])
        self.frame.CurStartBtnState=g.BtnState.Normal
        self.frame.OnStartProduceBtn(self.frame)
        self.assertEqual([g.sent[i] for i in range(1,5)],['station-A',7,5,4])

    def test_leave_requires_matching_object_and_interaction(self):
        g=self.vm.globals()
        for guid,interaction in [('station-B',99),('station-A',98),('station-A',99)]:
            self.frame.OnBuildInteractionLeave(self.frame,None,None,interaction,guid,False)
        self.assertEqual(g.calls.hide,1)

    def test_queue_refresh_filters_object_identity(self):
        self.frame.OnQueueWorkEntityWorkDataChanged(self.frame,None,None,'station-B')
        self.frame.OnQueueWorkEntityWorkDataChanged(self.frame,None,None,'station-A')
        self.assertEqual(self.vm.globals().calls.refresh,1)

    def test_missing_entity_contract_is_explicit(self):
        # Characterises the existing return, not a claim it is safe to produce.
        self.vm.globals().state.entity=False
        self.assertEqual(self.frame.GetBtnState(self.frame),self.vm.globals().BtnState.Normal)


class StorageRefresh(unittest.TestCase):
    def setUp(self):
        self.vm=LuaRuntime(unpack_returned_tuples=True)
        self.vm.execute('''
            metrics={clear=0,add=0,acquire=0,refresh=0}
            ProtoMacro={MACROS_XY_CS_CONSTS={E_CONT_STORAGE_BOX=6}}
            UE4={EPzDragScrollOrientation={Vertical=1}}
            items={[0]={ItemClientId=11},[2]={ItemClientId=33}}
            container={ContainerCurSize=3,ContainerMaxSize=6,GetContainerItem=function(_,i) return items[i] end}
            DataObjectPool={Get=function(_,data) metrics.acquire=metrics.acquire+1; return data end}
            behaviour={UpdateView=function(_,force) assert(force); metrics.refresh=metrics.refresh+1 end}
            __BehaviourManager={GetBehaviour=function() return behaviour end}
            visible={Num=function() return 2 end,Get=function(_,i) return {GetUniqueID=function() return i end} end}
            list={ClearListItems=function() metrics.clear=metrics.clear+1 end,
                  AddItem=function() metrics.add=metrics.add+1 end,GetDisplayedEntryWidgets=function() return visible end}
            PzLogicLibrary={CheckFGUIDEqual=function(_,a,b) return a==b end}
        ''')
        self.item=selected(self.vm,'StorageBox/StorageBoxWidget.lua','StorageBoxWidget',['ClearListView','SetContainerInfo','OnBoxContainerUpdate'])
        self.vm.execute('''
            StorageBoxWidget.boxMaxCountRecord=0; StorageBoxWidget.DefaultClientId=0
            StorageBoxWidget.ItemListViewData={}; StorageBoxWidget.ItemListView=list
            StorageBoxWidget.boxModel={GetCurBoxContainerData=function() return container end, GetCurBoxGuid=function() return 'box-A' end}
        ''')

    def test_stable_capacity_reuses_slots_and_refreshes_displayed_rows(self):
        self.item.SetContainerInfo(self.item)
        g=self.vm.globals()
        g.oldFirst=self.item.ItemListViewData[1]
        g['items'][0]=g['items'][2]
        self.item.SetContainerInfo(self.item)
        self.assertTrue(self.vm.eval('rawequal(oldFirst,StorageBoxWidget.ItemListViewData[1])'))
        self.assertEqual(self.item.ItemListViewData[1].ItemClientId,33)
        self.assertEqual((g.metrics.clear,g.metrics.add,g.metrics.acquire,g.metrics.refresh),(1,3,3,2))

    def test_capacity_change_rebuilds(self):
        self.item.SetContainerInfo(self.item)
        g=self.vm.globals()
        g.container.ContainerCurSize=4
        self.item.SetContainerInfo(self.item)
        self.assertEqual((g.metrics.clear,g.metrics.add,g.metrics.acquire),(2,7,7))

    def test_unrelated_box_update_does_not_populate(self):
        self.item.OnBoxContainerUpdate(self.item,None,None,'box-B')
        self.assertEqual(self.vm.globals().metrics.add,0)
        self.item.OnBoxContainerUpdate(self.item,None,None,'box-A')
        self.assertEqual(self.vm.globals().metrics.add,3)


class PanelLifetime(unittest.TestCase):
    def test_storage_range_check_closes_only_out_of_range(self):
        vm=LuaRuntime()
        frame=selected(vm,'StorageBox/StorageBoxFrame.lua','StorageBoxFrame',['OnCheckPlayerDistance','OnCloseView'])
        vm.execute('''
            state={inRange=true,hidden=0}
            StorageBoxFrame.boxModel={CheckPlayerDistance=function() return state.inRange end}
            StorageBoxFrame._target={Hide=function() state.hidden=state.hidden+1 end}
        ''')
        frame.OnCheckPlayerDistance(frame)
        self.assertEqual(vm.globals().state.hidden,0)
        vm.globals().state.inRange=False
        frame.OnCheckPlayerDistance(frame)
        self.assertEqual(vm.globals().state.hidden,1)

    def test_progress_start_stop_and_native_reanchor(self):
        vm=LuaRuntime()
        item=selected(vm,'BuildProduce/SemiProduce/SemiProduceSlotEntry.lua','SemiProduceSlotEntry',['StartTick','EndTick','ResetSimulateTime','UpdataValue'])
        vm.execute('''
            state={processed=20,total=100,rate=2,refresh=0}
            BuildProduceModel={GetQueueWorkEntityByGuid=function() return {GetQueueWorkData=function() return {ProcessedWorkloadAmount=state.processed,UnitProcessWorkloadAmount=state.total,WorkRate=state.rate} end} end}
            SemiProduceSlotEntry.Data={PieceGuid='station-A',Index=0}
            SemiProduceSlotEntry.RefreshSimulateTime=function() state.refresh=state.refresh+1 end
        ''')
        item.StartTick(item)
        self.assertTrue(item.IsSimulating)
        item.UpdataValue(item,0.5)
        self.assertEqual(item.PassTime,21)
        vm.globals().state.processed=70
        item.ResetSimulateTime(item)
        self.assertEqual(item.PassTime,70)
        item.EndTick(item)
        self.assertFalse(item.IsSimulating)


if __name__ == '__main__':
    unittest.main(verbosity=2)
