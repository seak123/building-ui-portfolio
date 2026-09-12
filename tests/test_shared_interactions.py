"""Real included adapters with controlled configuration, UI and native services."""
import unittest
from lupa import LuaRuntime
from test_portfolio import LUA, text


BOOT = '''
state={opens=0,refreshes=0,hides=0,now=100}
events={}; commands={}; models={}; configs={}
function config(rows)
    return {GetCount=function() return #rows end,GetRowByIndex=function(_,i) return rows[i+1] end,
            GetRowByKey=function(_,id) return {ButtonIcon='icon',OpTypeParams={Length=1,[0]={ParamType=10,ParamParam=5}}} end}
end
function FGuid() return 'zero' end
ModelManager={CreateModel=function(_,name)
    local m={}; models[name]=m; return m,{_init=function() end}
end,GetModel=function(_,name) return models[name] or {} end}
CreateUIBehaviourFromListView=function() return {},{} end
ConfigManager={GetTable=function(name) return configs[name] or config({}) end}
ResMacros={BUILD_OBJ_OP_PARAM_TYPE_OP_TIME=10}
ProtoMacro={MACROS_XY_CS_CONSTS={E_CONT_ITEM_BAG=1,E_CONT_SHORTCUT_BAR=2}}
EKGNoticeType={Normal=1}
LocalizationFText={FromStr=function(s) return {str=s} end}
EventSystem={Fire=function(name,...) table.insert(events,{name,...}) end}
GameUtil={GetUtcTimeStampSecond=function() return state.now end}
FrameManager={IsHUDFrameShow=function() return state.hud~=false end}
UE={UGameLuaLibrary={GetMyPlayerRID=function() return 1 end}}
building={}
interaction={GetSpecialInteractionName=function() return 'Select item' end}
bag={[0]={ItemTypeId=101,GetCount=function() return 2 end}}
shortcut={[1]={ItemTypeId=101,GetCount=function() return 1 end}}
inventory={GetContainerData=function(_,kind)
    return {ContainerCurSize=2,GetContainerItem=function(_,i) return (kind==1 and bag or shortcut)[i] end}
end}
logic={CheckFGUIDEqual=function(_,a,b) return a==b end,
    OnWeaponShelfHang=function(_,...) table.insert(commands,{'hang',...}) end}
UE4={BuildingFunctionLibrary={GetBuildingManager=function() return building end},
    PzBuildUtil={GetBuildInteractionSystem=function() return interaction end},
    PzGameLuaLibrary={CheckGuidIsEqual=function(a,b) return a==b end,CheckGuidIsEqualValid=function(a,b) return a==b and a~='zero' end},
    PzInventoryLibrary={GetInventoryManager=function() return inventory end},PzLogicLibrary=logic}
behaviour={ShowData=function(_,data) state.opens=state.opens+1; state.data=data end,
    RefreshList=function(_,data) state.refreshes=state.refreshes+1; state.data=data end,
    OnHideView=function() state.hides=state.hides+1 end}
__BehaviourManager={GetBehaviour=function() return behaviour end}
UIUtil={AddUniqueFrameAsync=function(_,cb) cb({GetUniqueID=function() return 1 end}) end,
    TextStringFormat=function(s,key,value) return s..'|'..key..'='..value end}
configs.ResHomelandHangableItemConfig=config({{TargetObj=7,ItemId=101},{TargetObj=8,ItemId=102}})
'''


