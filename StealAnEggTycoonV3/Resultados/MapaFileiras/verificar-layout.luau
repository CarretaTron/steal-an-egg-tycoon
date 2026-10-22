local C=_G.AvenueConfig
local w=workspace.EggTycoonV3;local checks=0;local plots={}
local function check(v,message) checks+=1;assert(v,message) end
for name,data in _G.AvenueBefore.Plots do
 local p=data.Plot;local id=p:GetAttribute('PlotId');local expected=C.PlotCFrame(id)
 check((p:GetPivot().Position-expected.Position).Magnitude<.001,name..' center')
 check(p:GetPivot().LookVector:Dot((Vector3.new(0,1,expected.Z)-expected.Position).Unit)>.999,name..' faces street')
 check(p.Battery==data.Battery and p.Floor==data.Floor,name..' identities')
 check(p.Floor.Size==Vector3.new(160,1,160),name..' floor size')
 for part,relative in data.Parts do
  check(part:IsDescendantOf(p),name..' preserved part')
  local actual=p:GetPivot():ToObjectSpace(part.CFrame)
  check((actual.Position-relative.Position).Magnitude<.003,name..' local layout')
  check(actual.LookVector:Dot(relative.LookVector)>.9999,name..' local orientation')
 end
 local feet=p.Battery.GeneratorVisual.GI_GrelhasEscuras
 check(math.abs(feet.Position.Y-feet.Size.Y/2)<.003,name..' generator grounded')
 local door=(expected*CFrame.new(0,2,-80)).Position
 check(math.abs(door.X)==150,name..' door distance from street')
 check(not C.IsSafe(door),name..' PvP door')
 table.insert(plots,{Name=name,Position={expected.X,expected.Y,expected.Z},Door={door.X,door.Y,door.Z}})
end
for folderName,data in {Biomes=_G.AvenueBefore.Biomes,Nests=_G.AvenueBefore.Nests,Guardians=_G.AvenueBefore.Guardians} do
 for m,cf in data do check((m:GetPivot().Position-(cf.Position+Vector3.new(0,0,1000))).Magnitude<.003,folderName..' shifted intact') end
end
check(C.IsSafe(Vector3.zero),'plaza safe')
check(not C.IsSafe(Vector3.new(0,2,1000)),'street PvP')
check(C.IsSafe(Vector3.new(0,2,1700)),'biomes safe')
check(not C.IsSafe(Vector3.new(95,2,1700)),'corridor side not safe')
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={w.Decorations.Island,w.Decorations.IslandExtension,w.Biomes}
local samples=0
for z=-650,1700,25 do
 local hit=workspace:Raycast(Vector3.new(0,20,z),Vector3.new(0,-30,0),params)
 check(hit and math.abs(hit.Position.Y)<.01,'continuous ground '..z);samples+=1
end
local shared=game.ReplicatedStorage.EggTycoonV3.Shared
local fresh=shared.HudGuide:Clone();fresh.Name='AvenueGuideFresh';fresh.Parent=shared
local Guide=require(fresh);fresh:Destroy()
local guide=setmetatable({Config=C},Guide)
local routeCount=0;local longest=0
for own=1,8 do for victim=1,8 do if own~=victim then
 local pos=(C.PlotCFrame(victim)*CFrame.new(0,2,-40)).Position
 local reached=false;local steps=0
 for step=1,10 do
  local goal,label=guide:StolenRoute({PlotId=own,PlotCFrame=C.PlotCFrame(own)},pos)
  check(goal~=nil,'route goal')
  for t=0,10 do check(not C.IsSafe(pos:Lerp(goal,t/10)),'route avoids safe zone') end
  check((goal-pos).Magnitude>.1,'route does not stall')
  steps=step;pos=goal
  if label=='Entregue a criatura' then reached=true;break end
 end
 check(reached,'route reaches owner '..own..' from '..victim)
 routeCount+=1;longest=math.max(longest,steps)
end end end
local compiled=0
for _,root in {game.ReplicatedStorage.EggTycoonV3,game.ServerScriptService.EggTycoonV3,game.StarterPlayer.StarterPlayerScripts} do
 for _,s in root:GetDescendants() do if s:IsA('LuaSourceContainer') then
  local fn,e=loadstring(s.Source,s:GetFullName());assert(fn,e);compiled+=1
 end end
end
local meshes,unsafe=0,0
for _,m in w.Decorations.AvenidaDecoracao:GetDescendants() do
 if m:IsA('MeshPart') then meshes+=1;check(m.Anchored and not m.CanCollide and not m.CanTouch,'static decoration mesh')
 elseif m:IsA('LuaSourceContainer') then unsafe+=1 end
end
check(unsafe==0,'decorations have no scripts')
for _,m in w.Decorations.AvenidaDecoracao:GetChildren() do
 local cf,size=m:GetBoundingBox()
 check(math.abs(cf.X)-size.X/2>C.MapLayout.RoadWidth/2,'street clear '..m.Name)
end
_G.AvenueValidation={Passed=true,Checks=checks,Plots=plots,Routes=routeCount,MaxRouteSteps=longest,Compiled=compiled,
 Decorations=100,DecorationMeshParts=meshes,GroundTiles=2,GroundSamples=samples,
 EstimatedSecondsBetweenDoors={Opposite=300/18,NextRow=280/18},Host='Studio Edit; geometry and route simulation, no players or profiles'}
return _G.AvenueValidation