-- Runs only under the explicitly requested Studio multiplayer test.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local StudioTestService=game:GetService("StudioTestService")
local ok,args=pcall(function() return StudioTestService:GetTestArgs() end)
if not ok or args~="EggTycoonV3_QA" then return end
local HttpService=game:GetService("HttpService")
local report={Suite="EggTycoonV3",Passed={},Failed={},Started=os.clock()}
local ended=false
local ctx,originals,probeConnection
local clientReports={}
local function copy(value)
 if type(value)~="table" then return value end
 local out={};for k,v in pairs(value) do out[k]=copy(v) end;return out
end
local function expect(condition,label)
 if not condition then error(label,2) end
 table.insert(report.Passed,label)
 print("[EggTycoonV3 QA] PASS: "..label)
end
local function waitFor(callback,seconds,label)
 local deadline=os.clock()+seconds
 repeat local result=callback();if result then return result end;task.wait(.1) until os.clock()>deadline or ended
 error("Timeout: "..label,2)
end
local function finish()
 if ended then return end;ended=true
 report.Duration=math.floor((os.clock()-report.Started)*100)/100
 report.Success=#report.Failed==0
 local encoded=HttpService:JSONEncode(report)
 print("[EggTycoonV3 QA] "..encoded)
 local success,err=pcall(function() StudioTestService:EndTest(encoded) end)
 if not success then warn("[EggTycoonV3 QA] EndTest:",err) end
end
local function cleanup()
 workspace:SetAttribute("V3QAActive",false)
 if probeConnection then probeConnection:Disconnect();probeConnection=nil end
 if not ctx or not originals then return end
 for _,s in pairs(ctx.States) do pcall(function() ctx:RestoreCarry(s) end) end
 for userId,original in pairs(originals) do
  local s=ctx.States[userId]
  if s then
   s.Profile=original.Profile;s.Pending=original.Pending;s.Generation+=1;s.LastCombat=0
   local f=s.Plot:FindFirstChild("Incubations");if f then f:ClearAllChildren() end
   ctx.Services.Building:Render(s);ctx.Services.Production:RenderCreatures(s);ctx.Services.Combat:Reset(s)
   ctx:GrantTools(s);ctx:ApplySpeed(s);ctx:Sync(s)
   pcall(function() ctx.Services.Persistence:Save(s) end)
  end
 end
end
task.delay(175,function()
 if ended then return end
 table.insert(report.Failed,"Overall timeout (175 seconds)")
 pcall(cleanup);finish()
end)

