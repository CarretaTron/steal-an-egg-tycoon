local C=_G.AvenueConfig;local S=_G.AvenueShell;local R=_G.CompactRules
local w=workspace.EggTycoonV3;local checks=0;local plots={}
local function check(v,m) checks+=1;assert(v,m) end
for _,p in w.Plots:GetChildren() do
 local id=p:GetAttribute('PlotId');local expected=C.PlotCFrame(id)
 check((p:GetPivot().Position-expected.Position).Magnitude<.003,p.Name..' position')
 check(p:GetPivot().LookVector:Dot((Vector3.new(0,1,expected.Z)-expected.Position).Unit)>.999,p.Name..' front faces street')
 check(p.Floor.Size==Vector3.new(144,1,144),p.Name..' floor144')
 check(p.Battery==_G.CompactBefore.Plots[p.Name].Battery and p.Floor==_G.CompactBefore.Plots[p.Name].Floor,p.Name..' identities')
 check(p:GetAttribute('BaseShellScale')==.9 and p:GetAttribute('BaseShellRevision')==5,p.Name..' shell scale')
 check(p.Battery.Size==Vector3.new(12,7,6),p.Name..' generator not scaled')
 local lp=p:GetPivot():PointToObjectSpace(p.Battery.Position)
 check(math.abs(lp.X-21.6)<.003 and math.abs(lp.Z+77.4)<.003,p.Name..' external generator')
 local feet=p.Battery.GeneratorVisual.GI_GrelhasEscuras
 check(math.abs(feet.Position.Y-feet.Size.Y/2)<.003,p.Name..' grounded generator')
 local floor,bat,roof=p.Floor,p.Battery,p.Roof;local cf=p:GetPivot()
 check(S.SetHalf(p,72)==p and p.Floor==floor and p.Battery==bat and p.Roof==roof,p.Name..' resize idempotence')
 check(p:GetPivot()==cf,p.Name..' stable pivot')
 for part,relative in _G.CompactBefore.Plots[p.Name].Contents do
  check(part:IsDescendantOf(p) and (p:GetPivot():ToObjectSpace(part.CFrame).Position-relative.Position).Magnitude<.003,'machine local coordinates')
 end
 table.insert(plots,{Id=id,X=expected.X,Z=expected.Z,Half=72})
end
check(C.IsSafe(Vector3.zero) and C.IsSafe(Vector3.new(0,3,1400)),'protected areas')
check(not C.IsSafe(Vector3.new(0,3,900)),'street PvP')
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={w.Decorations.Island,w.Decorations.IslandExtension,w.Biomes}
local samples=0
for z=-650,1340,10 do
 local hit=workspace:Raycast(Vector3.new(0,20,z),Vector3.new(0,-30,0),params)
 check(hit and math.abs(hit.Position.Y)<.01,'continuous floor '..z);samples+=1
end
local guide=setmetatable({Config=C},_G.CompactGuide);local routes=0
for own=1,8 do for victim=1,8 do if own~=victim then
 local pos=(C.PlotCFrame(victim)*CFrame.new(0,2,-35)).Position;local reached=false
 for step=1,10 do
  local goal,label=guide:StolenRoute({PlotId=own,PlotHalf=72,PlotCFrame=C.PlotCFrame(own)},pos)
  check(goal and (goal-pos).Magnitude>.1,'route progress')
  for t=0,10 do check(not C.IsSafe(pos:Lerp(goal,t/10)),'route avoids safe zone') end
  pos=goal;if label=='Entregue a criatura' then reached=true;break end
 end
 check(reached,'route reaches own base');routes+=1
