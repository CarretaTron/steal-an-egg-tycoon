-- Standalone Blender decoration bridge. No dependency on the tycoon Art/WorldFactory.
-- BuildOne(definition, existingAssetIds?, publish?) -> unparented Model, asset IDs, stats.
-- With publish=false, missing asset IDs produce SESSION-ONLY previews.
-- A failed build destroys only its own new instances. Successful upload IDs remain
-- in Builder.Published[definition.Id] so a retry can reuse them without uploading again.
local AssetService=game:GetService("AssetService")
local CollectionService=game:GetService("CollectionService")
local HttpService=game:GetService("HttpService")
local Builder={Published={}}

local function finite(value)
 return type(value)=="number" and value==value and math.abs(value)<math.huge
end
local function vector(value,label)
 assert(type(value)=="table" and #value==3,label..": expected three numbers")
 for _,component in ipairs(value) do assert(finite(component) and math.abs(component)<=10000,label..": invalid component") end
 return Vector3.new(value[1],value[2],value[3])
end
local function include(minimum,maximum,point)
 return Vector3.new(math.min(minimum.X,point.X),math.min(minimum.Y,point.Y),math.min(minimum.Z,point.Z)),
  Vector3.new(math.max(maximum.X,point.X),math.max(maximum.Y,point.Y),math.max(maximum.Z,point.Z))
end
local function array(v) return {v.X,v.Y,v.Z} end
local function safeAssetId(value)
 return type(value)=="number" and finite(value) and value>0 and value%1==0
end
local function categoryText(definition)
 local text=string.lower(tostring(definition.Category).." "..tostring(definition.Id).." "..tostring(definition.Name))
 for accented,plain in pairs({["á"]="a",["Á"]="a",["ã"]="a",["Ã"]="a",["â"]="a",["Â"]="a",["é"]="e",["É"]="e",["ê"]="e",["Ê"]="e",["í"]="i",["Í"]="i",["ó"]="o",["Ó"]="o",["ô"]="o",["Ô"]="o",["õ"]="o",["Õ"]="o",["ú"]="u",["Ú"]="u",["ç"]="c",["Ç"]="c"}) do text=text:gsub(accented,plain) end
 return text
end
local function hasAny(text,words)
 for _,word in ipairs(words) do if text:find(word,1,true) then return true end end
 return false
end
local function colliderFor(model,definition,minimum,maximum)
 local size=maximum-minimum
 local center=(minimum+maximum)*.5
 local kind=categoryText(definition)
 local colliderSize,colliderCenter,collisionKind
 if hasAny(kind,{"arvor","tree","palmeira","pinheiro","carvalho","bananeira"}) then
  local height=math.max(.25,size.Y*.5)
  colliderSize=Vector3.new(1.6,height,1.6)
  colliderCenter=Vector3.new(0,minimum.Y+height*.5,0)
  collisionKind="Trunk"
 elseif hasAny(kind,{"cacto","cactus"}) then
  colliderSize=Vector3.new(math.max(.2,math.min(1.6,size.X*.28)),math.max(.25,size.Y*.8),math.max(.2,math.min(1.6,size.Z*.28)))
  colliderCenter=Vector3.new(0,minimum.Y+colliderSize.Y*.5,0)
  collisionKind="CactusCore"
 elseif hasAny(kind,{"pedra","rock","boulder","stone"}) then
  colliderSize=Vector3.new(math.max(.1,size.X*.8),math.max(.1,size.Y*.8),math.max(.1,size.Z*.8))
  colliderCenter=center
  collisionKind="RockCore"
 else return nil end
 local part=Instance.new("Part")
 part.Name="Collider_"..collisionKind
 part.Size=colliderSize;part.CFrame=CFrame.new(colliderCenter)
 part.Anchored=true;part.Transparency=1;part.CanCollide=true;part.CanTouch=false;part.CanQuery=false;part.CastShadow=false
 part:SetAttribute("DecorationCollider",true);part:SetAttribute("CollisionKind",collisionKind)
 part.Parent=model
 return part
end

function Builder.BuildOne(definition,publishedEntry,publish)
 assert(type(definition)=="table","Expected model definition")
 for _,key in ipairs({"Id","Name","Biome","Category"}) do assert(type(definition[key])=="string" and definition[key]~="","Missing "..key) end
 assert(type(definition.Parts)=="table" and #definition.Parts>0,"Missing model parts")
 assert(publishedEntry==nil or type(publishedEntry)=="table","Invalid published entry")
 local groups={Solid={Name="Solid",Parts={},Vertices=0,Triangles=0},Glow={Name="Glow",Parts={},Vertices=0,Triangles=0}}
 local minimum=Vector3.new(math.huge,math.huge,math.huge)
 local maximum=-minimum
 local metadata={}
 -- Validate before allocation/publication so malformed input cannot create assets.
 for index,part in ipairs(definition.Parts) do
  local label=definition.Id..".Parts["..index.."]"
  assert(type(part)=="table" and type(part.Name)=="string",label..": missing Name")
  assert(type(part.Glow)=="boolean" and type(part.Collision)=="boolean",label..": missing source booleans")
  assert(type(part.Vertices)=="table" and #part.Vertices>=3,label..": missing vertices")
  assert(type(part.Triangles)=="table" and #part.Triangles>0,label..": missing triangles")
  local color=vector(part.Color,label..".Color")
  assert(color.X>=0 and color.X<=1 and color.Y>=0 and color.Y<=1 and color.Z>=0 and color.Z<=1,label..": color outside 0..1")
  local points={}
  for vi,point in ipairs(part.Vertices) do
   local position=vector(point,label..".Vertices["..vi.."]")
   points[vi]=position
   minimum,maximum=include(minimum,maximum,position)
  end
  for ti,triangle in ipairs(part.Triangles) do
   assert(type(triangle)=="table" and #triangle==3,label..": invalid triangle "..ti)
   for _,vi in ipairs(triangle) do assert(type(vi)=="number" and vi%1==0 and vi>=1 and vi<=#points,label..": triangle index out of range") end
   local a,b,c=points[triangle[1]],points[triangle[2]],points[triangle[3]]
   assert((b-a):Cross(c-a).Magnitude>1e-8,label..": degenerate triangle "..ti)
  end
  local group=part.Glow and groups.Glow or groups.Solid
  table.insert(group.Parts,{Definition=part,Points=points,Color=Color3.new(color.X,color.Y,color.Z)})
  group.Vertices+=#points;group.Triangles+=#part.Triangles
  table.insert(metadata,{Name=part.Name,Glow=part.Glow,Collision=part.Collision})
 end
 for _,name in ipairs({"Solid","Glow"}) do
  local group=groups[name]
  assert(group.Vertices<=60000 and group.Triangles<=20000,definition.Id..": EditableMesh budget exceeded in "..name)
 end
 local entry=publishedEntry or {}
 Builder.Published[definition.Id]=entry
 local editable={}
 local model
 local ok,result,stats=xpcall(function()
  model=Instance.new("Model");model.Name=definition.Name
  model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  model:SetAttribute("DecorationId",definition.Id)
  model:SetAttribute("Biome",definition.Biome);model:SetAttribute("Category",definition.Category)
  model:SetAttribute("Origem","Blender");model:SetAttribute("SourceParts",HttpService:JSONEncode(metadata))
  model:SetAttribute("SourcePartsCount",#definition.Parts)
  CollectionService:AddTag(model,"OrigemBlender")
  local pivot=Instance.new("Part");pivot.Name="Pivot"
  pivot.Size=Vector3.new(.1,.1,.1);pivot.CFrame=CFrame.identity
  pivot.Transparency=1;pivot.Anchored=true;pivot.CanCollide=false;pivot.CanTouch=false;pivot.CanQuery=false;pivot.CastShadow=false
  pivot.Parent=model;model.PrimaryPart=pivot
  local summary={Id=definition.Id,SourceParts=#definition.Parts,MeshParts=0,Vertices=0,Triangles=0,Groups={},Permanent=true,
   Bounds={Min=array(minimum),Max=array(maximum),Size=array(maximum-minimum)}}
  for _,name in ipairs({"Solid","Glow"}) do
   local group=groups[name]
   if #group.Parts==0 then continue end
   local lo=Vector3.new(math.huge,math.huge,math.huge);local hi=-lo
   for _,part in ipairs(group.Parts) do for _,point in ipairs(part.Points) do lo,hi=include(lo,hi,point) end end
   local center=(lo+hi)*.5;local size=hi-lo
   local assetId=entry[name]
   local content
   if not publish and safeAssetId(assetId) then
    content=Content.fromAssetId(assetId)
   else
    local mesh=AssetService:CreateEditableMesh()
    assert(mesh,"Unable to allocate EditableMesh for "..definition.Id.."/"..name)
    editable[mesh]=true
    local operations=0
    local function yieldBatch()
     operations+=1
     if operations%1000==0 then task.wait() end
    end
    for _,part in ipairs(group.Parts) do
     local vertexIds={}
     for i,point in ipairs(part.Points) do vertexIds[i]=mesh:AddVertex(point-center);yieldBatch() end
     local colorId=mesh:AddColor(part.Color,1)
     for _,triangle in ipairs(part.Definition.Triangles) do
      local face=mesh:AddTriangle(vertexIds[triangle[1]],vertexIds[triangle[2]],vertexIds[triangle[3]])
      local a,b,c=part.Points[triangle[1]],part.Points[triangle[2]],part.Points[triangle[3]]
      local normalId=mesh:AddNormal((b-a):Cross(c-a).Unit)
      mesh:SetFaceNormals(face,{normalId,normalId,normalId})
      mesh:SetFaceColors(face,{colorId,colorId,colorId})
      yieldBatch()
     end
    end
    if publish then
     local status,idOrError=AssetService:CreateAssetAsync(mesh,Enum.AssetType.Mesh,{
      Name="Egg Tycoon Decor "..definition.Id..(name=="Glow" and " Glow" or ""),
      Description="Original Blender decoration",
     })
     assert(status==Enum.CreateAssetResult.Success,"Mesh upload failed for "..definition.Id.."/"..name..": "..tostring(status).." "..tostring(idOrError))
     assert(safeAssetId(idOrError),"Upload returned an invalid mesh asset ID")
     assetId=idOrError;entry[name]=assetId
     content=Content.fromAssetId(assetId)
    else
     local status,sessionContent=AssetService:CreateDataModelContentAsync(Content.fromObject(mesh))
     assert(status==Enum.CreateContentResult.Success,"Session preview conversion failed: "..tostring(status))
     content=sessionContent;summary.Permanent=false
    end
   end
   local part=AssetService:CreateMeshPartAsync(content)
   part.Parent=model -- The model is unparented; cleanup also covers property errors.
   part.Name=name=="Glow" and "DetalhesLuminosos" or "Decoracao"
   part.Size=Vector3.new(math.max(.01,size.X),math.max(.01,size.Y),math.max(.01,size.Z))
   part.CFrame=CFrame.new(center);part.Color=Color3.new(1,1,1)
   part.Anchored=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=true;part.CastShadow=true;part.DoubleSided=true
   part.Material=name=="Glow" and Enum.Material.Neon or Enum.Material.SmoothPlastic
   part:SetAttribute("DecorationId",definition.Id);part:SetAttribute("Glow",name=="Glow")
   part:SetAttribute("SourcePartCount",#group.Parts)
   if safeAssetId(assetId) then part:SetAttribute("PublishedMeshId",assetId) end
   CollectionService:AddTag(part,"OrigemBlender")
   summary.MeshParts+=1;summary.Vertices+=group.Vertices;summary.Triangles+=group.Triangles
   table.insert(summary.Groups,{Name=name,Vertices=group.Vertices,Triangles=group.Triangles,AssetId=assetId})
   -- The MeshPart owns static or published content now. Release editable memory.
   for mesh in pairs(editable) do mesh:Destroy();editable[mesh]=nil end
   task.wait()
  end
  local collider=colliderFor(model,definition,minimum,maximum)
  summary.Collider=collider and collider:GetAttribute("CollisionKind") or "None"
  model:SetAttribute("PermanentMeshes",summary.Permanent)
  model:SetAttribute("SessionPreviewOnly",not summary.Permanent)
  return model,summary
 end,debug.traceback)
 for mesh in pairs(editable) do pcall(function() mesh:Destroy() end) end
 if not ok then
  if model then model:Destroy() end
  error(tostring(result).."\nSuccessful upload IDs retained in Builder.Published["..definition.Id.."]: "..HttpService:JSONEncode(entry),2)
 end
 return result,entry,stats
end

return Builder
