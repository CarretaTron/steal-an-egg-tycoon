-- Opt-in integration regressions. All profile writes below use an in-memory Store.
local Run=game:GetService("RunService")
if not Run:IsStudio() then return end
local Test=game:GetService("StudioTestService")
local argsOK,args=pcall(function() return Test:GetTestArgs() end)
if not argsOK or args~="EggTycoonV3_Regression" then return end
local H=game:GetService("HttpService")
local report={Suite="EggTycoonV3_Regression",Passed={},Failed={},Started=os.clock(),RealDataStoreWrites=0}
local live,isolated,fixtures,originals
local ended=false
local function copy(value)
 if type(value)~="table" then return value end
 local result={};for k,v in pairs(value) do result[k]=copy(v) end;return result
end
local function expect(value,label)
 assert(value,label)
 table.insert(report.Passed,label)
 print("[EggTycoonV3 Regression] PASS: "..label)
end
local function waitFor(callback,seconds,label)
 local deadline=os.clock()+seconds
 repeat local value=callback();if value then return value end;task.wait(.1) until ended or os.clock()>deadline
 error("Timeout: "..label)
end
local function cleanup()
 if fixtures then fixtures:Destroy();fixtures=nil end
 if not originals then return end
 for _,original in ipairs(originals) do
  local state,player=original.State,original.State.Player
  -- Fixtures never replace live profiles, states, pending timers, or persistence metadata.
  -- Restoring references is defensive against a concurrent UI action during the test.
  state.Profile=original.Profile;state.Runtime=original.Runtime;state.Pending=original.Pending
  if not original.PendingAdjusted then
   local pausedFor=os.clock()-(original.PausedAt or os.clock())
   for _,pending in pairs(state.Pending or {}) do if type(pending.EndsAt)=="number" then pending.EndsAt+=pausedFor end end
   original.PendingAdjusted=true
  end
  state.Generation=original.Generation;state.OperationBusy=original.OperationBusy
  state.Ready=original.Ready;state.LastCombat=original.LastCombat;state.Energy=original.Energy
  local character=player.Character
  if character then
   for _,tool in ipairs(character:GetChildren()) do if tool:IsA("Tool") and tool:GetAttribute("RegressionFixture") then tool:Destroy() end end
   local root=character:FindFirstChild("HumanoidRootPart")
   local hum=character:FindFirstChildOfClass("Humanoid")
   if root and original.RootCF then root.CFrame=original.RootCF;root.AssemblyLinearVelocity=Vector3.zero;root.Anchored=original.Anchored end
   if hum then hum.MaxHealth=original.MaxHealth;hum.Health=math.min(original.Health,original.MaxHealth) end
   if original.Equipped and original.Equipped.Parent and hum then hum:EquipTool(original.Equipped) end
  end
  for _,forceField in ipairs(original.ForceFields or {}) do if forceField.Parent==nil and character then forceField.Parent=character end end
  if live and player.Parent then live:Sync(state) end
 end
 if live then live.Running=report.OriginalRunning end
 originals=nil
end
local function finish(failure)
 if ended then return end;ended=true
 if failure then table.insert(report.Failed,tostring(failure)) end
 local ok,err=pcall(cleanup)
 if not ok then table.insert(report.Failed,"Cleanup: "..tostring(err));if live then live.Running=report.OriginalRunning end end
 report.Duration=math.floor((os.clock()-report.Started)*100)/100
 report.Success=#report.Failed==0
 local encoded=H:JSONEncode(report)
 print("[EggTycoonV3 Regression] "..encoded)
 pcall(function() Test:EndTest(encoded) end)
end
task.delay(100,function() finish("Overall timeout (100s)") end)
game:BindToClose(function() pcall(cleanup) end)

