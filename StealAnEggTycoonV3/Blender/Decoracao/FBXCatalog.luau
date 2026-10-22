-- Adopt only a dedicated FBX import. Geometry and normals remain in the native
-- imported MeshParts; this module never generates or republishes a mesh asset.
-- Adopt(importedModel, definition) -> the same Model, permanent asset manifest.
local CollectionService=game:GetService("CollectionService")
local Catalog={}
local inputBasis="FBX -Z/Y -> JSON XZ-Y; yaw pi validated"
local importYaw=CFrame.Angles(0,math.pi,0)

local function finite(value)
 return type(value)=="number" and value==value and math.abs(value)<math.huge
end
local function point(value,label)
 assert(type(value)=="table" and #value==3,label..": expected three numbers")
 for _,v in ipairs(value) do assert(finite(v) and math.abs(v)<=10000,label..": invalid number") end
 return Vector3.new(value[1],value[2],value[3])
end
local function include(lo,hi,v)
 return Vector3.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z)),
  Vector3.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
end
local function array(v) return {v.X,v.Y,v.Z} end
local function assetIdFromUri(uri)
 if type(uri)~="string" then return nil end
 local id=tonumber(uri:match("^rbxassetid://(%d+)$") or uri:match("[?&]id=(%d+)"))
 return id and id>0 and id%1==0 and id or nil
end
local function categoryText(definition)
 local text=string.lower(definition.Category.." "..definition.Id.." "..definition.Name)
 for accented,plain in pairs({["á"]="a",["Á"]="a",["ã"]="a",["Ã"]="a",["â"]="a",["Â"]="a",["é"]="e",["É"]="e",["ê"]="e",["Ê"]="e",["í"]="i",["Í"]="i",["ó"]="o",["Ó"]="o",["ô"]="o",["Ô"]="o",["õ"]="o",["Õ"]="o",["ú"]="u",["Ú"]="u",["ç"]="c",["Ç"]="c"}) do text=text:gsub(accented,plain) end
 return text
end
local function hasAny(text,words)
 for _,word in ipairs(words) do if text:find(word,1,true) then return true end end
 return false
end
local function colliderPlan(definition,lo,hi)
 local size=hi-lo
 local category=categoryText(definition)
 if hasAny(category,{"cacto","cactus"}) then
  local dimensions=Vector3.new(math.max(.2,math.min(1.6,size.X*.28)),math.max(.25,size.Y*.8),math.max(.2,math.min(1.6,size.Z*.28)))
  return {Kind="CactusCore",Size=dimensions,Center=Vector3.new(0,lo.Y+dimensions.Y*.5,0)}
 elseif hasAny(category,{"arvor","tree","palmeira","pinheiro","carvalho","bananeira"}) then
  local height=math.max(.25,size.Y*.5)
  return {Kind="Trunk",Size=Vector3.new(1.6,height,1.6),Center=Vector3.new(0,lo.Y+height*.5,0)}
 elseif hasAny(category,{"rocha","pedra","rock","boulder","stone"}) then
  return {Kind="RockCore",Size=Vector3.new(math.max(.1,size.X*.8),math.max(.1,size.Y*.8),math.max(.1,size.Z*.8)),Center=(lo+hi)*.5}
 end
 -- Logs, bushes, mushrooms, flowers and other small props stay non-colliding.
 return nil
end