local success,failure=xpcall(function()
 ctx=waitFor(function() return _G.EggTycoonV3 end,30,"bootstrap")
 probeConnection=ctx.Remotes.Command.OnServerEvent:Connect(function(player,action,payload)
  if action~="QAClientProbe" or not workspace:GetAttribute("V3QAActive") or type(payload)~="table" then return end
  if type(payload.EggParts)~="number" or type(payload.GuardParts)~="number" or type(payload.MeshParts)~="number" then return end
  if payload.EggParts<0 or payload.EggParts>10000 or payload.GuardParts<0 or payload.GuardParts>10000 or payload.MeshParts<0 or payload.MeshParts>10000 then return end
  clientReports[player.UserId]={EggParts=payload.EggParts,GuardParts=payload.GuardParts,MeshParts=payload.MeshParts,StreamRequest=payload.StreamRequest==true,Issue=type(payload.Issue)=="string" and string.sub(payload.Issue,1,300) or nil}
 end)
 workspace:SetAttribute("V3QAActive",true)
 local states=waitFor(function()
  local list={};for _,s in pairs(ctx.States) do if s.Ready then table.insert(list,s) end end
  if #list>=2 then table.sort(list,function(a,b) return a.PlotId<b.PlotId end);return list end
 end,30,"two connected clients")
 local owner,thief=states[1],states[2]
 waitFor(function() return clientReports[owner.Player.UserId] and clientReports[thief.Player.UserId] end,25,"two client geometry probes")
 for _,s in ipairs({owner,thief}) do
  local probe=clientReports[s.Player.UserId]
  expect(probe.EggParts>0 and probe.GuardParts>0 and probe.MeshParts>0,"Blender egg and guardian geometry replicated to client "..s.PlotId)
 end
 report.ClientGeometry={clientReports[owner.Player.UserId],clientReports[thief.Player.UserId]}
 local C=ctx.Config
 local function root(s)
  local char=s.Player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
  return char and hum and hum.Health>0 and char:FindFirstChild("HumanoidRootPart")
 end
 local function warp(s,cf,transportFixture)
  local r=waitFor(function() return root(s) end,12,"living character")
  r.CFrame=cf;r.AssemblyLinearVelocity=Vector3.zero
  if transportFixture then s.Runtime.LastAllowedCF=cf end
 end
 local function equip(s,kind)
  ctx:GrantTools(s)
  for _,tool in ipairs(s.Player.Backpack:GetChildren()) do
   if tool:GetAttribute("WeaponKind")==kind then s.Player.Character.Humanoid:EquipTool(tool);return end
  end
  error("Tool not found: "..kind)
 end
 local function promptFor(s)
  local folder=s.Plot:FindFirstChild("Creatures")
  return folder and folder:FindFirstChildWhichIsA("ProximityPrompt",true)
 end
 local function approachCreature()
  local cr=owner.Profile.Creatures[1];assert(cr,"source creature")
  local build=ctx.Services.Building:GetBuild(owner,cr.HabitatId)
  owner.Runtime.BreachUntil=os.clock()+30 -- fixture: maintain an already validated breach during IO tests.
  warp(thief,C.ItemCFrame(owner.Plot:GetPivot(),build)*CFrame.new(0,4,0))
  task.wait(.2)
  return assert(promptFor(owner),"creature prompt")
 end
 local function stealWithHold()
  local p=approachCreature()
  ctx.QA.BeginHold(p,thief.Player);task.wait(2.1);ctx.QA.TriggerPrompt(p,thief.Player)
  return waitFor(function() return thief.Carry and thief.Carry.Kind=="Creature" and not thief.OperationBusy end,20,"begin transfer")
 end
 originals={}
 for _,s in ipairs({owner,thief}) do
  expect(not ctx:HasTransfer(s),"No transfer active before QA for player "..s.PlotId)
  originals[s.Player.UserId]={Profile=copy(s.Profile),Pending=copy(s.Pending)}
  s.Profile=ctx.Services.Persistence:Default();s.Pending={};s.Generation+=1;s.LastCombat=0
  ctx.Services.Building:Render(s);ctx.Services.Production:RenderCreatures(s);ctx.Services.Combat:Reset(s)
  ctx:GrantTools(s);ctx:ApplySpeed(s)
 end
 expect(#ctx.World.Nests:GetChildren()==14,"Fourteen nests across seven biomes")
 expect(#ctx.World.Guardians:GetChildren()==14,"Fourteen distinct guardian placements")
 expect(C.IsSafe(Vector3.zero) and C.IsSafe(Vector3.new(0,0,1000)) and not C.IsSafe(owner.Plot:GetPivot().Position),"Safe plaza and corridor; PvP plots")
 expect(owner.Profile.Cash==0,"First cycle begins with zero cash")

 local nest=assert(ctx.Nests.B1_1,"first nest")
 local egg=nest.Model:FindFirstChild("Egg")
 local eggPrompt=egg:FindFirstChildWhichIsA("ProximityPrompt",true)
 warp(owner,CFrame.new(egg.PrimaryPart.Position+Vector3.new(0,3,5)))
 ctx.QA.BeginHold(eggPrompt,owner.Player);task.wait(.7);ctx.QA.TriggerPrompt(eggPrompt,owner.Player)
 expect(owner.Carry and owner.Carry.Kind=="Egg","Server-validated egg pickup")
 expect(math.abs(owner.Player.Character.Humanoid.WalkSpeed-C.WalkSpeed*.9)<.01,"Carrying slows movement by ten percent")
 local incubator
 for _,b in ipairs(owner.Profile.Builds) do if b.Kind=="Incubator" then incubator=b;break end end
 warp(owner,C.ItemCFrame(owner.Plot:GetPivot(),incubator)*CFrame.new(0,4,0))
 ctx.QA.Deliver(owner,incubator.Id)
 expect(not owner.Carry and next(owner.Pending)~=nil,"Incubator reserves habitat before accepting egg")
 waitFor(function() return #owner.Profile.Creatures==1 end,15,"natural ten-second hatch")
 expect(owner.Profile.Creatures[1].Species==1,"Natural hatch creates the original creature")
 waitFor(function() return owner.Profile.Cash>0 end,15,"connected production and seller payout")
 report.FirstNaturalSaleCash=owner.Profile.Cash
 expect(owner.Profile.Cash>0 and owner.Profile.Cash<500,"First sale earned through production without a cash fixture")

 -- A weapon raycast can hit an NPC object, but cannot damage its humanoid.
 local dummy=Instance.new("Model");dummy.Name="QA_NPC"
 local part=Instance.new("Part");part.Size=Vector3.new(3,3,3);part.Anchored=true;part.Name="HumanoidRootPart";part.Parent=dummy
 local npcHum=Instance.new("Humanoid");npcHum.Parent=dummy;dummy.PrimaryPart=part;dummy.Parent=workspace
 local outside=owner.Plot:GetPivot()*CFrame.new(-35,4,-95)
 warp(owner,outside);part.CFrame=outside*CFrame.new(0,1.2,-5)
 equip(owner,"Baton");ctx.Services.Combat:Attack(owner,{Weapon="Baton",Target=part.Position})
 expect(npcHum.Health==npcHum.MaxHealth,"Weapons never damage an NPC humanoid")
 dummy:Destroy()
 warp(owner,CFrame.new(0,4,0));warp(thief,CFrame.new(0,4,-5));equip(owner,"Baton")
 local before=thief.Player.Character.Humanoid.Health
 task.wait(.75);ctx.Services.Combat:Attack(owner,{Weapon="Baton",Target=root(thief).Position})
 expect(thief.Player.Character.Humanoid.Health==before,"Weapons cannot damage players in the safe plaza")

 -- Validate closed entry independently of the later open-battery theft.
 warp(thief,owner.Plot:GetPivot()*CFrame.new(0,4,-87));task.wait(.2)
 warp(thief,owner.Plot:GetPivot()*CFrame.new(0,4,-74));task.wait(.3)
 expect(owner.Plot:GetPivot():PointToObjectSpace(root(thief).Position).Z<-80,"Active laser rejects inward crossing")
 local battery=owner.Plot.Battery
 warp(thief,CFrame.lookAt(battery.Position+owner.Plot:GetPivot().LookVector*5,battery.Position))
 equip(thief,"Baton")
 for _=1,11 do
  ctx.Services.Combat:Attack(thief,{Weapon="Baton",Target=battery.Position})
  task.wait(.73)
  if owner.Runtime.BatteryHP<=0 then break end
 end
 expect(owner.Runtime.BatteryHP==0 and owner.Runtime.BreachUntil>os.clock(),"Repeated validated weapon hits open battery for thirty seconds")
 local p=approachCreature()
 ctx.QA.BeginHold(p,thief.Player);ctx.QA.TriggerPrompt(p,thief.Player)
 expect(thief.Carry==nil,"Instant forged creature interaction is rejected")
 task.wait(2.1);ctx.QA.TriggerPrompt(p,thief.Player)
 waitFor(function() return thief.Carry and not thief.OperationBusy end,20,"held theft")
 expect(#owner.Profile.Creatures==1 and #thief.Profile.Creatures==0,"Ownership remains with victim while carrying")
 local previous=root(thief).CFrame
 warp(thief,CFrame.new(0,4,0));task.wait(.3)
 expect((root(thief).Position-previous.Position).Magnitude<25,"A stolen creature cannot enter a safe zone")
 ctx:RestoreCarry(thief)
 expect(not thief.Carry and #owner.Profile.Creatures==1,"Dropping transport durably returns creature")
 stealWithHold()
 thief.Player.Character.Humanoid.Health=0
 waitFor(function() return not thief.Carry end,20,"death recovery")
 expect(#owner.Profile.Creatures==1 and #thief.Profile.Creatures==0,"Death does not duplicate or delete the stolen creature")
 waitFor(function() return root(thief) end,12,"respawn")
 stealWithHold()
 thief.Profile.Cash=C.RebirthCost
 local rb=thief.Profile.Rebirths
 ctx.QA.Rebirth(thief)
 expect(thief.Profile.Rebirths==rb,"Rebirth is blocked while involved in a transfer")
 warp(thief,thief.Plot:GetPivot()*CFrame.new(0,4,-65),true)
 ctx.QA.Deliver(thief)
 expect(not thief.Carry and #owner.Profile.Creatures==0 and #thief.Profile.Creatures==1,"Confirmed delivery transfers creature exactly once")
 thief.LastCombat=0
 ctx.QA.Rebirth(thief)
 expect(thief.Profile.Rebirths==rb+1 and thief.Profile.Cash==0 and #thief.Profile.Creatures==0,"Rebirth resets purchases and creatures once")
 expect(#thief.Profile.Builds>0 and thief.Profile.Rebirths*C.RebirthMultiplier==.25,"Rebirth restores free starter chain and permanent multiplier")
 if thief.SaveMode=="Persistente" then
  local expectedRebirths=thief.Profile.Rebirths
  local expectedBuilds=copy(thief.Profile.Builds)
  expect(ctx.Services.Persistence:Save(thief)==true,"Rebirth profile saves under a held lease")
  expect(ctx.Services.Persistence:Release(thief)==true,"Persistent profile releases its lease")
  local reloaded,reloadMode=ctx.Services.Persistence:Load(thief.Player)
  expect(reloaded~=nil and reloadMode=="Persistente","Released profile can be loaded again")
  thief.Profile=assert(reloaded)
  expect(thief.Profile.Rebirths==expectedRebirths and thief.Profile.Cash==0 and #thief.Profile.Creatures==0,"Reload after rebirth does not resurrect transferred creatures")
  expect(#thief.Profile.Builds==#expectedBuilds and thief.Profile.Builds[1].X==expectedBuilds[1].X and thief.Profile.Builds[1].Z==expectedBuilds[1].Z,"Saved layout reloads in relative plot coordinates")
 else
  report.PersistentReloadSkipped="Studio APIs disabled: session mode has no durable storage"
 end
 report.SaveModes={owner.SaveMode,thief.SaveMode}
end,debug.traceback)
if not success then table.insert(report.Failed,tostring(failure));warn("[EggTycoonV3 QA] "..tostring(failure)) end
local cleaned,cleanupError=pcall(cleanup)
if not cleaned then table.insert(report.Failed,"Cleanup: "..tostring(cleanupError)) end
finish()