local ok,failure=xpcall(function()
 live=waitFor(function() return _G.EggTycoonV3 end,30,"bootstrap")
 local states=waitFor(function()
  local found={};for _,state in pairs(live.States) do if state.Ready and state.Player.Character then table.insert(found,state) end end
  if #found>=2 then table.sort(found,function(a,b) return a.PlotId<b.PlotId end);return {found[1],found[2]} end
 end,25,"two ready clients")
 report.OriginalRunning=live.Running
 for _,state in ipairs(states) do expect(not state.Carry and not live:HasTransfer(state),"No transport fixture conflict for player "..state.PlotId) end
 -- Pause the live heartbeat before any fixture/avatar work; autosave cannot see test data.
 live.Running=false
 originals={}
 for _,state in ipairs(states) do
  local character=state.Player.Character
  local root=waitFor(function() return character:FindFirstChild("HumanoidRootPart") end,5,"character root")
  local hum=character:FindFirstChildOfClass("Humanoid")
  assert(hum and hum.Health>0,"Living character required")
  local original={State=state,Profile=state.Profile,Runtime=state.Runtime,Pending=state.Pending,Generation=state.Generation,
   Ready=state.Ready,OperationBusy=state.OperationBusy,LastCombat=state.LastCombat,Energy=state.Energy,
   RootCF=root.CFrame,Anchored=root.Anchored,Health=hum.Health,MaxHealth=hum.MaxHealth,ForceFields={},PausedAt=os.clock()}
  table.insert(originals,original)
  state.OperationBusy=true
  original.Equipped=character:FindFirstChildOfClass("Tool")
  hum:UnequipTools()
  for _,child in ipairs(character:GetChildren()) do if child:IsA("ForceField") then table.insert(original.ForceFields,child);child.Parent=nil end end
  root.Anchored=true
 end
 local Building=require(script.Parent.Building)
 local Production=require(script.Parent.Production)
 local Persistence=require(script.Parent.Persistence)
 local Combat=require(script.Parent.Combat)
 isolated={Config=live.Config,Art=live.Art,States={},Services={},Remotes={FX={FireAllClients=function() end}}}
 function isolated:Toast() end
 function isolated:Sync() end
 function isolated:Near(player,position,distance) return live:Near(player,position,distance) end
 isolated.Services.Building=Building.new(isolated)
 isolated.Services.Production=Production.new(isolated)
 isolated.Services.Combat=Combat.new(isolated)
 -- Constructor obtains a handle, but every subsequent IO call is redirected immediately.
 local persistence=Persistence.new(isolated)
 local memory={Records={},Writes=0,Reads=0,FailWrites=0,LoseReleaseAck=false}
 function memory:GetAsync(key) self.Reads+=1;return copy(self.Records[key]) end
 function memory:UpdateAsync(key,callback)
  self.Writes+=1
  if self.FailWrites>0 then self.FailWrites-=1;error("Injected write failure") end
  local before=copy(self.Records[key])
  local after=callback(copy(before))
  if after==nil then return nil end
  self.Records[key]=copy(after)
  if self.LoseReleaseAck and before and before.Lease and not after.Lease then
   self.LoseReleaseAck=false;error("Injected lost acknowledgement after durable lease release")
  end
  return copy(after)
 end
 persistence.Store=memory
 function persistence:Call(callback) return pcall(callback) end
 isolated.Services.Persistence=persistence
 fixtures=Instance.new("Folder");fixtures.Name="EggTycoonV3RegressionFixtures";fixtures.Parent=workspace
 local C=isolated.Config
 local function fixtureState(original)
  local plot=Instance.new("Model");plot.Name="FixturePlot_"..original.PlotId
  local anchor=Instance.new("Part");anchor.Name="FixtureAnchor";anchor.Size=Vector3.one;anchor.Transparency=1
  anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false
  anchor.CFrame=C.PlotCFrame(original.PlotId);anchor.Parent=plot;plot.PrimaryPart=anchor;plot.Parent=fixtures
  local s={Player=original.Player,Plot=plot,PlotId=original.PlotId,Profile=persistence:Default(),Pending={},Runtime={Saving=true},
   Generation=1,Energy=100,LastAttack=0,LastCombat=0,Ready=true,OperationBusy=true}
  isolated.States[s.Player.UserId]=s
  return s
 end
 local owner,other=fixtureState(states[1]),fixtureState(states[2])
 local building,production,combat=isolated.Services.Building,isolated.Services.Production,isolated.Services.Combat
 building:Render(owner)
 local habitat,incubator
 for _,build in ipairs(owner.Profile.Builds) do if build.Kind=="Habitat" then habitat=build elseif build.Kind=="Incubator" then incubator=build end end
 assert(habitat and incubator,"Starter layout must include habitat and incubator")
 local root=owner.Player.Character.HumanoidRootPart
 root.CFrame=C.PlotCFrame(owner.PlotId)*CFrame.new(35,4,-45)
 owner.Profile.Cash=100000
 local before=owner.Profile.Cash
 expect(not building:Command(owner,"UpgradeHabitat",{Id=habitat.Id}) and habitat.Level==0 and owner.Profile.Cash==before,"Busy transfer state rejects a direct building-module request")
 owner.OperationBusy=false
 expect(building:Command(owner,"UpgradeHabitat",{Id=habitat.Id}) and habitat.Level==1 and owner.Profile.Cash==before-C.HabitatPrices[1],"First habitat upgrade charges exactly one configured price")
 expect(building:Command(owner,"UpgradeHabitat",{Id=habitat.Id}) and building:Command(owner,"UpgradeHabitat",{Id=habitat.Id}) and habitat.Level==3,"Habitat reaches level three")
 before=owner.Profile.Cash
 expect(not building:Command(owner,"UpgradeHabitat",{Id=habitat.Id}) and owner.Profile.Cash==before and habitat.Level==3,"Repeated max-level request cannot debit again")
 owner.Pending[habitat.Id]={Id="reserved-egg",Species=1,IncubatorId=incubator.Id,EndsAt=os.clock()+7}
 expect(not building:Command(owner,"Store",{BuildId=habitat.Id}) and owner.Profile.Cash==before,"Incubation reservation blocks storing its habitat")
 owner.Pending={}
 local habitatId,x,z=habitat.Id,habitat.X,habitat.Z
 expect(building:Command(owner,"Store",{BuildId=habitatId}) and #owner.Profile.StoredHabitats==1,"Upgraded empty habitat can be stored")
 expect(building:Command(owner,"Place",{Kind="Habitat",X=x,Z=z,R=0}),"Stored upgraded habitat can be placed again")
 habitat=building:GetBuild(owner,habitatId)
 expect(habitat and habitat.Level==3 and #owner.Profile.StoredHabitats==0,"Store/place preserves unique habitat ID and paid level")
 local normalized=persistence:Normalize(persistence:Snapshot(owner))
 local savedLevel
 for _,build in ipairs(normalized.Builds) do if build.Id==habitatId then savedLevel=build.Level end end
 expect(savedLevel==3,"Habitat level survives profile normalization")
 owner.Profile.Rebirths=2;owner.Profile.ProcessorLevel=2
 local expected=(1+2*C.RebirthMultiplier)*C.ProcessorMultipliers[2]*C.HabitatMultipliers[4]
 expect(math.abs(production:Multiplier(owner,habitatId)-expected)<.00001,"Habitat, processor and rebirth production factors compose correctly")

 -- Pending eggs retain remaining connected time, without becoming creatures early.
 owner.Profile.Creatures={}
 owner.Pending[habitatId]={Id="regression-pending",Species=1,IncubatorId=incubator.Id,EndsAt=os.clock()+7.25}
 local endsAt=owner.Pending[habitatId].EndsAt
 local snapshot=persistence:Snapshot(owner)
 expect(#snapshot.Incubations==1 and #snapshot.Creatures==0 and owner.Pending[habitatId].EndsAt==endsAt,"Incubation snapshot preserves pending egg without mutating runtime")
 local rejoin={Player=other.Player,Profile=persistence:Normalize(snapshot),Pending={},Runtime={},Generation=7,Plot=other.Plot,PlotId=other.PlotId}
 persistence:RestoreIncubations(rejoin)
 local remaining=rejoin.Pending[habitatId].EndsAt-os.clock()
 expect(remaining>7 and remaining<=7.25 and #rejoin.Profile.Incubations==0,"Rejoin resumes remaining incubation time on another plot")
 local restoredEnd=rejoin.Pending[habitatId].EndsAt
 persistence:RestoreIncubations(rejoin)
 expect(rejoin.Pending[habitatId].EndsAt==restoredEnd,"Repeated incubation restore cannot extend timer or duplicate egg")

 -- Escrow packets whose producer is gone must pay once, including after rejoin.
 local escrowState={Player=owner.Player,Profile=persistence:Default(),Pending={},Plot=owner.Plot,PlotId=owner.PlotId,Generation=1,
  Runtime={PacketGeneration=1,ResourcePackets={{Id="unpaid-one",CreatureId="released-producer",Species=1,Value=32,Remaining=2,Lifetime=0,Path={{X=0,Z=0},{X=0,Z=-4}}}}}}
 escrowState.Profile.StarterPlaced=true
 local escrowSnapshot=persistence:Snapshot(escrowState)
 table.insert(escrowSnapshot.ResourceEscrow,copy(escrowSnapshot.ResourceEscrow[1]))
 local escrowProfile=persistence:Normalize(escrowSnapshot)
 expect(#escrowProfile.ResourceEscrow==1 and #escrowState.Runtime.ResourcePackets==1,"Escrow normalization deduplicates packet IDs without consuming live queue")
 local loaded={Player=owner.Player,Profile=escrowProfile,Pending={},Runtime={},Generation=8,Plot=other.Plot,PlotId=other.PlotId}
 production:Step(loaded,0)
 expect(#loaded.Runtime.ResourcePackets==1 and #loaded.Profile.ResourceEscrow==0 and loaded.Profile.Cash==0,"Escrow moves into runtime exactly once without early credit")
 production:Step(loaded,2);production:Step(loaded,2)
 expect(loaded.Profile.Cash==32 and #loaded.Runtime.ResourcePackets==0,"Restored orphan packet pays exactly once")
 loaded={Player=owner.Player,Profile=persistence:Normalize(persistence:Snapshot(loaded)),Pending={},Runtime={},Generation=9,Plot=owner.Plot,PlotId=owner.PlotId}
 production:Step(loaded,3)
 expect(loaded.Profile.Cash==32 and #loaded.Runtime.ResourcePackets==0,"Reload of paid escrow cannot replay payout")
 escrowState.Generation+=1;production:Step(escrowState,3)
 expect(escrowState.Profile.Cash==0 and #escrowState.Runtime.ResourcePackets==0,"Generation reset discards unpaid packets from the previous rebirth")

 local function loadMemoryPlayer(uid)
  local player={UserId=uid}
  local profile=persistence:Default();profile.StarterPlaced=true;profile.Cash=1234
  profile.Builds={{Id="memory-habitat",Kind="Habitat",X=0,Z=16,R=0,Level=2}}
  profile.Creatures={{Id="memory-creature",Species=1,HabitatId="memory-habitat",Stored=3}}
  memory.Records["P:"..uid]={Profile=copy(profile),Revision=0}
  local loadedProfile,mode=persistence:Load(player)
  assert(loadedProfile and mode=="Persistente","Memory profile load failed")
  return {Player=player,Profile=loadedProfile,Pending={},Runtime={},Generation=1}
 end
 local leaving=loadMemoryPlayer(-910001)
 memory.FailWrites=1
 expect(persistence:Release(leaving)==false and persistence.PendingReleases[-910001] and persistence.Meta[-910001],"Failed final save keeps a retryable release snapshot and lease metadata")
 leaving.Profile.Cash=999999;leaving.Profile.Creatures={}
 local denied=persistence:Load(leaving.Player)
 expect(denied==nil,"Rejoin is refused while previous failed release remains pending")
 expect(persistence:RetryPending()==true and not persistence.Meta[-910001] and not persistence.PendingReleases[-910001],"Pending final save retries and releases its lease")
 local record=memory.Records["P:-910001"]
 expect(record.Profile.Cash==1234 and #record.Profile.Creatures==1 and not record.Lease,"Release retry saves frozen original snapshot after live state is cleared")
 local writes=memory.Writes
 expect(persistence:RetryPending()==true and memory.Writes==writes,"Repeated release drain is idempotent")
 local lostAck=loadMemoryPlayer(-910002)
 memory.LoseReleaseAck=true
 expect(persistence:Release(lostAck)==false and persistence.PendingReleases[-910002].WithoutSave==true,"Lost release acknowledgement queues only lease-release retry")
 expect(persistence:RetryPending()==true and not persistence.Meta[-910002] and not persistence.PendingReleases[-910002] and not memory.Records["P:-910002"].Lease,"Lost-ack retry recognizes released lease and completes without another snapshot write")
 report.MemoryStoreWrites=memory.Writes;report.MemoryStoreReads=memory.Reads
 require(script.Parent.StudioPersistenceQA).Run(isolated,expect)
 require(script.Parent.StudioRulesQA).Run(isolated,expect)

 -- Buying protection during combat must wait for the same battery's reconstruction.
 local battery=Instance.new("Part");battery.Name="Battery";battery.Anchored=true; battery.CanQuery=false
 battery.Position=C.PlotCFrame(owner.PlotId).Position+Vector3.new(0,3,-86);battery.Parent=owner.Plot
 owner.Profile.BatteryLevel=1;owner.Profile.Cash=C.BatteryPrices[1]
 combat:Reset(owner);combat:Reset(other)
 combat:DamageBattery(other,owner,20)
 combat:Upgrade(owner,"Battery")
 expect(owner.Profile.BatteryLevel==2 and owner.Profile.Cash==0 and owner.Runtime.ActiveBatteryLevel==1 and owner.Runtime.BatteryHP==180 and owner.Runtime.BatteryUpgradeDeferred==true,"Battery upgrade purchased during attack debits but leaves current defence unchanged")
 owner.LastCombat=os.clock()-C.CombatLock-1
 combat:Step(0)
 expect(owner.Runtime.ActiveBatteryLevel==1 and owner.Runtime.BatteryHP==180 and owner.Runtime.BatteryUpgradeDeferred==true,"Combat timeout does not apply deferred battery protection early")
 combat:DamageBattery(other,owner,180)
 expect(owner.Runtime.BatteryHP==0 and owner.Runtime.BreachUntil>os.clock(),"Battery remains breachable at its original resistance")
 owner.Runtime.BreachUntil=os.clock()-.1
 combat:Step(0)
 expect(owner.Runtime.ActiveBatteryLevel==2 and owner.Runtime.BatteryHP==C.BatteryHP[2] and owner.Runtime.BatteryUpgradeDeferred==false,"Reconstruction applies deferred battery level exactly once")

 -- Real character raycasts use isolated state/config and an empty elevated arena.
 local ar,vr=owner.Player.Character.HumanoidRootPart,other.Player.Character.HumanoidRootPart
 local ah,vh=owner.Player.Character:FindFirstChildOfClass("Humanoid"),other.Player.Character:FindFirstChildOfClass("Humanoid")
 ah.MaxHealth=100;ah.Health=100;vh.MaxHealth=100;vh.Health=100
 local tool=Instance.new("Tool");tool.Name="RegressionBlaster";tool.RequiresHandle=false
 tool:SetAttribute("WeaponKind","Blaster");tool:SetAttribute("RegressionFixture",true);tool.Parent=owner.Player.Character
 owner.Profile.WeaponLevel=1;other.Runtime.SpawnProtectedUntil=0
 local function fire(target)
  owner.LastAttack=os.clock()-2;owner.Energy=100
  combat:Attack(owner,{Weapon="Blaster",Target=target})
 end
 ar.CFrame=CFrame.new(124,200,0);vr.CFrame=CFrame.new(110,200,0)
 fire(vr.Position+Vector3.new(0,1.2,0))
 expect(vh.Health==100,"Projectile fired from outside cannot hurt a player inside safe plaza")
 ar.CFrame=CFrame.new(3000,200,0);vr.CFrame=CFrame.new(3020,200,0)
 local wall=Instance.new("Part");wall.Name="RegressionObstacle";wall.Anchored=true;wall.Size=Vector3.new(2,14,16);wall.CFrame=CFrame.new(3010,201,0);wall.Parent=fixtures
 fire(vr.Position+Vector3.new(0,1.2,0))
 expect(vh.Health==100,"Server raycast obstacle blocks damage")
 wall:Destroy()
 fire(vr.Position+Vector3.new(0,1.2,0))
 expect(vh.Health==80,"Unobstructed PvP blaster applies configured twenty damage")
 combat:Attack(owner,{Weapon="Blaster",Target=vr.Position+Vector3.new(0,1.2,0)})
 expect(vh.Health==80 and owner.Energy==88,"Immediate repeated shot is rejected by cadence without extra energy charge")
 local npc=Instance.new("Model");npc.Name="RegressionCreature";npc.Parent=fixtures
 local body=Instance.new("Part");body.Name="HumanoidRootPart";body.Size=Vector3.new(4,5,4);body.CFrame=CFrame.new(3010,201,0);body.Anchored=true;body.Parent=npc
 local npcHum=Instance.new("Humanoid");npcHum.Parent=npc
 fire(body.Position)
 expect(npcHum.Health==npcHum.MaxHealth and vh.Health==80,"Weapon never damages or passes through a nonplayer creature")
 local rangeBefore=vh.Health
 npc:Destroy();vr.CFrame=CFrame.new(3150,200,0)
 fire(vr.Position+Vector3.new(0,1.2,0))
 expect(vh.Health==rangeBefore,"Blaster cannot exceed its configured one-hundred-stud range")
 report.IsolatedTwoClientFixtures=true
end,debug.traceback)
finish(not ok and failure or nil)