function Catalog.Adopt(importedModel,definition)
 assert(typeof(importedModel)=="Instance" and importedModel:IsA("Model"),"Adopt expects the dedicated imported Model")
 assert(type(definition)=="table","Missing Blender model definition")
 for _,key in ipairs({"Id","Name","Biome","Category"}) do assert(type(definition[key])=="string" and definition[key]~="","Missing "..key) end
 assert(type(definition.Parts)=="table" and #definition.Parts>0,"Missing Blender parts")
 assert(not importedModel:GetAttribute("FBXCatalogAdopted"),"This model was already adopted; preserve it and import a fresh copy")
 local meshes={};local meshCount=0
 for _,object in ipairs(importedModel:GetDescendants()) do
  assert(not object:IsA("LuaSourceContainer"),"FBX model unexpectedly contains executable code: "..object:GetFullName())
  if object:IsA("MeshPart") then
   assert(not meshes[object.Name],"Duplicate FBX mesh name: "..object.Name)
   meshes[object.Name]=object;meshCount+=1
  elseif object:IsA("BasePart") then
   error("Dedicated FBX import contains a non-mesh part: "..object:GetFullName())
  end
 end
 assert(meshCount==#definition.Parts,string.format("FBX mesh count mismatch for %s: got %d, expected %d",definition.Id,meshCount,#definition.Parts))
 assert(not importedModel:FindFirstChild("Pivot"),"FBX model already has an object named Pivot")
 local plans={};local names={}
 local minimum=Vector3.new(math.huge,math.huge,math.huge);local maximum=-minimum
 -- All names, published IDs, dimensions and colors are checked before mutation.
 for index,part in ipairs(definition.Parts) do
  local label=definition.Id..".Parts["..index.."]"
  assert(type(part)=="table" and type(part.Name)=="string" and part.Name~="",label..": missing Name")
  assert(not names[part.Name],label..": duplicate Blender name "..part.Name);names[part.Name]=true
  local mesh=meshes[part.Name];assert(mesh,"Exact FBX mesh name missing: "..part.Name)
  local meshId=mesh.MeshId
  local publishedId=assetIdFromUri(meshId)
  assert(publishedId,label..": imported mesh does not reference a permanent asset ID")
  assert(type(part.Glow)=="boolean" and type(part.Collision)=="boolean",label..": missing original booleans")
  local color=point(part.Color,label..".Color")
  assert(color.X>=0 and color.X<=1 and color.Y>=0 and color.Y<=1 and color.Z>=0 and color.Z<=1,label..": Color must contain sRGB values in 0..1")
  local lo,hi
  if part.Bounds~=nil then
   assert(type(part.Bounds)=="table",label..": Bounds must be an object")
   lo=point(part.Bounds.Min,label..".Bounds.Min");hi=point(part.Bounds.Max,label..".Bounds.Max")
   assert(lo.X<=hi.X and lo.Y<=hi.Y and lo.Z<=hi.Z,label..": Bounds.Min must not exceed Bounds.Max")
  else
   assert(type(part.Vertices)=="table" and #part.Vertices>=3,label..": missing Vertices or Bounds")
   lo=Vector3.new(math.huge,math.huge,math.huge);hi=-lo
   for vi,v in ipairs(part.Vertices) do lo,hi=include(lo,hi,point(v,label..".Vertices["..vi.."]")) end
  end
  minimum,maximum=include(minimum,maximum,lo);minimum,maximum=include(minimum,maximum,hi)
  local size=hi-lo
  assert(size.X>=.001 and size.Y>=.001 and size.Z>=.001,label..": degenerate bounding box")
  table.insert(plans,{Mesh=mesh,Definition=part,MeshId=meshId,AssetId=publishedId,Size=size,Center=(lo+hi)*.5,
   Color=Color3.fromRGB(math.round(color.X*255),math.round(color.Y*255),math.round(color.Z*255))})
 end
 local collision=colliderPlan(definition,minimum,maximum)
 local manifest={Id=definition.Id,Name=definition.Name,Biome=definition.Biome,Category=definition.Category,
  Origin="Blender",Permanent=true,InputBasis=inputBasis,Parts={},Bounds={Min=array(minimum),Max=array(maximum),Size=array(maximum-minimum)}}
 -- Keep a rollback snapshot for unlikely property errors. Existing models, mesh
 -- assets, surfaces, import packages and native vertex normals are never deleted.
 local before={Name=importedModel.Name,PrimaryPart=importedModel.PrimaryPart,Attributes=importedModel:GetAttributes(),
  Tags=importedModel:GetTags(),WorldPivot=importedModel.WorldPivot,Meshes={}}
 for _,plan in ipairs(plans) do
  local mesh=plan.Mesh
  table.insert(before.Meshes,{Object=mesh,Size=mesh.Size,CFrame=mesh.CFrame,Color=mesh.Color,Material=mesh.Material,
   Anchored=mesh.Anchored,CanCollide=mesh.CanCollide,CanTouch=mesh.CanTouch,CanQuery=mesh.CanQuery,
   Attributes=mesh:GetAttributes(),Tags=mesh:GetTags()})
 end
 local created={}
 local ok,err=xpcall(function()
  for _,plan in ipairs(plans) do
   local mesh,part=plan.Mesh,plan.Definition
   mesh.Size=plan.Size;mesh.CFrame=CFrame.new(plan.Center)*importYaw
   mesh.Color=plan.Color;mesh.Material=part.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
   mesh.Anchored=true;mesh.CanCollide=false;mesh.CanTouch=false;mesh.CanQuery=true
   mesh:SetAttribute("DecorationId",definition.Id);mesh:SetAttribute("OriginalCollision",part.Collision)
   mesh:SetAttribute("OriginalGlow",part.Glow);mesh:SetAttribute("PublishedMeshId",plan.AssetId)
   CollectionService:AddTag(mesh,"OrigemBlender")
   assert(mesh.MeshId==plan.MeshId,"Native imported mesh ID changed unexpectedly")
   table.insert(manifest.Parts,{Name=part.Name,MeshId=plan.MeshId,AssetId=plan.AssetId,Color=array(Vector3.new(plan.Color.R,plan.Color.G,plan.Color.B)),
    Size=array(plan.Size),Center=array(plan.Center),YawRadians=math.pi,CFrame={mesh.CFrame:GetComponents()},Glow=part.Glow,Collision=part.Collision})
  end
  local pivot=Instance.new("Part");table.insert(created,pivot)
  pivot.Name="Pivot";pivot.Size=Vector3.new(.1,.1,.1);pivot.CFrame=CFrame.identity
  pivot.Anchored=true;pivot.Transparency=1;pivot.CanCollide=false;pivot.CanTouch=false;pivot.CanQuery=false;pivot.CastShadow=false
  pivot:SetAttribute("DecorationPivot",true);pivot.Parent=importedModel
  importedModel.PrimaryPart=pivot
  if collision then
   local part=Instance.new("Part");table.insert(created,part)
   part.Name="Collider_"..collision.Kind;part.Size=collision.Size;part.CFrame=CFrame.new(collision.Center)
   part.Anchored=true;part.Transparency=1;part.CanCollide=true;part.CanTouch=false;part.CanQuery=false;part.CastShadow=false
   part:SetAttribute("DecorationCollider",true);part:SetAttribute("CollisionKind",collision.Kind);part.Parent=importedModel
   manifest.Collider={Kind=collision.Kind,Size=array(collision.Size),Center=array(collision.Center)}
  end
  importedModel.Name=definition.Id
  importedModel:SetAttribute("Nome",definition.Name);importedModel:SetAttribute("Bioma",definition.Biome)
  importedModel:SetAttribute("DecorationId",definition.Id);importedModel:SetAttribute("Category",definition.Category)
  importedModel:SetAttribute("OrigemBlender",true);importedModel:SetAttribute("PermanentMeshes",true)
  importedModel:SetAttribute("InputBasis",inputBasis)
  importedModel:SetAttribute("FBXCatalogAdopted",true);CollectionService:AddTag(importedModel,"OrigemBlender")
 end,debug.traceback)
 if not ok then
  for _,object in ipairs(created) do object:Destroy() end
  for _,saved in ipairs(before.Meshes) do
   local mesh=saved.Object
   for _,key in ipairs({"Size","CFrame","Color","Material","Anchored","CanCollide","CanTouch","CanQuery"}) do mesh[key]=saved[key] end
   for key in pairs(mesh:GetAttributes()) do if saved.Attributes[key]==nil then mesh:SetAttribute(key,nil) end end
   for key,value in pairs(saved.Attributes) do mesh:SetAttribute(key,value) end
   for _,tag in ipairs(mesh:GetTags()) do if not table.find(saved.Tags,tag) then CollectionService:RemoveTag(mesh,tag) end end
  end
  importedModel.Name=before.Name;importedModel.PrimaryPart=before.PrimaryPart;importedModel.WorldPivot=before.WorldPivot
  for key in pairs(importedModel:GetAttributes()) do if before.Attributes[key]==nil then importedModel:SetAttribute(key,nil) end end
  for key,value in pairs(before.Attributes) do importedModel:SetAttribute(key,value) end
  for _,tag in ipairs(importedModel:GetTags()) do if not table.find(before.Tags,tag) then CollectionService:RemoveTag(importedModel,tag) end end
  error("FBX adoption rolled back: "..tostring(err),2)
 end
 return importedModel,manifest
end

return Catalog
