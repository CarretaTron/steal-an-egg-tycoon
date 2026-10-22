-- Opt-in physical traversal. Only the first egg approach uses a position fixture.
-- Profiles and transfer journals used below are session-only and never reach a DataStore.
local Run=game:GetService("RunService")
if not Run:IsStudio() then return end
local Test=game:GetService("StudioTestService")
local argsOK,args=pcall(function() return Test:GetTestArgs() end)
if not argsOK or args~="EggTycoonV3_Traversal" then return end
local H=game:GetService("HttpService")
local started=os.clock()
local report={Suite="EggTycoonV3_Traversal",Passed={},Failed={},RealDataStoreWritesDuringFixture=0,
 InitialPositionFixtures=0,OwnerWalkedStuds=0,ThiefWalkedStuds=0,OwnerPursuitStuds=0,BatteryHits=0}
local ctx,originals,originalPersistence,fixturePersistence,monitor
local ended,cleaning,pursuitActive=false,false,false
local owner,thief,seenChasing,returnedHome,carryStarted=false,false,false,false,false
local lastPositions={}

local function expect(condition,label)
 assert(condition,label)
 table.insert(report.Passed,label)
 print("[EggTycoonV3 Traversal] PASS: "..label)
end
local function rootOf(state)
 local character=state and state.Player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health<=0 then return nil,humanoid end
 return character:FindFirstChild("HumanoidRootPart"),humanoid
end
local function waitFor(callback,seconds,label)
 local deadline=math.min(os.clock()+seconds,started+190)
 repeat
  if ended then error("Traversal already ended") end
  local value=callback()
  if value then return value end
  task.wait(.1)
 until os.clock()>deadline
 error("Timeout: "..label)
end
local function cleanup()
 if cleaning then return end;cleaning=true;pursuitActive=false
 if monitor then monitor:Disconnect();monitor=nil end
 if not ctx or not originals then return end
 local running=ctx.Running;ctx.Running=false
 -- Finish only session journals before putting real profile references back.
 for _,entry in ipairs(originals) do
  local state=entry.State
  pcall(function() ctx:RestoreCarry(state) end)
 end
 ctx.Services.Persistence=originalPersistence
 for _,entry in ipairs(originals) do
  local state=entry.State
  if ctx.States[state.Player.UserId]==state then
   state.Profile=entry.Profile;state.Pending=entry.Pending;state.Runtime=entry.Runtime
   state.Generation=entry.Generation;state.OperationBusy=entry.OperationBusy;state.Ready=entry.Ready
   state.LastCombat=entry.LastCombat;state.LastAttack=entry.LastAttack;state.Energy=entry.Energy;state.Carry=nil
   state.SaveMode=entry.SaveMode
   local incubations=state.Plot:FindFirstChild("Incubations")
   if incubations then incubations:ClearAllChildren() end
   ctx.Services.Building:Render(state);ctx.Services.Production:RenderCreatures(state)
   ctx:GrantTools(state);ctx:ApplySpeed(state)
   local root,humanoid=rootOf(state)
   if root then
    root.CFrame=entry.RootCF;root.AssemblyLinearVelocity=Vector3.zero
    pcall(function() root:SetNetworkOwnershipAuto() end)
   end
   if humanoid then
    humanoid:MoveTo(root and root.Position or entry.RootCF.Position)
    humanoid.MaxHealth=entry.MaxHealth;humanoid.Health=math.min(entry.Health,entry.MaxHealth)
   end
   for _,forceField in ipairs(entry.ForceFields) do
    if not forceField.Parent and state.Player.Character then forceField.Parent=state.Player.Character end
   end
   ctx:Sync(state)
  end
 end
 ctx.Running=running
 report.OriginalProfilesRestored=true
 originals=nil
end
local function finish(failure)
 if ended then return end;ended=true
 if failure then table.insert(report.Failed,tostring(failure)) end
 local ok,err=pcall(cleanup)
 if not ok then
  table.insert(report.Failed,"Cleanup: "..tostring(err))
  if ctx and originalPersistence then ctx.Services.Persistence=originalPersistence end
 end
 report.Duration=math.floor((os.clock()-started)*100)/100
 report.Success=#report.Failed==0
 local encoded=H:JSONEncode(report)
 print("[EggTycoonV3 Traversal] "..encoded)
 pcall(function() Test:EndTest(encoded) end)
end
task.delay(195,function() finish("Overall timeout (195s)") end)
game:BindToClose(function() pcall(cleanup) end)

