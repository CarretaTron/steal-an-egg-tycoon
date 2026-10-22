-- Blender-authored industrial shell. Gameplay contents and plot identities stay authored.
local Data=require(script.Parent.BaseIndustrialData)
local Generator=require(script.Parent.Generator)
local AssetService=game:GetService('AssetService')
local Shell={Revision=4}
local cache={}
local legacy={Perimeter=true,Frame=true,Roof=true,RoofFrame=true,DoorHeader=true,Laser=true,LaserBeam=true}

local function defaults(p,alpha,collide,query)
 p:SetAttribute('BaseShellPart',true)
 p:SetAttribute('BaseShellRevision',Shell.Revision)
 p:SetAttribute('BaseShellTransparency',alpha)
 p:SetAttribute('BaseShellCanCollide',collide)
 p:SetAttribute('BaseShellCanTouch',collide)
 p:SetAttribute('BaseShellCanQuery',query)
end

local function prototype(def)
 local key=def.Name..def.MeshId
 if cache[key] then return cache[key] end
 local p=AssetService:CreateMeshPartAsync(Content.fromUri(def.MeshId))
 p.Name=def.Name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 cache[key]=p
 return p
end

function Shell.Seed(model)
 for _,def in ipairs(Data.Meshes) do
  local p=model:FindFirstChild(def.SourceName or def.Name,true)
  assert(p and p:IsA('MeshPart') and p.MeshId==def.MeshId,'Blender template mismatch: '..def.Name)
  cache[def.Name..def.MeshId]=p:Clone()
 end
end

local function batteryDefaults(plot)
 local b=plot:FindFirstChild('Battery')
 if not b or not b:IsA('BasePart') then return end
 for _,key in ipairs({'Transparency','CanCollide','CanTouch','CanQuery'}) do
  if b:GetAttribute('BaseShell'..key)==nil then b:SetAttribute('BaseShell'..key,b[key]) end
 end
 local vacant=(plot:GetAttribute('OwnerUserId') or 0)==0
 if vacant then b.Transparency=1;b.CanCollide=false;b.CanTouch=false;b.CanQuery=false end
 for _,gui in ipairs(b:GetDescendants()) do
  if gui:IsA('BillboardGui') or gui:IsA('SurfaceGui') then
   if gui:GetAttribute('BaseShellEnabled')==nil then gui:SetAttribute('BaseShellEnabled',gui.Enabled) end
   if vacant then gui.Enabled=false end
  end
 end
end

local function ownerSign(plot,cf)
 local p=plot:FindFirstChild('OwnerSign')
 if not p then p=Instance.new('Part');p.Name='OwnerSign';p.Parent=plot end
 assert(p:IsA('BasePart'),'OwnerSign must remain a BasePart')
 p.Size=Vector3.new(59,7.8,.8);p.CFrame=cf*CFrame.new(0,29,-83.35)
 p.Color=Color3.fromRGB(139,72,55);p.Material=Enum.Material.SmoothPlastic
 p.Anchored=true;p.Transparency=0;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
 for _,face in ipairs({'TopSurface','BottomSurface','FrontSurface','BackSurface','LeftSurface','RightSurface'}) do p[face]=Enum.SurfaceType.Smooth end
 defaults(p,0,false,false)
 local gui=p:FindFirstChildWhichIsA('SurfaceGui')
 if gui and not gui:GetAttribute('BaseIndustrialCanvas') then
  -- Recreate the legacy canvas after changing its aspect ratio; retain the live labels.
  local old=gui;gui=Instance.new('SurfaceGui');gui.Name='SurfaceGui';gui.Face=Enum.NormalId.Front
  for _,child in ipairs(old:GetChildren()) do child.Parent=gui end
  old:Destroy();gui.Parent=p
 end
 if not gui then gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.PixelsPerStud=45;gui.Parent=p end
 gui:SetAttribute('BaseIndustrialCanvas',true)
 gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=16
 local title=gui:FindFirstChild('Title')
 if not title then title=Instance.new('TextLabel');title.Name='Title';title.Text='TYCOON '..tostring(plot:GetAttribute('PlotId') or '');title.Parent=gui end
 local sub=gui:FindFirstChild('Subtitle')
 if not sub then sub=Instance.new('TextLabel');sub.Name='Subtitle';sub.Text='BASE DISPONÍVEL';sub.Parent=gui end
 title.Size=UDim2.fromScale(.95,.59);title.Position=UDim2.fromScale(.025,.045)
 sub.Size=UDim2.fromScale(.95,.24);sub.Position=UDim2.fromScale(.025,.71)
 for _,label in ipairs({title,sub}) do
  label.AnchorPoint=Vector2.zero;label.Rotation=0
  label.TextXAlignment=Enum.TextXAlignment.Center;label.TextYAlignment=Enum.TextYAlignment.Center
  label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBlack;label.TextScaled=true
  label.TextColor3=Color3.fromRGB(255,244,237);label.TextStrokeTransparency=.6
 end
end