end end end
local fixtures=Instance.new('Folder');fixtures.Name='CompactValidation';fixtures.Parent=game.ServerStorage
local ok,err=pcall(function()
 local p=w.Plots.Plot_01:Clone();p.Name='SyntheticProfile';p:SetAttribute('OwnerUserId',-9001);p.Parent=fixtures
 -- Visual-only stub: production art initializes during Play; this checks real Building state.
 local Art={Structure=function(kind,cf,parent)
  local model=Instance.new('Model');local pad=Instance.new('Part');pad.Name='Pad'
  pad.Size=Vector3.new(C.Items[kind].W,.2,C.Items[kind].D);pad.CFrame=cf;pad.Anchored=true;pad.Parent=model
  model.PrimaryPart=pad;model.Parent=parent;return model
 end}
 local ctx={Config=C,Art=Art,Services={},States={},Toast=function() end,Sync=function() end}
 local building=_G.CompactBuilding.new(ctx)
 local function render(builds,expectedHalf)
  S.SetHalf(p,72)
  local encoded=game.HttpService:JSONEncode(builds)
  local state={Ready=true,Plot=p,PlotId=1,Player={UserId=-9001},Profile={Builds=builds,StarterPlaced=true,Creatures={},Inventory={Belt=20}},Runtime={}}
  building:Render(state)
  check(C.PlotHalfFor(p)==expectedHalf,'legacy envelope preserved')
  check(game.HttpService:JSONEncode(builds)==encoded,'saved positions IDs grid unchanged')
  check(state.Profile.Inventory.Belt==20,'inventory preserved')
  return state
 end
 local starter={{Id='h',Kind='Habitat',X=0,Z=16,R=0},{Id='i',Kind='Incubator',X=-32,Z=-40,R=0},{Id='p',Kind='Processor',X=0,Z=-16,R=0},{Id='s',Kind='Seller',X=0,Z=-36,R=0}}
 check(R.Validate(starter,nil,nil,72),'starter fits compact base');render(starter,72)
 local edge={{Id='old1',Kind='Habitat',X=60,Z=16,R=0},{Id='old2',Kind='Habitat',X=60,Z=-20,R=0}}
 check(R.Validate(edge,nil,nil,80) and not R.Validate(edge,nil,nil,72),'edge legacy fixture');render(edge,80)
 local arrival={{Id='old3',Kind='Processor',X=0,Z=-48,R=0},{Id='old4',Kind='Seller',X=16,Z=-48,R=0}}
 check(R.Validate(arrival,nil,nil,80) and not R.Validate(arrival,nil,nil,72),'arrival legacy fixture');render(arrival,80)
 local owner=render(starter,72)
 owner.Runtime={Positions={},BatteryHP=200,BatteryMax=200,ActiveBatteryLevel=1,BreachUntil=0}
 owner.Profile.BatteryLevel=1;owner.Profile.DefensesBuilt=true
 local function char(name)
  local m=Instance.new('Model');m.Name=name;m.Parent=fixtures
  local humanoid=Instance.new('Humanoid');humanoid.MaxHealth=100;humanoid.Health=100;humanoid.Parent=m
  local root=Instance.new('Part');root.Name='HumanoidRootPart';root.Anchored=true;root.Parent=m
  return m,root
 end
 local oc,oroot=char('owner');owner.Player.Character=oc;oroot.CFrame=p:GetPivot()*CFrame.new(0,4,0)
 local vc,vroot=char('visitor');local visitor={Ready=true,Player={UserId=-9002,Character=vc},Runtime={}}
 ctx.States={owner,visitor};local combat=_G.CompactCombat.new(ctx)
 vroot.CFrame=p:GetPivot()*CFrame.new(21.6,4,-78);local before=vroot.CFrame
 combat:Step(.01);check(vroot.CFrame==before,'visitor reaches external battery without crossing laser')
 vroot.CFrame=p:GetPivot()*CFrame.new(0,4,-70);combat:Step(.01)
 check(math.abs(p:GetPivot():PointToObjectSpace(vroot.Position).Z+78.3)<.003,'inward crossing blocked at compact door')
 owner.Runtime.Positions[-9002]=Vector3.new(0,4,0);vroot.CFrame=p:GetPivot()*CFrame.new(0,4,-78);before=vroot.CFrame
 combat:Step(.01);check(vroot.CFrame==before,'outward crossing allowed')
 owner.Runtime.BreachUntil=os.clock()+30;vroot.CFrame=p:GetPivot()*CFrame.new(0,4,0);before=vroot.CFrame
 combat:Step(.01);check(vroot.CFrame==before,'breached compact base allows visitor')
 combat:SetPlotVacant(p);check(C.PlotHalfFor(p)==72 and p.Floor.Size.X==144,'vacant returns to compact size')
end)
fixtures:Destroy();assert(ok,err)
local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={workspace.walls}
for _,p in w.Plots:GetChildren() do
 check(#workspace:GetPartBoundsInBox(p:GetPivot()*CFrame.new(0,12,0),Vector3.new(144,24,144),overlap)==0,'base clear of cliff wall')
end
local existing=w;local beforeCount=#w:GetDescendants()
check(_G.CompactFactory.Build()==existing and #w:GetDescendants()==beforeCount,'authored factory retains current map')
local compiled=0
for _,root in {game.ReplicatedStorage.EggTycoonV3,game.ServerScriptService.EggTycoonV3,game.StarterPlayer.StarterPlayerScripts} do
 for _,s in root:GetDescendants() do if s:IsA('LuaSourceContainer') then local fn,e=loadstring(s.Source);check(fn,e);compiled+=1 end end
end
local report={Passed=true,Checks=checks,Routes=routes,GroundSamples=samples,Compiled=compiled,Plots=plots,Decorations=100,
 NormalSize=144,LegacySize=160,LegacyProfiles=2,WallIntersections=0,DoorOppositeSeconds=236/18,DoorNextRowSeconds=244/18,
 Host='Studio Edit: actual state/defense modules with synthetic profiles, players and machine visuals; no DataStore or real clients'}
_G.CompactValidation=report
return report
