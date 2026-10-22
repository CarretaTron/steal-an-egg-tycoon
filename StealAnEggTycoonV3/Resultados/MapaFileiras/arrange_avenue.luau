-- Explicit Studio Edit operation. Never run this helper from the game bootstrap.
assert(not game:GetService('RunService'):IsRunning(), 'Use this helper only in Edit')
local C = assert(_G.AvenueConfig, 'Load the current Config into _G.AvenueConfig first')
local L = C.MapLayout
local world = workspace.EggTycoonV3
if world:GetAttribute('AvenueLayoutRevision') == L.Revision then
 return {AlreadyApplied=true, Revision=L.Revision}
end
assert(_G.LayoutBefore and _G.LayoutBefore.Native, 'Capture a complete native backup first')
local library = game.ServerStorage.BibliotecaDecoracao
for _, name in ipairs({'ArvoreCampestre','ArbustoRedondo','ArbustoFlorido','FloresSilvestres','PedraMusgo'}) do
 assert(library:FindFirstChild(name), 'Missing decoration: '..name)
end
local deco = world.Decorations
local before = {Plots={}, Biomes={}, Nests={}, Guardians={}}
_G.AvenueBefore = before
for _, plot in ipairs(world.Plots:GetChildren()) do
 assert((plot:GetAttribute('OwnerUserId') or 0)==0, 'Do not move an occupied runtime base')
 local data={Plot=plot,Pivot=plot:GetPivot(),Parts={},Battery=plot.Battery,Floor=plot.Floor}
 for _, p in ipairs(plot:GetDescendants()) do
  if p:IsA('BasePart') then data.Parts[p]=data.Pivot:ToObjectSpace(p.CFrame) end
 end
 before.Plots[plot.Name]=data
end
local history=Instance.new('Folder');history.Name='MapaAntesFileiras';history.Parent=game.ServerStorage
local removedTrees=Instance.new('Folder');removedTrees.Name='ArvoresPrimitivas';removedTrees.Parent=history
local oldRoads={}
for _, p in ipairs(workspace:GetDescendants()) do
 if p:IsA('BasePart') and p.Name=='ExpeditionRoad' then table.insert(oldRoads,p) end
