"""Workbench entry/exit contracts and integrity of the supplied PNG gallery."""
import struct
import unittest
from lupa import LuaRuntime
from test_portfolio import ROOT, selected


class WorkbenchIntegration(unittest.TestCase):
    def setUp(self):
        self.vm = LuaRuntime(unpack_returned_tuples=True)
        self.vm.execute('''
            state={loads=0,shows=0,hides=0,cleanups=0,stops=0,clears=0,resets=0,interrupts=0}
            Panel_Path='controlled-panel-path'
            ItemMakeTable={BenchOpenType_PieceObj=10}
            ResMacros={BUILDING_OP_TYPE_EQUIP_TABLE_2=2,BUILDING_OP_TYPE_EQUIP_TABLE_3=3}
            UE4={PzLogicLibrary={GetFGUIDToString=function(_,guid) return guid end}}
            WorkBenchExport={WorkBench_GetInteractiveTraceLimit=function() return 300 end,
                Synthesis_GetInteractiveTraceLimit=function() return 400 end,
                StartCheckLeavePieceEntity=function(_,guid,distance,event)
                    state.guid=guid; state.distance=distance; state.event=event
                end,
                StopCheckLeavePieceEntity=function() state.stops=state.stops+1 end}
            EquipMadeExport={InteractivePiece_ClearPieceParam=function() state.clears=state.clears+1 end}
            WorkBenchTable={StartWorkBenchPanel=function(kind) state.kind=kind end}
            panel={OnMyShowPanel=function() state.shows=state.shows+1 end,
                OnMyHidePanel=function() state.cleanups=state.cleanups+1 end,
                _target={Hide=function() state.hides=state.hides+1 end}}
            __BehaviourManager={GetBehaviour=function() return panel end}
            UIUtil={AddUniqueFrameAsync=function(path,callback)
                state.loads=state.loads+1
                callback({GetUniqueID=function() return 1 end})
            end}
        ''')
        methods=['OnSetUIVisible','MyShowPanel','MyHidePanel','OnHidePanel','IsPanelVisible']
        self.equipment=selected(self.vm,'WorkBench/WorkBenchModel.lua','WorkBenchModel',methods+['OnLeaveWorkBench'])
        self.crafting=selected(self.vm,'PalWorkBench/PalWorkBenchModel.lua','PalWorkBenchModel',methods+['OnLeaveBuildPiece'])
        self.g=self.vm.globals()

    def test_equipment_world_entry_preserves_guid_operation_and_margin(self):
        m=self.equipment
        m.OnSetUIVisible(m,None,None,True,'bench-A',2)
        self.assertEqual(m.m_BenchOpenType,10)
        self.assertEqual((self.g.state.guid,self.g.state.kind,self.g.state.distance),('bench-A',2,330))
        self.assertEqual(self.g.state.event,'LogicEvent_WorkBenchUI_Leave')
        self.assertEqual((self.g.state.loads,self.g.state.shows),(1,1))
        self.assertTrue(self.vm.eval('rawequal(panel.m_BindModel,WorkBenchModel)'))

    def test_crafting_reuses_bound_panel_and_has_own_leave_event(self):
        m=self.crafting
        m.OnSetUIVisible(m,None,None,True,'craft-A')
        m.MyShowPanel(m,'craft-A')
        self.assertEqual((self.g.state.distance,self.g.state.event),(430,'LogicEvent_PalWorkBenchUI_Leave'))
        self.assertEqual((self.g.state.loads,self.g.state.shows),(1,2))

    def test_leaving_and_visibility_false_request_hide(self):
        m=self.equipment
        m.OnSetUIVisible(m,None,None,True,'bench-A',2)
        m.OnLeaveWorkBench(m)
        m.OnSetUIVisible(m,None,None,False,'bench-A',2)
        self.assertEqual(self.g.state.hides,2)
        self.assertEqual(self.g.state.stops,0)  # Hide is not a fake framework destruction callback.

    def test_cleanup_releases_context_and_delegates_local_interruption(self):
        for m in [self.equipment,self.crafting]:
            m.Panel=self.g.panel
            m.m_State_InMaking=True
            m.func_MyMakeInterrupt=self.vm.eval('function() state.interrupts=state.interrupts+1 end')
            m.MyResetData=self.vm.eval('function() state.resets=state.resets+1 end')
            m.OnHidePanel(m)
            self.assertIsNone(m.Panel)
        self.assertEqual((self.g.state.stops,self.g.state.clears,self.g.state.cleanups,
                          self.g.state.interrupts,self.g.state.resets),(2,2,2,2,2))


class Gallery(unittest.TestCase):
    def test_five_full_resolution_pngs_and_gallery_links(self):
        expected={'Building_Catalogue.png','Building_Placement.png','Equipment_Workbench.png',
                  'Crafting_Workbench.png','Storage_Box.png'}
        directory=ROOT/'media/screenshots'
        self.assertEqual({p.name for p in directory.glob('*.png')},expected)
        readme=(ROOT/'README.md').read_text(encoding='utf-8')
        for name in expected:
            with self.subTest(image=name):
                with (directory/name).open('rb') as stream:
                    header=stream.read(24)
                self.assertEqual(header[:8],b'\x89PNG\r\n\x1a\n')
                self.assertEqual(header[12:16],b'IHDR')
                self.assertEqual(struct.unpack('>II',header[16:24]),(1920,1080))
                self.assertIn('media/screenshots/'+name,readme)


if __name__ == '__main__':
    unittest.main(verbosity=2)