local good,failure=xpcall(function()
 ctx=waitFor(function() return _G.EggTycoonV3 end,30,"bootstrap")
 local states=waitFor(function()
  local list={}
  for _,state in pairs(ctx.States) do
   if state.Ready and rootOf(state) then table.insert(list,state) end
  end
  if #list>=2 then
   table.sort(list,function(a,b) return a.PlotId<b.PlotId end)
   return {list[1],list[2]}
  end
 end,25,"two ready clients")
 owner,thief=states[1],states[2]
 for _,state in ipairs(states) do
  expect(not state.Carry and not ctx:HasTransfer(state) and next(state.Pending)==nil,
   "No existing transport or incubation for player "..state.PlotId)
 end
 originalPersistence=ctx.Services.Persistence
 -- Drain any real autosave that started before the fixture. Never swap its source mid-write.
 waitFor(function()
  for _,state in ipairs(states) do
   local meta=originalPersistence.Meta[state.Player.UserId]
   if state.Runtime.Saving or (meta and meta.Saving) then return false end
  end
  return true
 end,12,"existing real saves finish")
 fixturePersistence=require(script.Parent.Persistence).new(ctx)
 function fixturePersistence:Save() return true end
 originals={}
 ctx.Services.Persistence=fixturePersistence
 for _,state in ipairs(states) do
  local root,humanoid=rootOf(state)
  table.insert(originals,{State=state,Profile=state.Profile,Pending=state.Pending,Runtime=state.Runtime,
   Generation=state.Generation,OperationBusy=state.OperationBusy,Ready=state.Ready,LastCombat=state.LastCombat,
   LastAttack=state.LastAttack,Energy=state.Energy,RootCF=root.CFrame,Health=humanoid.Health,
   MaxHealth=humanoid.MaxHealth,SaveMode=state.SaveMode,ForceFields={}})
  local entry=originals[#originals]
  for _,child in ipairs(state.Player.Character:GetChildren()) do
   if child:IsA("ForceField") then table.insert(entry.ForceFields,child);child.Parent=nil end
  end
  fixturePersistence.Meta[state.Player.UserId]={Session=true}
  state.Profile=fixturePersistence:Default();state.Pending={};state.Runtime={Saving=true}
  state.Generation+=1;state.OperationBusy=false;state.LastCombat=0;state.LastAttack=0;state.Carry=nil
  state.SaveMode="Ensaio de percurso • sem gravação"
  ctx.Services.Combat:Reset(state);ctx.Services.Building:Render(state)
  ctx.Services.Production:RenderCreatures(state);ctx:GrantTools(state);ctx:ApplySpeed(state);ctx:Sync(state)
  pcall(function() root:SetNetworkOwner(nil) end)
 end
 local C=ctx.Config
 local function horizontal(a,b) return Vector3.new(a.X-b.X,0,a.Z-b.Z).Magnitude end
 local function point(state,x,z)
  return state.Plot:GetPivot():PointToWorldSpace(Vector3.new(x,3,z))
 end
 local function walk(state,destination,label,tolerance)
  local root,humanoid=rootOf(state);assert(root,"Living walker required: "..label)
  local distance=horizontal(root.Position,destination)
  local deadline=math.min(os.clock()+distance/math.max(1,humanoid.WalkSpeed)*1.9+6,started+190)
  local lastCommand=-math.huge
  while horizontal(root.Position,destination)>(tolerance or 2.5) do
   assert(not ended,"Traversal ended during "..label)
   root,humanoid=rootOf(state);assert(root,"Walker died during "..label)
   assert(os.clock()<deadline,"MoveTo stalled: "..label.." ("..math.floor(horizontal(root.Position,destination)).." studs remain)")
   if os.clock()-lastCommand>=2 then humanoid:MoveTo(destination);lastCommand=os.clock() end
   task.wait(.1)
  end
  humanoid:MoveTo(root.Position)
 end
 local function ringPoint(plotId,radius)
  local p=C.PlotCFrame(plotId).Position
  return Vector3.new(p.X,0,p.Z).Unit*(radius or 330)+Vector3.new(0,3,0)
 end
 local function ringWalk(state,fromId,toId)
  local from=C.PlotCFrame(fromId).Position;local to=C.PlotCFrame(toId).Position
  local a,b=math.atan2(from.X,from.Z),math.atan2(to.X,to.Z)
  local delta=(b-a+math.pi)%(2*math.pi)-math.pi
  local steps=math.max(1,math.ceil(math.abs(delta)/math.rad(15)))
  for i=1,steps do
   local angle=a+delta*i/steps
   walk(state,Vector3.new(math.sin(angle)*330,3,math.cos(angle)*330),"outer ring segment "..i)
  end
 end
 local nest=assert(ctx.Nests.B1_1,"Field nest missing")
 local egg=assert(nest.Model:FindFirstChild("Egg"),"Field egg missing")
 local eggPrompt=assert(egg:FindFirstChildWhichIsA("ProximityPrompt",true),"Field prompt missing")
 local ownerRoot,ownerHum=rootOf(owner)
 -- This is the single approach fixture. All movement after pickup uses Humanoid:MoveTo.
 ownerRoot.CFrame=CFrame.new(egg.PrimaryPart.Position+Vector3.new(0,3,5))
 ownerRoot.AssemblyLinearVelocity=Vector3.zero
 report.InitialPositionFixtures=1
 task.wait(.25)
 local guard=assert(ctx.Guards.B1_1,"Field guardian missing")
 monitor=Run.Heartbeat:Connect(function()
  if guard.Model.Parent then
   if guard.Model:GetAttribute("Chasing") then seenChasing=true end
   if seenChasing and not guard.Model:GetAttribute("Chasing") and (guard.Model:GetPivot().Position-guard.Home.Position).Magnitude<4 then returnedHome=true end
  end
  for _,state in ipairs({owner,thief}) do
   local root=rootOf(state)
   if root then
    local prior=lastPositions[state.Player.UserId]
    if prior then
     local distance=horizontal(root.Position,prior)
     if distance<25 then
      if state==owner then report.OwnerWalkedStuds+=distance else report.ThiefWalkedStuds+=distance end
      if state==owner and pursuitActive then report.OwnerPursuitStuds+=distance end
     elseif carryStarted then report.UnexpectedPositionJump=true end
    end
    lastPositions[state.Player.UserId]=root.Position
   end
  end
 end)
 expect(owner.Profile.Cash==0,"First natural cycle starts with zero cash")
 ctx.QA.BeginHold(eggPrompt,owner.Player);task.wait(.7);ctx.QA.TriggerPrompt(eggPrompt,owner.Player)
 expect(owner.Carry and owner.Carry.Kind=="Egg","Held egg pickup begins real return route")
 carryStarted=true
 walk(owner,Vector3.new(0,3,610),"escape field guardian")
 walk(owner,Vector3.new(0,3,340),"expedition approach")
 walk(owner,ringPoint(owner.PlotId),"own base approach on ring")
 walk(owner,point(owner,0,-89),"own outside entrance")
 walk(owner,point(owner,0,-62),"owner crosses active laser")
 local incubator
 for _,build in ipairs(owner.Profile.Builds) do if build.Kind=="Incubator" then incubator=build;break end end
 assert(incubator,"Starter incubator missing")
 local ix,iz=incubator.X,incubator.Z-10
 walk(owner,point(owner,ix,iz),"incubator approach")
 local incubatorModel=owner.Plot.Structures:FindFirstChild("Incubator_"..incubator.Id)
 local incubatorPrompt=incubatorModel and incubatorModel:FindFirstChildWhichIsA("ProximityPrompt",true)
 assert(incubatorPrompt,"Incubator prompt missing")
 ctx.QA.BeginHold(incubatorPrompt,owner.Player);task.wait(.4);ctx.QA.TriggerPrompt(incubatorPrompt,owner.Player)
 expect(not owner.Carry and next(owner.Pending)~=nil,"Walked egg reaches incubator and reserves habitat")
 waitFor(function() return #owner.Profile.Creatures==1 end,15,"natural field hatch")
 waitFor(function() return owner.Profile.Cash>0 end,15,"first natural seller payout")
 report.FirstNaturalSaleCash=owner.Profile.Cash
 expect(report.FirstNaturalSaleCash==32,"First natural sale is exactly $32 with no cash fixture")
 expect(seenChasing and returnedHome,"Guardian visibly chases and physically returns home after leash")
 expect(report.OwnerWalkedStuds>450 and not report.UnexpectedPositionJump,"Egg escape traverses over 450 studs without position jumps")

 -- The other real player travels from their own base to the victim's battery.
 walk(thief,point(thief,0,-89),"thief exits own base")
 walk(thief,ringPoint(thief.PlotId),"thief joins outer ring")
 ringWalk(thief,thief.PlotId,owner.PlotId)
 walk(thief,point(owner,24,-92),"external battery approach")
 local battery=owner.Plot:FindFirstChild("Battery");assert(battery,"Battery missing")
 local thiefRoot,thiefHum=rootOf(thief)
 local baton
 for _,tool in ipairs(thief.Player.Backpack:GetChildren()) do
  if tool:GetAttribute("WeaponKind")=="Baton" then baton=tool;break end
 end
 assert(baton,"Free baton missing");thiefHum:EquipTool(baton)
 for _=1,12 do
  if owner.Runtime.BatteryHP<=0 then break end
  ctx.Services.Combat:Attack(thief,{Weapon="Baton",Target=battery.Position})
  report.BatteryHits+=1;task.wait(.74)
 end
 expect(owner.Runtime.BatteryHP==0 and owner.Runtime.BreachUntil>os.clock(),"Actual timed baton raycasts destroy external battery")
 walk(thief,point(owner,0,-89),"breached entry alignment")
 walk(thief,point(owner,0,-62),"thief crosses breached laser")
 local creature=owner.Profile.Creatures[1]
 local habitat=ctx.Services.Building:GetBuild(owner,creature.HabitatId)
 assert(habitat,"Producing creature habitat missing")
 walk(thief,point(owner,habitat.X,habitat.Z-14),"producing creature approach")
 local creatureModel=owner.Plot.Creatures:FindFirstChild("Creature_"..creature.Id)
 local creaturePrompt=creatureModel and creatureModel:FindFirstChildWhichIsA("ProximityPrompt",true)
 assert(creaturePrompt,"Producing creature prompt missing")
 ctx.QA.BeginHold(creaturePrompt,thief.Player);task.wait(2.1);ctx.QA.TriggerPrompt(creaturePrompt,thief.Player)
 waitFor(function() return thief.Carry and thief.Carry.Kind=="Creature" and not thief.OperationBusy end,8,"held theft starts")
 expect(#owner.Profile.Creatures==1 and #thief.Profile.Creatures==0,"Victim retains ownership throughout carrying")
 local stolenId=creature.Id
 pursuitActive=true
 task.spawn(function()
  while pursuitActive and not ended do
   local chasingRoot,chasingHum=rootOf(owner);local targetRoot=rootOf(thief)
   if not chasingRoot or not targetRoot then break end
   if horizontal(chasingRoot.Position,targetRoot.Position)>15 then chasingHum:MoveTo(targetRoot.Position)
   else chasingHum:MoveTo(chasingRoot.Position) end
   task.wait(.4)
  end
 end)
 walk(thief,point(owner,0,-62),"stolen creature reaches victim entry")
 walk(thief,point(owner,0,-89),"stolen creature exits victim base")
 walk(thief,ringPoint(owner.PlotId),"stolen creature joins legal outer route")
 ringWalk(thief,owner.PlotId,thief.PlotId)
 walk(thief,point(thief,0,-89),"stolen creature reaches own entrance")
 pursuitActive=false
 local chasingRoot,chasingHum=rootOf(owner)
 if chasingRoot then chasingHum:MoveTo(chasingRoot.Position) end
 walk(thief,point(thief,0,-65),"stolen creature enters destination base")
 expect(thief.Carry and not C.IsSafe(rootOf(thief).Position) and not report.UnexpectedPositionJump,"Stolen creature completes physical route outside protected zones")
 local delivery=thief.Plot:FindFirstChild("DeliveryPad")
 local deliveryPrompt=delivery and delivery:FindFirstChildWhichIsA("ProximityPrompt",true)
 assert(deliveryPrompt,"Destination delivery prompt missing")
 ctx.QA.BeginHold(deliveryPrompt,thief.Player);task.wait(.4);ctx.QA.TriggerPrompt(deliveryPrompt,thief.Player)
 waitFor(function() return not thief.Carry end,8,"physical stolen creature delivery")
 expect(#owner.Profile.Creatures==0 and #thief.Profile.Creatures==1 and thief.Profile.Creatures[1].Id==stolenId,
  "Physical invasion and delivery transfer original creature once")
 expect(report.OwnerPursuitStuds>30,"Victim physically pursues the carrier for over thirty studs")
 report.OwnerWalkedStuds=math.floor(report.OwnerWalkedStuds)
 report.ThiefWalkedStuds=math.floor(report.ThiefWalkedStuds)
 report.OwnerPursuitStuds=math.floor(report.OwnerPursuitStuds)
end,debug.traceback)
finish(good and nil or failure)
