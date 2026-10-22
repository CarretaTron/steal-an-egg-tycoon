assert(not game:GetService('RunService'):IsRunning(),'Edit only')
local C=assert(_G.AvenueConfig);local Shell=assert(_G.AvenueShell)
local w=workspace.EggTycoonV3;local L=C.MapLayout
if w:GetAttribute('AvenueLayoutRevision')==L.Revision then return {AlreadyApplied=true} end
assert(w:GetAttribute('AvenueLayoutRevision')==1,'Apply the avenue before compacting')
_G.CompactBefore={Plots={},FirstCorridorOffset=w:GetAttribute('AvenueCorridorOffset')}
for _,plot in w.Plots:GetChildren() do
 local record={Plot=plot,Floor=plot.Floor,Battery=plot.Battery,Pivot=plot:GetPivot(),Contents={}}
 for _,folder in ipairs({'Structures','Creatures','Incubations'}) do
  local f=plot:FindFirstChild(folder)
  if f then for _,p in f:GetDescendants() do
   if p:IsA('BasePart') then record.Contents[p]=plot:GetPivot():ToObjectSpace(p.CFrame) end
  end end
 end
 _G.CompactBefore.Plots[plot.Name]=record
 assert(Shell.SetHalf(plot,C.PlotHalf)~=false,'Resize cancelled')
 plot:PivotTo(C.PlotCFrame(plot:GetAttribute('PlotId')))
 task.wait()
end
local d=w.Decorations
d.Island.Size=Vector3.new(1400,8,1400);d.Island.CFrame=CFrame.new(0,-4,0)
local depth=L.GroundDepth-1400
d.IslandExtension.Size=Vector3.new(1400,8,depth);d.IslandExtension.CFrame=CFrame.new(0,-4,700+depth/2)
d.ExpeditionRoad.Size=Vector3.new(L.RoadWidth,.3,L.RoadEnd-L.RoadStart)
d.ExpeditionRoad.CFrame=CFrame.new(0,.15,(L.RoadStart+L.RoadEnd)/2)
for _,road in d:GetChildren() do
 if road:IsA('BasePart') and road.Name=='PlotRoad' then
  local id=road:GetAttribute('PlotId');assert(id)
  local side=id%2==1 and -1 or 1;local z=C.PlotCFrame(id).Z
  local near=L.RoadWidth/2;local far=L.PlotX-C.PlotHalf+2
  road.Size=Vector3.new(far-near,.3,20);road.CFrame=CFrame.new(side*(near+far)/2,.15,z)
 end
end
local delta=L.CorridorOffset-_G.CompactBefore.FirstCorridorOffset
local shift=Vector3.new(0,0,delta)
for _,name in ipairs({'Biomes','Nests','Guardians'}) do
 for _,m in w[name]:GetChildren() do if m:IsA('Model') then
  m:PivotTo(m:GetPivot()+shift)
  if name=='Guardians' and type(m:GetAttribute('HomeZ'))=='number' then m:SetAttribute('HomeZ',m:GetAttribute('HomeZ')+delta) end
 end end
end
for _,p in d:GetChildren() do
 if p:IsA('BasePart') and (p.Name=='FinalWall' or p.Name=='CorridorApproach' or (p.Name=='Sign' and p.Position.Z>1500)) then p.CFrame+=shift end
end
for _,m in workspace:GetChildren() do
 if m:IsA('Model') and m.Name=='ArvoreCampestre' and m:GetPivot().Z>1500 and math.abs(m:GetPivot().X)<100 then m:PivotTo(m:GetPivot()+shift) end
end
-- Compress the existing side extensions; preserve every cliff model.
for _,m in workspace.walls:GetChildren() do if m:IsA('Model') then
 local cf=m:GetBoundingBox()
 if m:GetAttribute('AvenueCliffExtension') then
  local amount=cf.Z>1120 and 1120 or 560
  -- The source side modules were at Z30..545. Distinguish the overlapping bands by pivot.
  local source=m:GetAttribute('AvenueExtensionSourceZ')
  if not source then
   local best,dist
   for _,original in workspace.walls:GetChildren() do
    if original:IsA('Model') and not original:GetAttribute('AvenueCliffExtension') then
     local originalCF=original:GetBoundingBox()
     if math.abs(originalCF.X-cf.X)<1 and originalCF.Z>0 and originalCF.Z<600 then
      for _,a in ipairs({560,1120}) do
       local e=math.abs(originalCF.Z+a-cf.Z)
       if not dist or e<dist then source=originalCF.Z;amount=a;dist=e end
      end
     end
    end
   end
   assert(dist and dist<.1,'Cliff source not found')
  end
  local newAmount=amount==560 and L.CorridorOffset/2 or L.CorridorOffset
  m:PivotTo(m:GetPivot()+Vector3.new(0,0,newAmount-amount))
  m:SetAttribute('AvenueExtensionSourceZ',source)
 elseif cf.Z>1500 then m:PivotTo(m:GetPivot()+shift+Vector3.new(0,0,L.CliffExtra or 0)) end
end end
-- Reposition the same hundred decorations; no new meshes are created here.
local function move(name,x,z,yaw)
 local m=d.AvenidaDecoracao:FindFirstChild(name);assert(m,name)
 m:PivotTo(CFrame.new(x,0,z)*CFrame.Angles(0,math.rad(yaw or 0),0))
 m:SetAttribute('AvenueLayoutRevision',L.Revision)
end
local index=0
local function nextMove(template,x,z,yaw)
 index+=1;move(template..'_'..string.format('%03d',index),x,z,yaw)
end
for _,side in ipairs({-1,1}) do
 for row=0,3 do
  local z=L.PlotStartZ+row*L.RowSpacing
  nextMove('ArvoreCampestre',side*65,z+98,side*(row*37+12))
  nextMove('ArvoreCampestre',side*365,z+28,side*(row*51+20))
  nextMove('ArvoreCampestre',side*510,z-80,row*73)
  nextMove('ArbustoRedondo',side*80,z-44,row*35)
  nextMove('ArbustoFlorido',side*80,z+44,row*63)
  nextMove('ArbustoRedondo',side*330,z-80,row*47)
  nextMove('ArbustoRedondo',side*43,z+116,row*20)
  nextMove('FloresSilvestres',side*95,z-60,row*19)
  nextMove('FloresSilvestres',side*95,z+60,row*57)
  nextMove('PedraMusgo',side*430,z+100,row*43)
 end
 for i,p in ipairs({{420,140},{520,-150},{475,-430},{480,L.CorridorStart-90}}) do nextMove('ArvoreCampestre',side*p[1],p[2],side*i*47) end
 for i,p in ipairs({{405,-30},{450,230},{545,-315},{390,-360}}) do nextMove('ArbustoRedondo',side*p[1],p[2],side*i*39) end
 for i,z in ipairs({-260,210}) do nextMove('PedraMusgo',side*550,z,i*74) end
end
assert(index==100)
w:SetAttribute('AvenueLayoutRevision',L.Revision);w:SetAttribute('AvenueCorridorOffset',L.CorridorOffset)
return {Plots=8,SizeStuds=144,Revision=L.Revision,CorridorOffset=L.CorridorOffset,Decorations=index}
