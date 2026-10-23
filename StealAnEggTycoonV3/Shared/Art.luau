local RS=game:GetService('ReplicatedStorage')
local AS=game:GetService('AssetService')
local C=require(script.Parent.Config)
local Data=require(script.Parent.GeometryData)
local A={}
local assets=script.Parent.Parent:WaitForChild('Assets')
local templates={}
local initialized=false
local function vec(a) return Vector3.new(a[1],a[2],a[3]) end
local function rgb(a) return Color3.new(a[1],a[2],a[3]) end
function A.Init()
 if initialized then return end
 for _,v in ipairs(assets:GetChildren()) do v:Destroy() end
 templates={}
 for name,d in pairs(Data.Meshes) do
  local e=AS:CreateEditableMesh()
  assert(e,'Não foi possível alocar malha: '..name)
  local ids={}
  for i,p in ipairs(d.Vertices) do ids[i]=e:AddVertex(vec(p)) end
  -- Blender split normals keep rounded toys smooth and broad faces flat.
  -- Existing meshes without authored normals retain their previous flat shading.
  local normals={}
  for i,n in ipairs(d.Normals or {}) do normals[i]=e:AddNormal(vec(n)) end
  for ti,t in ipairs(d.Triangles) do
   local f=e:AddTriangle(ids[t[1]],ids[t[2]],ids[t[3]])
   local authored=d.TriangleNormals and d.TriangleNormals[ti]
   if authored then
    e:SetFaceNormals(f,{assert(normals[authored[1]]),assert(normals[authored[2]]),assert(normals[authored[3]])})
   else
    local n=(vec(d.Vertices[t[2]])-vec(d.Vertices[t[1]])):Cross(vec(d.Vertices[t[3]])-vec(d.Vertices[t[1]]))
    if n.Magnitude>.00001 then local id=e:AddNormal(n.Unit) e:SetFaceNormals(f,{id,id,id}) end
   end
  end
  local result,content=AS:CreateDataModelContentAsync(Content.fromObject(e))
  assert(result==Enum.CreateContentResult.Success,'Conversão da malha falhou: '..tostring(result))
  local p=AS:CreateMeshPartAsync(content)
  p.Name=name p.Anchored=true p.CanCollide=false p.CanTouch=false p.CastShadow=true
  p.Material=Enum.Material.SmoothPlastic p.Parent=assets templates[name]=p e:Destroy()
  task.wait()
 end
 assets:SetAttribute('Revision',Data.Revision)
 initialized=true
end
-- Clients reuse the server's static meshes for placement previews. No assets are
-- generated, removed or uploaded here; bind only after the complete set arrived.
function A.UseReplicatedAssets()
 local replicated={}
 for name in pairs(Data.Meshes) do
  local mesh=assets:FindFirstChild(name)
  if not mesh or not mesh:IsA('MeshPart') then return false,'Malha ainda não carregada: '..name end
  replicated[name]=mesh
 end
 templates=replicated
 initialized=true
 return true
end
local function meshModel(name,cf,scale,parent)
 local defs=Data.Models[name] assert(defs,'Modelo ausente: '..name)
 local m=Instance.new('Model') m.Name=name m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 for _,d in ipairs(defs) do
  local p=templates[d.Mesh]:Clone() p.Name=d.Name
  local rc=CFrame.new(table.unpack(d.CF)); local orient=rc-rc.Position
  local size=vec(Data.Meshes[d.Mesh].Size)
  p.Size=Vector3.new(math.abs(size.X*d.Scale[1]*scale),math.abs(size.Y*d.Scale[2]*scale),math.abs(size.Z*d.Scale[3]*scale))
  p.CFrame=cf*CFrame.new(rc.Position*scale)*orient
  p.Color=rgb(d.Color) p.Material=d.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
  p:SetAttribute('RestCF',CFrame.new(rc.Position*scale)*orient)
  p.Parent=m
 end
 local body=m:FindFirstChild('Body') or m:FindFirstChildWhichIsA('BasePart')
 if body then body.PivotOffset=body.CFrame:ToObjectSpace(cf) m.PrimaryPart=body end
 m.Parent=parent return m
end
function A.Creature(index,cf,scale,parent)
 local adult=scale>=1.7
 local key=(adult and 'Guardian_' or 'Species_')..index
 local m=meshModel(key,cf,adult and scale/2 or scale,parent)
 m:SetAttribute('ArtCreature',true) m:SetAttribute('Species',index) m:SetAttribute('Adult',adult)
 if Data.ModelRevisions and Data.ModelRevisions[key] then m:SetAttribute('ArtRevision',Data.ModelRevisions[key]) end
 return m
end
function A.Egg(index,cf,scale,parent)
 local m=meshModel('Egg',cf,scale,parent) m.Name='Egg'
 for _,p in ipairs(m:GetChildren()) do if p:IsA('BasePart') and p.Name=='Spot' then p.Color=C.Species[index].Color end end
 return m