function Shell.Apply(plot,force)
 assert(plot and plot:IsA('Model'),'BaseShell.Apply expects a plot Model')
 Generator.Apply(plot)
 local count=0
 for _,p in ipairs(plot:GetChildren()) do if p:IsA('BasePart') and p:GetAttribute('BaseShellPart') then count+=1 end end
 if not force and plot:GetAttribute('BaseShellRevision')==Shell.Revision
  and count==plot:GetAttribute('BaseShellPartCount') and plot:FindFirstChild('Roof')
  and plot:FindFirstChild('Laser') and plot:FindFirstChild('OwnerSign') then return plot end
 -- Asset loading can yield/fail. Complete it before removing the previous envelope.
 for _,def in ipairs(Data.Meshes) do prototype(def) end
 local cf=plot:GetPivot()
 local staging=Instance.new('Model')
 local function block(name,size,offset,color,material,alpha,collide,query)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf*CFrame.new(offset)
  p.Anchored=true;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
  p.Transparency=alpha or 0;p.CanCollide=collide==true;p.CanTouch=p.CanCollide;p.CanQuery=query==true
  p.CastShadow=p.Transparency<1
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
  defaults(p,p.Transparency,p.CanCollide,p.CanQuery);p.Parent=staging
  return p
 end
 for _,def in ipairs(Data.Meshes) do
  local p=prototype(def):Clone();p.Name=def.Name;p.Size=def.Size;p.CFrame=cf*def.LocalCF
  p.Color=def.Color;p.Material=Enum.Material.SmoothPlastic;p.Transparency=0
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=true
  p:SetAttribute('BlenderBaseVisual',true);defaults(p,0,false,false);p.Parent=staging
 end
 local gray=Color3.fromRGB(83,85,99)
 -- Visual mesh collision is disabled: explicit thin planes seal the three windows.
 for _,x in ipairs({-80,80}) do block('Perimeter',Vector3.new(2,28,160),Vector3.new(x,14,0),gray,nil,1,true,true) end
 block('Perimeter',Vector3.new(160,28,2),Vector3.new(0,14,80),gray,nil,1,true,true)
 block('RoofCollision',Vector3.new(162,1.8,162),Vector3.new(0,28.4,0),gray,nil,1,true,true)
 for _,x in ipairs({-76,76}) do for _,z in ipairs({-76,76}) do
  block('ColumnCollision',Vector3.new(7.8,28,7.8),Vector3.new(x,14,z),gray,nil,1,true,true)
 end end
 -- The central sixteen-stud route remains clear; the low sill matches the screenshot.
 for _,side in ipairs({-1,1}) do block('FrontSillCollision',Vector3.new(68,3.6,4),Vector3.new(side*42,1.8,-80),gray,nil,1,true,true) end
 local red=Color3.fromRGB(255,33,51)
 block('EntryStep',Vector3.new(20,.5,6),Vector3.new(0,-.75,-87),Color3.fromRGB(189,47,41),nil,0,true,true)
 block('EntryStep',Vector3.new(18,.5,4),Vector3.new(0,-.25,-83),Color3.fromRGB(216,54,47),nil,0,true,true)
 for _,x in ipairs({-48,48}) do for _,z in ipairs({-48,0,48}) do
  block('CeilingFixture',Vector3.new(7,.9,7),Vector3.new(x,26.8,z),Color3.fromRGB(40,43,54),nil,0,false,false)
  local diffuser=block('CeilingDiffuser',Vector3.new(5.5,.3,5.5),Vector3.new(x,26.23,z),Color3.fromRGB(255,242,235),Enum.Material.Neon,0,false,false)
  -- Diffusers are visible lighting details; no per-fixture dynamic lights are needed.
 end end
 local owned=(plot:GetAttribute('OwnerUserId') or 0)~=0
 local laser=block('Laser',Vector3.new(140,25,.5),Vector3.new(0,13.5,-80),red,Enum.Material.Neon,.92,false,true)
 laser:SetAttribute('Open',not owned)
 if not owned then laser.Transparency=1;laser.CanQuery=false end
 for x=-68,68,4 do
  local p=block('LaserBeam',Vector3.new(.48,25,.48),Vector3.new(x,13.5,-80),red,Enum.Material.Neon,0,false,true)
  if not owned then p.Transparency=1;p.CanQuery=false end
 end
 for _,p in ipairs(plot:GetChildren()) do
  if p:IsA('BasePart') and p.Name~='OwnerSign' and (p:GetAttribute('BaseShellPart') or legacy[p.Name]) then p:Destroy() end
 end
 for _,p in ipairs(staging:GetChildren()) do p.Parent=plot end
 staging:Destroy()
 -- Preserve floor identity, size and pivot; match the gray floor in the Blender design.
 local floor=plot:FindFirstChild('Floor')
 if floor and floor:IsA('BasePart') then floor.Color=Color3.fromRGB(92,95,109) end
 ownerSign(plot,cf);batteryDefaults(plot)
 count=0
 for _,p in ipairs(plot:GetChildren()) do if p:IsA('BasePart') and p:GetAttribute('BaseShellPart') then count+=1 end end
 plot:SetAttribute('BaseShellRevision',Shell.Revision)
 plot:SetAttribute('BaseShellGeneration',(plot:GetAttribute('BaseShellGeneration') or 0)+1)
 plot:SetAttribute('BaseShellPartCount',count);plot:SetAttribute('DefensesBuilt',true)
 return plot
end
return Shell
