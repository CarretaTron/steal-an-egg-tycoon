local RS=game:GetService('ReplicatedStorage')
local Lighting=game:GetService('Lighting')
local C=require(RS.EggTycoonV3.Shared.Config)
local A=require(RS.EggTycoonV3.Shared.Art)
local BaseShell=require(RS.EggTycoonV3.Shared.BaseShell)
local F={}
local preparedWorld
local white=Color3.fromRGB(240,246,252)
local dark=Color3.fromRGB(34,49,67)
local gold=Color3.fromRGB(255,208,65)
local function folder(parent,name) local f=Instance.new('Folder') f.Name=name f.Parent=parent return f end
local function part(p,n,size,cf,col,mat,collide) return A.Part(p,n,size,cf,col,mat,collide) end
local function sign(p,cf,w,title,sub,color)
 local board=part(p,'Sign',Vector3.new(w,8,.6),cf,dark,nil,true)
 local sg=Instance.new('SurfaceGui') sg.Face=Enum.NormalId.Front sg.PixelsPerStud=35 sg.Parent=board
 local t=Instance.new('TextLabel') t.Name='Title' t.Size=UDim2.fromScale(1,.6) t.BackgroundTransparency=1
 t.Font=Enum.Font.GothamBlack t.TextScaled=true t.TextColor3=color or white t.Text=title t.Parent=sg
 local u=t:Clone() u.Name='Subtitle' u.Size=UDim2.fromScale(1,.35) u.Position=UDim2.fromScale(0,.62) u.Text=sub or '' u.TextColor3=white u.Parent=sg
 return board
end
local function tree(p,cf,color,variant)
 part(p,'Trunk',Vector3.new(2,8,2),cf*CFrame.new(0,4,0),Color3.fromRGB(116,79,46),Enum.Material.Wood,true)
 if variant=='pine' then
  for j=0,2 do local q=part(p,'Pine',Vector3.new(12-j*3,7,12-j*3),cf*CFrame.new(0,8+j*3,0),color,nil,false) q.Shape=Enum.PartType.Ball end
 else
  local t=part(p,'Crown',Vector3.new(13,10,12),cf*CFrame.new(0,11,0),color,nil,false) t.Shape=Enum.PartType.Ball
  for s=-1,1,2 do local k=part(p,'Crown',Vector3.new(8,8,8),cf*CFrame.new(s*5,10,1),color,nil,false) k.Shape=Enum.PartType.Ball end
 end
end
local function crystal(p,cf,color,s)
 local q=part(p,'Crystal',Vector3.new(2*s,7*s,2*s),cf*CFrame.new(0,3*s,0)*CFrame.Angles(.1,0,.2),color,Enum.Material.Neon,true)
 for x=-1,1,2 do part(p,'CrystalShard',Vector3.new(s,4*s,s),cf*CFrame.new(x*1.8*s,1.8*s,0)*CFrame.Angles(0,0,-x*.4),color,Enum.Material.Glass,false) end
 return q
end
local function renewArtModel(old,create)
 local cf=old:GetPivot()
 local replacement=create(cf)
 replacement.Name=old.Name
 for name,value in pairs(old:GetAttributes()) do replacement:SetAttribute(name,value) end
 local parts={}
 for _,p in ipairs(replacement:GetChildren()) do
  if p:IsA('BasePart') then parts[p.Name]=parts[p.Name] or {};table.insert(parts[p.Name],p) end
 end
 local used={}
 for _,p in ipairs(old:GetChildren()) do
  if not p:IsA('BasePart') then continue end
  used[p.Name]=(used[p.Name] or 0)+1
  local target=parts[p.Name] and parts[p.Name][used[p.Name]]
  if not target then continue end
  -- Authored mesh appearance is retained, but content comes from this session.
  if not p:GetAttribute('SessionArtPlaceholder') then
   target.Size=p.Size;target.CFrame=p.CFrame;target.Color=p.Color;target.Material=p.Material
   target.Transparency=p.Transparency;target.CastShadow=p.CastShadow
   target:SetAttribute('RestCF',cf:ToObjectSpace(p.CFrame))
  end
  for _,child in ipairs(p:GetChildren()) do
   if child:IsA('LayerCollector') or child:IsA('ProximityPrompt') then
    local copy=child:Clone()
    if copy:IsA('BillboardGui') or copy:IsA('SurfaceGui') then copy.Adornee=target end
    copy.Parent=target
   end
  end
 end
 replacement.Parent=old.Parent
 old:Destroy()
 return replacement
