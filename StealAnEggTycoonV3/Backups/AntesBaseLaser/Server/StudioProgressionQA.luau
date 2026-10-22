-- Opt-in feature smoke checks. No profile or DataStore writes.
local QA={}
function QA.Run(C,Progression,Persistence)
 local passed={}
 local function expect(value,label) assert(value,label);table.insert(passed,label) end
 local service=Progression.new({Config=C})
 local persistence=setmetatable({Ctx={Config=C}},Persistence)
 local state={Profile=persistence:Default(),Ready=true,Runtime={},Pending={},LastCombat=0}
 local p=state.Profile
 expect(#service:Snapshot(state)==7,'Seven configured progression missions')
 expect(not service:Claim(state,'first_hatch'),'Incomplete mission cannot be claimed')
 service:Record(state,'Hatches',1)
 expect(service:Snapshot(state)[1].Complete,'Authoritative hatch completes first objective')
 local before=p.Inventory.Belt
 expect(service:Claim(state,'first_hatch') and p.Inventory.Belt==before+10 and p.Cash==0,'Claim grants construction pieces and no money')
 expect(not service:Claim(state,'first_hatch') and p.Inventory.Belt==before+10,'Mission reward is granted once')
 state.Profile=persistence:Normalize(persistence:Snapshot(state));p=state.Profile
 expect(p.Progress.Claimed.first_hatch and not service:Claim(state,'first_hatch'),'Claim acknowledgement survives saved profile normalization')
 service:Record(state,'Sales',1);state.Carry={Kind='Egg'}
 expect(not service:Claim(state,'first_sale'),'Reward claim waits for transport completion')
 state.Carry=nil
 expect(service:Claim(state,'first_sale'),'Completed sale objective grants its configured reward')
 p.Discovered={['1']=true,['2']=true,['3']=true}
 expect(service:Current(state,'Discoveries')==3 and service:Claim(state,'explorer'),'Three real discoveries unlock exploration objective')
 local stats=p.Progress.Stats
 service:Record(state,'ResourcesSold',25)
 expect(service:Current(state,'ResourcesSold')==25 and service:Claim(state,'busy_factory'),'Actual resources sold advance factory objective')
 expect(not service:Record(state,'Unknown',1) and not service:Record(state,'Sales',-5),'Only supported positive server counters advance objectives')
 p.Progress.Claimed.forged=true;p.Progress.Stats.forged=99
 local normalized=persistence:Normalize(p)
 expect(not normalized.Progress.Claimed.forged and not normalized.Progress.Stats.forged,'Saved progression contains only configured objectives and counters')
 return {Suite='ProgressionFeature',Success=true,Passed=passed,RealDataStoreWrites=0}
end
return QA