end
assert(#oldRoads>0, 'Existing main road not found')
local road=oldRoads[1]
road.Parent=deco;road.CFrame=CFrame.new(0,.15,(L.RoadStart+L.RoadEnd)/2)
road.Size=Vector3.new(L.RoadWidth,.3,L.RoadEnd-L.RoadStart)
road.TopSurface=Enum.SurfaceType.Studs
for i=2,#oldRoads do oldRoads[i].Parent=history end
local roads={}
for _, p in ipairs(deco:GetChildren()) do
 if p:IsA('BasePart') and p.Name=='PlotRoad' then table.insert(roads,p)
 elseif p:IsA('BasePart') and (p.Name=='Trunk' or p.Name=='Crown' or p.Name=='Pine') then p.Parent=removedTrees end
end
assert(#roads==8,'Expected the eight existing entrance paths')
local island=deco.Island
-- Roblox clamps a single Part axis to 2048 studs; keep two flush ground tiles.
island.Size=Vector3.new(1400,8,1400)
island.CFrame=CFrame.new(0,-4,0)
local extension=island:Clone();extension.Name='IslandExtension'
extension.Size=Vector3.new(1400,8,L.GroundDepth-1400)
extension.CFrame=CFrame.new(0,-4,700+(L.GroundDepth-1400)/2);extension.Parent=deco
for id=1,8 do
 local plot=world.Plots:FindFirstChild(string.format('Plot_%02d',id))
 assert(plot,'Missing plot '..id)
 plot:PivotTo(C.PlotCFrame(id))
 local side=id%2==1 and -1 or 1
 local z=C.PlotCFrame(id).Z
 roads[id].Size=Vector3.new(136,.3,20)
 roads[id].CFrame=CFrame.new(side*84,.15,z)
 roads[id]:SetAttribute('PlotId',id)
 roads[id].TopSurface=Enum.SurfaceType.Studs
 task.wait()
end
local shift=Vector3.new(0,0,L.CorridorOffset)
for _, folderName in ipairs({'Biomes','Nests','Guardians'}) do
 for _, model in ipairs(world[folderName]:GetChildren()) do
  if model:IsA('Model') then
   before[folderName][model]=model:GetPivot()
   model:PivotTo(model:GetPivot()+shift)
   if folderName=='Guardians' then
    local home=model:GetAttribute('HomeZ')
    if type(home)=='number' then model:SetAttribute('HomeZ',home+L.CorridorOffset) end
   end
  end
 end
 task.wait()
end
for _, p in ipairs(deco:GetChildren()) do
 if p:IsA('BasePart') and (p.Name=='CorridorApproach' or p.Name=='FinalWall'
  or (p.Name=='Sign' and p.Position.Z>=580 and math.abs(p.Position.X)<200)) then
  p.CFrame+=shift
 end
end
-- Preserve the user's already positioned tree beside the first biome.
for _, m in ipairs(workspace:GetChildren()) do
 if m:IsA('Model') and m.Name=='ArvoreCampestre' then
  local p=m:GetPivot().Position
  if p.Z>=580 and math.abs(p.X)<100 then m:PivotTo(m:GetPivot()+shift) end
 end
end
-- Reuse the authored cliff modules, extending the side walls and moving the far gate.
local walls=workspace:FindFirstChild('walls')
local addedCliffs=0
if walls then
 local sides={}
 for _, m in ipairs(walls:GetChildren()) do
  if m:IsA('Model') then
   local cf=m:GetBoundingBox()
   if cf.Z>600 then
    m:PivotTo(m:GetPivot()+shift)
   elseif math.abs(cf.X)>600 and cf.Z>0 and cf.Z<600 then
    table.insert(sides,m)
   end
  end
 end
 for _, amount in ipairs({560,1120}) do
  for _, original in ipairs(sides) do
   local copy=original:Clone()
   copy:SetAttribute('AvenueCliffExtension',true)
   copy:PivotTo(copy:GetPivot()+Vector3.new(0,0,amount));copy.Parent=walls
   addedCliffs+=1
  end
  task.wait()
 end
end
local garden=Instance.new('Folder');garden.Name='AvenidaDecoracao';garden.Parent=deco
local counts={}
local decorations=0
local function place(name,x,z,scale,yaw)
 local model=library[name]:Clone()
 model.Name=name..'_'..string.format('%03d',decorations+1)
 model:ScaleTo(scale or 1)
 model:PivotTo(CFrame.new(x,0,z)*CFrame.Angles(0,math.rad(yaw or 0),0))
 model:SetAttribute('DecorationTemplate',name)
 model:SetAttribute('AvenueLayoutRevision',L.Revision)
 model.Parent=garden
 counts[name]=(counts[name] or 0)+1;decorations+=1
 if decorations%16==0 then task.wait() end
 return model
end
for _, side in ipairs({-1,1}) do
 for row=0,3 do
  local z=L.PlotStartZ+row*L.RowSpacing
  place('ArvoreCampestre',side*78,z+98,1.65,side*(row*37+12))
  place('ArvoreCampestre',side*410,z+28,2.25+(row%2)*.2,side*(row*51+20))
  place('ArvoreCampestre',side*548,z-80,1.8+(row%2)*.2,row*73)
  place('ArbustoRedondo',side*96,z-44,1.8,row*35)
  place('ArbustoFlorido',side*96,z+44,1.6,row*63)
  place('ArbustoRedondo',side*380,z-80,2.1,row*47)
  place('ArbustoRedondo',side*45,z+132,1.5,row*20)
  place('FloresSilvestres',side*118,z-60,1.25,row*19)
  place('FloresSilvestres',side*117,z+60,1.15,row*57)
  place('PedraMusgo',side*470,z+100,2,row*43)
 end
 for i,p in ipairs({{420,140},{520,-150},{475,-430},{480,1510}}) do
  place('ArvoreCampestre',side*p[1],p[2],2.2+(i%2)*.25,side*i*47)
 end
 for i,p in ipairs({{405,-30},{450,230},{545,-315},{390,-360}}) do
  place('ArbustoRedondo',side*p[1],p[2],2,side*i*39)
 end
 for i,z in ipairs({-260,210}) do place('PedraMusgo',side*550,z,2.2,i*74) end
end
world:SetAttribute('AvenueLayoutRevision',L.Revision)
world:SetAttribute('AvenueCorridorOffset',L.CorridorOffset)
local report={Revision=L.Revision,Plots=8,Rows=4,GroundTiles=2,GroundBoundsZ={-700,1700},
 CorridorOffset=L.CorridorOffset,Decorations=decorations,ByTemplate=counts,AddedCliffs=addedCliffs,
 PrimitiveTreePartsPreserved=#removedTrees:GetChildren(),DuplicateRoadsPreserved=#oldRoads-1}
_G.AvenueInstallReport=report
return report