end
local function prepareAuthoredWorld(world)
 for _,name in ipairs({'Plots','Biomes','Nests','Guardians','Decorations'}) do
  assert(world:FindFirstChild(name),'Mapa editado incompleto: falta '..name..'. O mapa foi preservado.')
 end
 -- Static map instances belong to Studio editing; only session mesh content is renewed.
 for _,nest in ipairs(world.Nests:GetChildren()) do
  local species=nest:GetAttribute('Species')
  local egg=nest:FindFirstChild('Egg')
  if egg and C.Species[species] then renewArtModel(egg,function(cf) return A.Egg(species,cf,1.25,nil) end) end
 end
 for _,guard in ipairs(world.Guardians:GetChildren()) do
  local species=guard:GetAttribute('Species')
  if C.Species[species] then
   local cf=guard:GetPivot()
   local fresh=renewArtModel(guard,function(pivot) return A.Creature(species,pivot,2,nil) end)
   fresh:SetAttribute('HomeX',cf.X);fresh:SetAttribute('HomeY',cf.Y);fresh:SetAttribute('HomeZ',cf.Z)
  end
 end
end
function F.Build()
 local old=workspace:FindFirstChild('EggTycoonV3')
 if old then
  local plots=old:FindFirstChild('Plots')
  if plots then for _,plot in ipairs(plots:GetChildren()) do if plot:IsA('Model') then BaseShell.Apply(plot) end end end
  if game:GetService('RunService'):IsRunning() and preparedWorld~=old then
   prepareAuthoredWorld(old)
   old:SetAttribute('RuntimeGenerated',true)
   preparedWorld=old
  end
  return old
 end
 local world=Instance.new('Folder') world.Name='EggTycoonV3' world:SetAttribute('MapVersion',3) world.Parent=workspace
 world:SetAttribute('RuntimeGenerated',game:GetService('RunService'):IsRunning())
 local plots=folder(world,'Plots'); local biomes=folder(world,'Biomes');local nests=folder(world,'Nests');local guards=folder(world,'Guardians');local deco=folder(world,'Decorations')
 -- Chunked assembly keeps every parenting operation bounded.
 local ground=part(deco,'Island',Vector3.new(1400,8,1400),CFrame.new(0,-4,0),Color3.fromRGB(104,181,75),Enum.Material.Grass,true)
 -- Two flush tiles avoid Roblox's 2048-stud maximum Part axis.
 local extensionDepth=C.MapLayout.GroundDepth-1400
 part(deco,'IslandExtension',Vector3.new(1400,8,extensionDepth),CFrame.new(0,-4,700+extensionDepth*.5),ground.Color,ground.Material,true)
 local plaza=part(deco,'SafePlaza',Vector3.new(220,.4,220),CFrame.new(0,.2,0),Color3.fromRGB(235,219,166),Enum.Material.Sandstone,true)
 plaza.TopSurface=Enum.SurfaceType.Studs
 for _,x in ipairs({-115,115}) do part(deco,'SafeBorder',Vector3.new(1,1,230),CFrame.new(x,.6,0),Color3.fromRGB(65,222,224),Enum.Material.Neon,false) end
 for _,z in ipairs({-115,115}) do part(deco,'SafeBorder',Vector3.new(230,1,1),CFrame.new(0,.6,z),Color3.fromRGB(65,222,224),Enum.Material.Neon,false) end
 for j=0,31 do
  local a=j*math.pi/16;local center=Vector3.new(math.sin(a)*330,.15,math.cos(a)*330)
  part(deco,'RingRoad',Vector3.new(58,.3,80),CFrame.new(center)*CFrame.Angles(0,a,0),Color3.fromRGB(210,198,154),Enum.Material.Pavement,true)
 end
 part(deco,'ExpeditionRoad',Vector3.new(C.MapLayout.RoadWidth,.3,C.MapLayout.RoadEnd-C.MapLayout.RoadStart),CFrame.new(0,.15,(C.MapLayout.RoadStart+C.MapLayout.RoadEnd)*.5),Color3.fromRGB(210,198,154),Enum.Material.Pavement,true)
 sign(deco,CFrame.new(0,13,70),58,'STEAL AN EGG','ROUBE • CHOQUE • PRODUZA • DEFENDA',gold)
  sign(deco,CFrame.new(0,13,-85),36,'PRAÇA SEGURA','AS ARMAS NÃO FUNCIONAM AQUI',Color3.fromRGB(101,234,226))
 local spawn=Instance.new('SpawnLocation') spawn.Name='SpawnSeguro' spawn.Size=Vector3.new(16,.5,16) spawn.CFrame=CFrame.new(0,.8,0)
 spawn.Anchored=true spawn.Neutral=true spawn.Duration=0 spawn.Transparency=.15 spawn.Color=Color3.fromRGB(78,211,214) spawn.Material=Enum.Material.Neon spawn.Parent=deco
 for id=1,8 do
  local plot=Instance.new('Model') plot.Name=string.format('Plot_%02d',id) plot:SetAttribute('PlotId',id) plot:SetAttribute('OwnerUserId',0)
  local cf=C.PlotCFrame(id)
  local floor=part(plot,'Floor',Vector3.new(160,1,160),cf*CFrame.new(0,-.5,0),Color3.fromRGB(151,188,125),Enum.Material.SmoothPlastic,true)
  floor.TopSurface=Enum.SurfaceType.Studs floor.PivotOffset=floor.CFrame:ToObjectSpace(cf) plot.PrimaryPart=floor
  local battery=part(plot,'Battery',Vector3.new(6,7,4),cf*CFrame.new(24,3.5,-86),Color3.fromRGB(73,228,158),Enum.Material.Metal,true) battery:SetAttribute('PlotId',id)
  local owner=sign(plot,cf*CFrame.new(0,20,-81),42,string.format('TYCOON %02d',id),'BASE DISPONÍVEL',gold) owner.Name='OwnerSign'
  folder(plot,'Structures');folder(plot,'Creatures')
  BaseShell.Apply(plot)
  local door=(cf*CFrame.new(0,0,-C.PlotHalf)).Position
  local near=C.MapLayout.RoadWidth*.5;local far=math.abs(door.X)+2;local side=door.X<0 and -1 or 1
  part(deco,'PlotRoad',Vector3.new(far-near,.3,20),CFrame.new(side*(near+far)*.5,.15,door.Z),Color3.fromRGB(210,198,154),Enum.Material.Pavement,true)
  plot.Parent=plots task.wait()
 end
 for i,species in ipairs(C.Species) do
  local z=650+(i-1)*180+C.MapLayout.CorridorOffset
  local section=Instance.new('Model') section.Name='Biome_'..i
  local cf=CFrame.new(0,0,z+90)
  local f=part(section,'BiomeGround',Vector3.new(176,8,180),cf*CFrame.new(0,-4,0),species.Ground,Enum.Material.SmoothPlastic,true) f.TopSurface=Enum.SurfaceType.Studs
  for side=-1,1,2 do
   part(section,'CanyonWall',Vector3.new(8,44,180),cf*CFrame.new(side*92,22,0),species.Ground:Lerp(dark,.30),Enum.Material.Slate,true)
   part(section,'WallTop',Vector3.new(11,1.2,180),cf*CFrame.new(side*92,44,0),species.Color,Enum.Material.Neon,false)
  end
  sign(section,cf*CFrame.new(0,19,-85),66,string.upper(species.Biome),species.Name..' • '..species.Resource,species.Color)
  for _,x in ipairs({-86,86}) do part(section,'Gateway',Vector3.new(2,32,3),cf*CFrame.new(x,16,-86),species.Color,Enum.Material.Neon,true) end
  for j=1,8 do
   local side=j%2==0 and 1 or -1;local px=side*(64+(j%3)*5);local pz=-65+math.floor((j-1)/2)*42
   local pcf=cf*CFrame.new(px,0,pz)
   if i==1 or i==2 then tree(section,pcf,i==1 and Color3.fromRGB(70,160,69) or Color3.fromRGB(34,110,74),i==2 and 'pine' or nil)
   elseif i==3 then
    local pool=part(section,'SwampPool',Vector3.new(15,.3,20),pcf*CFrame.new(0,.05,0),Color3.fromRGB(83,156,102),Enum.Material.Glass,false) pool.Transparency=.2
    part(section,'Reed',Vector3.new(.6,8,.6),pcf*CFrame.new(4,4,0),species.Color,nil,false)
   elseif i==4 then
    part(section,'Cactus',Vector3.new(2.5,10,2.5),pcf*CFrame.new(0,5,0),Color3.fromRGB(70,142,66),nil,true)
    part(section,'CactusArm',Vector3.new(7,2,2),pcf*CFrame.new(0,6,0),Color3.fromRGB(70,142,66),nil,true)
   else crystal(section,pcf,species.Color,1+(j%2)*.4) end
   local rock=part(section,'Rock',Vector3.new(6,3,6),pcf*CFrame.new(-side*9,1.5,8)*CFrame.Angles(.2,j,.15),species.Ground:Lerp(dark,.22),Enum.Material.Slate,true)
  end
  if i==6 then
   for side=-1,1,2 do part(section,'LavaChannel',Vector3.new(6,.3,150),cf*CFrame.new(side*76,.05,0),Color3.fromRGB(255,119,33),Enum.Material.Neon,false) end
  elseif i==7 then
   for j=1,12 do local star=part(section,'Star',Vector3.new(.8,.8,.8),cf*CFrame.new((j%2==0 and -1 or 1)*87,8+(j%4)*6,-70+j*11),white,Enum.Material.Neon,false) star.Shape=Enum.PartType.Ball end
  end
  section.Parent=biomes task.wait()
  for n=1,2 do
   local x=n==1 and -42 or 42;local nz=z+88+(n-1)*32;local id='B'..i..'_'..n
   local nest=Instance.new('Model') nest.Name='Nest_'..id nest:SetAttribute('Species',i) nest:SetAttribute('NestId',id) nest:SetAttribute('Available',true) nest:SetAttribute('RespawnSeconds',15+i*5)
   local base=part(nest,'Base',Vector3.new(14,1,14),CFrame.new(x,.5,nz),Color3.fromRGB(154,103,54),Enum.Material.Wood,true) base.Shape=Enum.PartType.Cylinder base.Size=Vector3.new(1,14,14) base.CFrame=CFrame.new(x,.5,nz)*CFrame.Angles(0,0,math.pi/2)
   for k=0,11 do local a=k*math.pi/6 part(nest,'Twig',Vector3.new(6,.7,.7),CFrame.new(x+math.cos(a)*5.4,1,nz+math.sin(a)*5.4)*CFrame.Angles(0,-a,0),Color3.fromRGB(112,72,41),Enum.Material.Wood,false) end
   local egg=A.Egg(i,CFrame.new(x,1.1,nz),1.25,nest)
   local prompt=Instance.new('ProximityPrompt') prompt.Name='StealEgg' prompt.ActionText='Roubar ovo' prompt.ObjectText=species.Name prompt.HoldDuration=.6 prompt.MaxActivationDistance=11 prompt.RequiresLineOfSight=false
   prompt:SetAttribute('Action','StealEgg') prompt:SetAttribute('Species',i) prompt:SetAttribute('NestId',id) prompt.Parent=egg.PrimaryPart
   A.Label(nest,egg.PrimaryPart,'OVO • '..string.upper(species.Biome),species.Name,species.Color,65)
   nest.PrimaryPart=base nest.Parent=nests
   local home=CFrame.new(x*.65,0,nz+16)*CFrame.Angles(0,math.pi,0)
   local guard=A.Creature(i,home,2,guards) guard.Name='Guardian_'..id
   guard:SetAttribute('Species',i) guard:SetAttribute('NestId',id) guard:SetAttribute('HomeX',home.X) guard:SetAttribute('HomeY',0) guard:SetAttribute('HomeZ',home.Z) guard:SetAttribute('Speed',species.Speed) guard:SetAttribute('Damage',species.Damage)
   A.Label(guard,guard.PrimaryPart,string.upper(species.Name),'GUARDIÃO • '..species.Speed..' VELOCIDADE',species.Color,90)
  end
  task.wait()
 end
  sign(deco,CFrame.new(0,13,620+C.MapLayout.CorridorOffset),50,'EXPEDIÇÃO','ROUBE UM OVO E VOLTE AO TYCOON',gold)
 part(deco,'CorridorApproach',Vector3.new(176,8,70),CFrame.new(0,-4,615+C.MapLayout.CorridorOffset),C.Species[1].Ground,Enum.Material.Grass,true)
 part(deco,'FinalWall',Vector3.new(192,44,8),CFrame.new(0,22,1914+C.MapLayout.CorridorOffset),C.Species[7].Ground,Enum.Material.Slate,true)
 for j=1,12 do
  local a=j*math.pi/6
   local treeX,treeZ=math.sin(a)*640,math.cos(a)*640
   -- Keep the central expedition walkway clear at the corridor approach.
   if treeZ>=580 and math.abs(treeX)<28 then treeX=45 end
   tree(deco,CFrame.new(treeX,0,treeZ),Color3.fromRGB(61,137,73))
 end
 Lighting.ClockTime=13.5 Lighting.Brightness=2.5 Lighting.Ambient=Color3.fromRGB(148,163,184) Lighting.OutdoorAmbient=Color3.fromRGB(158,177,196)
 Lighting.GlobalShadows=true Lighting.FogEnd=6000
 local atmosphere=Lighting:FindFirstChildOfClass('Atmosphere') or Instance.new('Atmosphere') atmosphere.Density=.15 atmosphere.Haze=.7 atmosphere.Color=Color3.fromRGB(196,224,255) atmosphere.Parent=Lighting
 local pilot=workspace:FindFirstChild('EggTycoonPilot') if pilot then pilot:Destroy() end
 preparedWorld=world
 return world
end
return F