end
function A.Prop(name,cf,scale,parent) return meshModel(name,cf,scale,parent) end
function A.Part(parent,name,size,cf,color,material,collide)
 local p=Instance.new('Part') p.Name=name p.Size=size p.CFrame=cf p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic p.Anchored=true p.CanCollide=collide==true
 p.CanTouch=collide==true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
function A.Label(parent,part,title,subtitle,color,distance)
 local gui=Instance.new('BillboardGui') gui.Name='Label' gui.Adornee=part gui.Size=UDim2.fromOffset(210,66)
 gui.StudsOffsetWorldSpace=Vector3.new(0,4,0) gui.MaxDistance=distance or 100 gui.AlwaysOnTop=false gui.Parent=part
 local t=Instance.new('TextLabel') t.Name='Text' t.Size=UDim2.fromScale(1,1) t.BackgroundTransparency=1
 t.Font=Enum.Font.GothamBold t.TextSize=20 t.TextColor3=color or Color3.new(1,1,1) t.TextStrokeTransparency=.25
 t.Text=title..(subtitle and ('\n'..subtitle) or '') t.Parent=gui return gui
end
local steel=Color3.fromRGB(48,66,83)
function A.Structure(kind,cf,parent)
 local item=C.Items[kind] assert(item,'Tipo desconhecido: '..tostring(kind))
 local m=Instance.new('Model') m.Name=kind
 local pad=A.Part(m,'Main',Vector3.new(item.W,.45,item.D),cf*CFrame.new(0,.225,0),item.Color,Enum.Material.SmoothPlastic,true)
 pad.PivotOffset=pad.CFrame:ToObjectSpace(cf) m.PrimaryPart=pad
 if kind=='Habitat' then
  A.Part(m,'Grass',Vector3.new(22,.2,22),cf*CFrame.new(0,.55,0),Color3.fromRGB(125,215,103),Enum.Material.Grass,false)
  for _,x in ipairs({-11.5,11.5}) do A.Part(m,'Fence',Vector3.new(.5,2.2,23),cf*CFrame.new(x,1.5,0),Color3.fromRGB(173,110,56),nil,true) end
  A.Part(m,'Fence',Vector3.new(23,2.2,.5),cf*CFrame.new(0,1.5,11.5),Color3.fromRGB(173,110,56),nil,true)
  for _,x in ipairs({-8,8}) do A.Part(m,'Fence',Vector3.new(7,2.2,.5),cf*CFrame.new(x,1.5,-11.5),Color3.fromRGB(173,110,56),nil,true) end
  A.Part(m,'ResourceOutlet',Vector3.new(4,.5,4),cf*CFrame.new(0,1,-12),Color3.fromRGB(255,212,69),Enum.Material.Metal,false)
 elseif kind=='Processor' or kind=='Seller' then
  local shell=meshModel('MachineShell',cf*CFrame.new(0,.5,0),1.35,m)
  for _,v in ipairs(shell:GetDescendants()) do if v:IsA('BasePart') and v.Name=='Top' then v.Color=item.Color end end
  A.Label(m,pad,item.Name,kind=='Processor' and 'REFINA RECURSOS' or 'VENDA AUTOMÁTICA',item.Color,65)
 elseif kind=='Incubator' then
  local core=meshModel('IncubatorCore',cf*CFrame.new(0,.5,0),1.15,m)
  for _,v in ipairs(core:GetDescendants()) do if v:IsA('BasePart') and v.Name=='Glass' then v.Transparency=.55 v.Material=Enum.Material.Glass end end
  A.Label(m,pad,'INCUBADORA','ENTREGUE SEU OVO',item.Color,65)
 else
  pad.Color=steel
  A.Part(m,'Track',Vector3.new(3.1,.15,3.7),cf*CFrame.new(0,.55,0),Color3.fromRGB(33,43,57),nil,false)
  for _,x in ipairs({-1.8,1.8}) do A.Part(m,'Rail',Vector3.new(.18,.55,4),cf*CFrame.new(x,.65,0),item.Color,Enum.Material.Metal,false) end
  for z=-1,1 do A.Part(m,'Slat',Vector3.new(3,.08,.16),cf*CFrame.new(0,.67,z),Color3.fromRGB(114,135,153),nil,false) end
  local ar=A.Part(m,'Direction',Vector3.new(.25,.08,1.5),cf*CFrame.new(0,.8,0),Color3.fromRGB(255,213,76),Enum.Material.Neon,false)
  for s=-1,1,2 do A.Part(m,'Arrow',Vector3.new(.2,.08,.8),cf*CFrame.new(s*.23,.8,-.5)*CFrame.Angles(0,s*.6,0),Color3.fromRGB(255,213,76),Enum.Material.Neon,false) end
  if kind~='Belt' then A.Label(m,ar,kind=='Curve' and '↱' or '↑',nil,Color3.fromRGB(255,213,76),22) end
 end
 m.Parent=parent return m
end
return A
