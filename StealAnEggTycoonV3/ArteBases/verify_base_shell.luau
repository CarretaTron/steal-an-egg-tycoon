-- Edit-only structural checks. Usage: require(thisModule)(freshShellModule, authoredPlot).
-- All work is confined to unparented clones; this never starts Play or loads a profile.
return function(Shell,templatePlot)
 local RunService=game:GetService('RunService')
 assert(not RunService:IsRunning(),'Run this structural check in Edit mode only.')
 assert(type(Shell)=='table' and type(Shell.Apply)=='function','Expected a fresh BaseShell module table.')
 assert(typeof(templatePlot)=='Instance' and templatePlot:IsA('Model'),'Expected an authored plot Model.')
 local report={Mode='Edit',Passed=false,Assertions=0,Failures={},Clones=0,Geometry={},Limitations={
  'Unparented clones only. No Play, physics simulation, DataStore, profile, weapon or theft execution.',
  'Coverage is sampled at the stated positions. It is not a complete volumetric proof or a walking test.',
  'Segments use oriented part boxes. Sealing only counts Block Parts; other shapes are conservative obstacles.',
  'Owned/vacant checks cover Shell.Apply output; Combat presentation transitions are not executed.'}}
 local cleanup={}
 local function check(condition,message)
  report.Assertions+=1
  if not condition then table.insert(report.Failures,message) end
  return condition
 end
 local function near(a,b) return math.abs(a-b)<.001 end
 local function clonePlot()
  local copy=templatePlot:Clone()
  assert(copy,'The template is not Archivable; the original was not modified.')
  copy.Parent=nil
  table.insert(cleanup,copy);report.Clones+=1
  return copy
 end
 local function identities(plot)
  local saved={Children={},Contents={},FloorCF=plot.Floor.CFrame,FloorSize=plot.Floor.Size,
   PivotOffset=plot.Floor.PivotOffset,Pivot=plot:GetPivot(),Primary=plot.PrimaryPart}
  for _,name in ipairs({'Floor','Battery','OwnerSign','ClaimPad','Structures','Creatures'}) do
   saved.Children[name]=plot:FindFirstChild(name)
  end
  local board=saved.Children.OwnerSign
  saved.Title=board and board:FindFirstChild('Title',true)
  saved.Subtitle=board and board:FindFirstChild('Subtitle',true)
  for _,name in ipairs({'ClaimPad','Structures','Creatures'}) do
   local root=saved.Children[name]
   if root then for _,child in ipairs(root:GetDescendants()) do
    saved.Contents[child]=child.Parent
   end end
  end
  return saved
 end
 local function retained(plot,saved,label)
  for name,original in pairs(saved.Children) do
   check(plot:FindFirstChild(name)==original,label..': '..name..' identity preserved')
  end
  check(plot.PrimaryPart==saved.Primary and plot.PrimaryPart==saved.Children.Floor,label..': Floor PrimaryPart preserved')
  check(plot.Floor.CFrame==saved.FloorCF,label..': Floor CFrame preserved')
  check(plot.Floor.Size==saved.FloorSize,label..': Floor size preserved')
  check(plot.Floor.PivotOffset==saved.PivotOffset,label..': Floor PivotOffset preserved')
  check(plot:GetPivot()==saved.Pivot,label..': plot pivot preserved')
  local board=saved.Children.OwnerSign
  check(board and board:FindFirstChild('Title',true)==saved.Title and saved.Title~=nil,label..': Title identity preserved')
  check(board and board:FindFirstChild('Subtitle',true)==saved.Subtitle and saved.Subtitle~=nil,label..': Subtitle identity preserved')
  for child,parent in pairs(saved.Contents) do check(child.Parent==parent,label..': saved content '..child.Name..' preserved') end
 end
 local function shellParts(plot)
  local parts={}
  for _,p in ipairs(plot:GetChildren()) do
   if p:IsA('BasePart') and p:GetAttribute('BaseShellPart') then table.insert(parts,p) end
  end
  return parts
 end
 local function metadata(plot,label)
  local parts=shellParts(plot)
  check(#parts>0,label..': shell has parts')
  check(#parts==plot:GetAttribute('BaseShellPartCount'),label..': declared shell count matches')
  check(plot:GetAttribute('BaseShellRevision')==Shell.Revision,label..': revision matches module')
  check(type(plot:GetAttribute('BaseShellGeneration'))=='number',label..': generation exists')
  for _,p in ipairs(parts) do
   check(p.Anchored,label..': '..p.Name..' anchored')
   check(p:GetAttribute('BaseShellRevision')==Shell.Revision,label..': '..p.Name..' revision matches')
   check(type(p:GetAttribute('BaseShellTransparency'))=='number',label..': '..p.Name..' transparency default exists')
   for _,key in ipairs({'CanCollide','CanTouch','CanQuery'}) do
    check(type(p:GetAttribute('BaseShell'..key))=='boolean',label..': '..p.Name..' '..key..' default exists')
   end
  end
  return parts
 end
 -- Exact for block Parts. Other BaseParts are treated as their conservative boxes.
 local function intersects(p,from,to)
  local a=p.CFrame:PointToObjectSpace(from)
  local d=p.CFrame:PointToObjectSpace(to)-a
  local minimum,maximum=0,1
  for _,axis in ipairs({'X','Y','Z'}) do
   local half=p.Size[axis]/2
   if math.abs(d[axis])<1e-9 then
    if math.abs(a[axis])>half+1e-5 then return false end
   else
    local first,last=(-half-a[axis])/d[axis],(half-a[axis])/d[axis]
    if first>last then first,last=last,first end
    minimum=math.max(minimum,first);maximum=math.min(maximum,last)
    if minimum>maximum+1e-5 then return false end
   end
  end
  return true
 end
 local function geometry(plot,parts)
  local cf=plot:GetPivot()
  local colliders={}
  for _,p in ipairs(parts) do if p.CanCollide and p~=plot.Floor then table.insert(colliders,p) end end
  local function hit(a,b,sealing)
   local from,to=cf:PointToWorldSpace(a),cf:PointToWorldSpace(b)
   for _,p in ipairs(colliders) do
    if not sealing or (p:IsA('Part') and p.Shape==Enum.PartType.Block) then
     if intersects(p,from,to) then return p end
    end
   end
  end
  local entrySamples,wallSamples,roofSamples,gridSamples=0,0,0,0
  for _,x in ipairs({-7.5,-4,0,4,7.5}) do for _,y in ipairs({1,9,17}) do
   entrySamples+=1
   local obstacle=hit(Vector3.new(x,y,-84),Vector3.new(x,y,-76),false)
   check(not obstacle,string.format('Entry x%.1f y%.1f has no solid obstacle (%s)',x,y,obstacle and obstacle.Name or 'clear'))
  end end
  for lateral=-76,76,8 do for _,y in ipairs({1,8,17,26}) do
   for _,side in ipairs({-1,1}) do
    wallSamples+=1
    check(hit(Vector3.new(side*77,y,lateral),Vector3.new(side*83,y,lateral),true)~=nil,
     string.format('Side wall sealed at x%d z%d y%d',side*80,lateral,y))
   end
   wallSamples+=1
   check(hit(Vector3.new(lateral,y,77),Vector3.new(lateral,y,83),true)~=nil,
    string.format('Rear wall sealed at x%d y%d',lateral,y))
   if math.abs(lateral)>=8 then
    wallSamples+=1
    check(hit(Vector3.new(lateral,y,-77),Vector3.new(lateral,y,-83),true)~=nil,
     string.format('Front wall sealed at x%d y%d',lateral,y))
   end
  end end
  for x=-72,72,24 do for z=-72,72,24 do
   roofSamples+=1
   check(hit(Vector3.new(x,26,z),Vector3.new(x,30,z),true)~=nil,string.format('Roof seals x%d z%d near y28',x,z))
  end end
  -- Every four-stud build-grid line is checked through the usable lower interior.
  -- Both directions catch thin obstacles between perpendicular grid lines.
  for lateral=-72,72,4 do for _,y in ipairs({.5,3,6,10,14,18}) do
   for _,axis in ipairs({'X','Z'}) do
    gridSamples+=1
    local a=axis=='X' and Vector3.new(-72,y,lateral) or Vector3.new(lateral,y,-72)
    local b=axis=='X' and Vector3.new(72,y,lateral) or Vector3.new(lateral,y,72)
    local obstacle=hit(a,b,false)
    check(not obstacle,string.format('Build area line %s=%d y%.1f is clear (%s)',axis=='X' and 'Z' or 'X',lateral,y,obstacle and obstacle.Name or 'clear'))
   end
  end end
  report.Geometry={EntrySamples=entrySamples,WallSamples=wallSamples,RoofSamples=roofSamples,GridLines=gridSamples,
   BuildHalf=72,BuildTestHeight={.5,18},DoorHalfWidth=7.5,DoorHeightSamples={1,9,17},WallHeights={1,8,17,26}}
 end
 local function laserState(plot,owned)
  local laser=plot:FindFirstChild('Laser')
  if not check(laser and laser:IsA('BasePart'),'Laser root exists') then return end
  local localCF=plot:GetPivot():ToObjectSpace(laser.CFrame)
  check(near(localCF.X,0) and near(localCF.Y,9) and near(localCF.Z,-80),'Laser position remains (0,9,-80)')
  check(near(laser.Size.X,16) and near(laser.Size.Y,18),'Laser covers the 16 by 18 entry')
  check(laser:GetAttribute('Open')==not owned,'Laser Open follows ownership on construction')
  check(not laser.CanCollide and not laser.CanTouch,'Laser has no physical collision or touch damage')
  check(owned and laser.Transparency<1 or not owned and laser.Transparency==1,'Laser visibility follows ownership on construction')
  local beams=0
  for _,beam in ipairs(plot:GetChildren()) do if beam:IsA('BasePart') and beam.Name=='LaserBeam' then
   beams+=1
   check(not beam.CanCollide and not beam.CanTouch,'LaserBeam has no physical collision or touch damage')
   check(owned and beam.Transparency<1 or not owned and beam.Transparency==1,'LaserBeam visibility follows ownership on construction')
  end end
  check(beams>=3,'Entrance has multiple laser beams')
 end
 local ok,err=xpcall(function()
  for _,name in ipairs({'Floor','Battery','OwnerSign','Structures','Creatures'}) do
   assert(templatePlot:FindFirstChild(name),'Missing required template child '..name)
  end
  local vacant=clonePlot();vacant:SetAttribute('OwnerUserId',0)
  local saved=identities(vacant)
  Shell.Apply(vacant,true)
  retained(vacant,saved,'Vacant rebuild')
  local parts=metadata(vacant,'Vacant rebuild');laserState(vacant,false);geometry(vacant,parts)
  local generation=vacant:GetAttribute('BaseShellGeneration')
  local before={}
  for _,p in ipairs(parts) do before[p]=true end
  Shell.Apply(vacant)
  local after=shellParts(vacant)
  check(#after==#parts,'Idempotent Apply keeps part count')
  check(vacant:GetAttribute('BaseShellGeneration')==generation,'Idempotent Apply keeps generation')
  for _,p in ipairs(after) do check(before[p]==true,'Idempotent Apply keeps shell instances') end
  retained(vacant,saved,'Idempotent Apply')
  Shell.Apply(vacant,true)
  check(#shellParts(vacant)==#parts,'Forced rebuild keeps part count without duplicates')
  check(vacant:GetAttribute('BaseShellGeneration')==generation+1,'Forced rebuild increments generation once')
  retained(vacant,saved,'Forced rebuild')
  report.PartsPerPlot=#parts
  local owned=clonePlot();owned:SetAttribute('OwnerUserId',1)
  local ownedSaved=identities(owned)
  Shell.Apply(owned,true)
  retained(owned,ownedSaved,'Owned rebuild');metadata(owned,'Owned rebuild');laserState(owned,true)
 end,debug.traceback)
 for _,copy in ipairs(cleanup) do copy:Destroy() end
 if not ok then table.insert(report.Failures,'Verifier exception: '..tostring(err)) end
 report.Passed=#report.Failures==0
 return report
end