class SharedInteractions(unittest.TestCase):
    def setUp(self):
        self.vm = LuaRuntime(unpack_returned_tuples=True)
        self.vm.execute(BOOT)
        self.common = self.load('AdditionModel.lua')
        self.common._init(self.common)
        self.rack = self.load('SubPartModel/AdditionWeaponShelfModel.lua')
        self.rack._init(self.rack)
        self.g = self.vm.globals()

    def load(self, name):
        return self.vm.execute(text(LUA/'Interaction/Addition'/name))

    def open_rack(self):
        self.rack.OnOpenHangView(self.rack,None,None,7,'rack-A',20)

    def test_shared_context_requires_guid_and_type(self):
        self.open_rack()
        for guid,kind,expected in [('rack-A','WeaponShelf',True),('rack-B','WeaponShelf',False),('rack-A','OtherInteraction',False)]:
            self.assertEqual(bool(self.common.CheckIsCurInteractionEntity(self.common,guid,kind)),expected)

    def test_empty_refresh_hides_instead_of_presenting_stale_candidates(self):
        self.open_rack()
        self.common.RefreshAdditionPanel(self.common,self.vm.eval('{interactionData={}}'))
        self.assertEqual(self.g.state.hides,1)

    def test_frame_leave_requires_object_and_interaction(self):
        frame = self.load('AdditionFrame.lua')
        frame.ActorGuid='rack-A'
        frame.additionData=self.vm.eval('{interactionID=20}')
        frame._target=self.vm.eval('{Hide=function() state.hides=state.hides+1 end}')
        frame.OnBuildInteractionLeave(frame,None,None,20,'rack-B',False)
        frame.OnBuildInteractionLeave(frame,None,None,21,'rack-A',False)
        self.assertEqual(self.g.state.hides,0)
        frame.OnBuildInteractionLeave(frame,None,None,20,'rack-A',False)
        self.assertEqual(self.g.state.hides,1)

    def test_frame_hides_when_hud_unavailable(self):
        frame=self.load('AdditionFrame.lua')
        frame._target=self.vm.eval('{Hide=function() state.hides=state.hides+1 end}')
        frame.CheckValid(frame)
        self.assertEqual(self.g.state.hides,0)
        self.g.state.hud=False
        frame.CheckValid(frame)
        self.assertEqual(self.g.state.hides,1)

    def test_configured_cooldown_early_return_characterisation(self):
        # Current code fails to store the configured five seconds; not a claimed fix.
        self.common.SetInteractionColdTime(self.common,20)
        self.common.CacheInteractionTime(self.common)
        self.assertTrue(self.common.CheckInCold(self.common))

    def test_rack_retains_bag_and_shortcut_positions(self):
        self.open_rack()
        rows=self.g.state.data.interactionData
        self.assertEqual(len(rows),2)
        self.assertEqual((rows[1].itemTypeID,rows[1].containerType,rows[1].containerPos),(101,1,0))
        self.assertEqual((rows[2].containerType,rows[2].containerPos),(2,1))
        self.rack.OnItemHang(self.rack,None,None,rows[2])
        self.assertEqual([self.g.commands[1][i] for i in range(1,6)],['hang','rack-A',101,2,1])

    def test_rack_rejects_other_interaction_key(self):
        self.open_rack()
        self.rack.OnItemHang(self.rack,None,None,self.vm.eval('{Key="OtherInteraction",itemTypeID=101}'))
        self.assertEqual(len(self.g.commands),0)

    def test_rack_occupancy_closes_and_notifies_for_other_player(self):
        self.open_rack()
        self.rack.OnHangeItemChange(self.rack,None,None,'rack-B',101,2)
        self.assertEqual(len(self.g.events),0)
        self.rack.OnHangeItemChange(self.rack,None,None,'rack-A',101,2)
        self.assertEqual(self.g.events[1][1],'Ineraction_Addition_HideView')
        self.assertEqual(self.g.events[2][1],'AppendNotice')

    def test_rack_own_change_closes_without_occupied_notice(self):
        self.open_rack()
        self.rack.OnHangeItemChange(self.rack,None,None,'rack-A',101,1)
        self.assertEqual(len(self.g.events),1)
        self.assertEqual(self.g.events[1][1],'Ineraction_Addition_HideView')

    def test_adapter_refresh_follows_current_interaction_type(self):
        self.open_rack()
        self.common.ActorGuid='rack-B'
        self.rack.OnContainerUpdate(self.rack)
        self.assertEqual(self.g.state.refreshes,0)
        self.common.ActorGuid='rack-A'
        self.rack.OnContainerUpdate(self.rack)
        self.assertEqual(self.g.state.refreshes,1)


if __name__ == '__main__':
    unittest.main(verbosity=2)
