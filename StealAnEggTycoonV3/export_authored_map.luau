-- Run in Edit through the Studio MCP. Native RBXM remains the exact snapshot.
-- JSON keeps session art as transparent pivots and permanent, nonphysical MeshParts
-- as MeshParts. These visual meshes rely on separate authored Part colliders.
assert(not game:GetService('RunService'):IsRunning(),'Exporte o mapa no modo Editar.')
local roots={}
for _,object in ipairs(workspace:GetChildren()) do
 if not object:IsA('Camera') and not object:IsA('Terrain') then table.insert(roots,object) end
end
local serialized=game:GetService('SerializationService'):SerializeInstancesAsync(roots)
-- Preserve access to the exact snapshot even if the portable representation is refused.
_G.EggTycoonMapExport={Serialized=serialized}
local list={}
for _,root in ipairs(roots) do
 table.insert(list,root)
 for _,object in ipairs(root:GetDescendants()) do table.insert(list,object) end
end
local ids={}
for i,object in ipairs(list) do ids[object]='MAP_'..i end
local function pack(value)
 local kind=typeof(value)
 if kind=='Instance' then return {Type='Ref',Value=ids[value] or 'null'} end
 if kind=='Vector3' then return {Type=kind,Value={value.X,value.Y,value.Z}} end
 if kind=='Vector2' then return {Type=kind,Value={value.X,value.Y}} end
 if kind=='CFrame' then return {Type=kind,Value={value:GetComponents()}} end
 if kind=='Color3' then return {Type=kind,Value={value.R,value.G,value.B}} end
 if kind=='UDim2' then return {Type=kind,Value={value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset}} end
 if kind=='UDim' then return {Type=kind,Value={value.Scale,value.Offset}} end
 if kind=='EnumItem' then return {Type='token',Value=value.Value} end
 if kind=='string' or kind=='number' or kind=='boolean' then return {Type=kind,Value=value} end
end
local function permanent(value)
 return type(value)=='string' and value:match('^rbxassetid://[1-9]%d*$')~=nil
end
local function finitePositive(vector)
 for _,v in ipairs({vector.X,vector.Y,vector.Z}) do
  if v~=v or v<=0 or v==math.huge then return false end
 end
 return true
end
local fields={'Name','Size','CFrame','Color','Material','MaterialVariant','Transparency','Reflectance','Anchored','CanCollide','CanTouch','CanQuery','CastShadow','Shape','TopSurface','BottomSurface','LeftSurface','RightSurface','FrontSurface','BackSurface','PrimaryPart','PivotOffset','StudsOffset','StudsOffsetWorldSpace','MaxDistance','AlwaysOnTop','Adornee','Text','TextColor3','TextSize','Font','TextStrokeTransparency','TextStrokeColor3','TextScaled','TextWrapped','TextXAlignment','TextYAlignment','BackgroundColor3','BackgroundTransparency','BorderSizePixel','AnchorPoint','Rotation','ZIndex','Visible','CornerRadius','Thickness','LightEmission','Brightness','Range','Value','ActionText','ObjectText','KeyboardKeyCode','GamepadKeyCode','MaxActivationDistance','HoldDuration','RequiresLineOfSight','ClickablePrompt','Style','Color3','ResetOnSpawn','PixelsPerStud','Face','Duration','Neutral','Enabled','Active','BaseMaterial','ColorMap','NormalMap','MetalnessMap','RoughnessMap','StudsPerTile','ModelStreamingMode'}
table.insert(fields,'SizingMode');table.insert(fields,'CanvasSize');table.insert(fields,'LightInfluence')
local meshFields={'MeshId','TextureID','DoubleSided','CollisionFidelity','RenderFidelity'}
local rows={}
local staticMeshes=0
local world=workspace:FindFirstChild('EggTycoonV3')
for i,object in ipairs(list) do
 assert(not object:IsA('LuaSourceContainer'),'Scripts no Workspace exigem exportação própria: '..object:GetFullName())
 assert(not object:IsA('UnionOperation'),'Use o snapshot RBXM nativo para preservar operações sólidas.')
 local mesh=object:IsA('MeshPart')
 local placeholder=false
 if mesh then
  local model=object:FindFirstAncestorOfClass('Model')
  placeholder=world and ((world:FindFirstChild('Guardians') and object:IsDescendantOf(world.Guardians))
   or (model and model.Name=='Egg' and model.Parent and model.Parent.Parent==world:FindFirstChild('Nests'))) or false
  if not placeholder then
   assert(permanent(object.MeshId),'Malha estática sem ID permanente: '..object:GetFullName())
   assert(object.TextureID=='' or permanent(object.TextureID),'Textura sem ID permanente: '..object:GetFullName())
   assert(object.Anchored and not object.CanCollide and not object.CanTouch,
    'A exportação JSON aceita apenas malhas visuais ancoradas, sem colisão/toque; mantenha colliders Part separados: '..object:GetFullName())
   assert(not object:FindFirstChildWhichIsA('Bone',true),'Malha com rig exige snapshot nativo: '..object:GetFullName())
   assert(not object:FindFirstChildWhichIsA('SurfaceAppearance',true),'SurfaceAppearance exige suporte próprio: '..object:GetFullName())
   local ok,skinned=pcall(function() return object.HasSkinnedMesh end)
   assert(not ok or not skinned,'Malha skinned exige snapshot nativo: '..object:GetFullName())
   assert(finitePositive(object.MeshSize),'Dimensões originais inválidas ou degeneradas: '..object:GetFullName())
   staticMeshes+=1
  end
 end
 local row={Id=ids[object],Class=placeholder and 'Part' or object.ClassName,Parent=ids[object.Parent],Properties={},Attributes={},Tags=object:GetTags()}
 for _,field in ipairs(fields) do
  local ok,value=pcall(function() return object[field] end)
  if ok then row.Properties[field]=pack(value) end
 end
 if mesh and not placeholder then
  for _,field in ipairs(meshFields) do row.Properties[field]=pack(object[field]) end
  -- MeshSize is the public read-only source extent. The native serializer stores
  -- that extent under InitialSize; using Size here would erase imported scaling.
  row.Properties.InitialSize=pack(object.MeshSize)
 end
 if object:IsA('GuiObject') then row.Properties.Position=pack(object.Position) end
 for name,value in pairs(object:GetAttributes()) do
  local kind=typeof(value)
  if kind=='string' or kind=='boolean' or kind=='number' then row.Attributes[name]=pack(value)
  else assert(placeholder and (name=='RestCF' or name=='AnimationJoint'),'Atributo não suportado no JSON: '..name) end
 end
 if placeholder then
  row.Attributes.SessionArtPlaceholder={Type='boolean',Value=true}
  row.Properties.Transparency={Type='number',Value=1}
  for _,field in ipairs({'CanCollide','CanTouch','CanQuery'}) do row.Properties[field]={Type='boolean',Value=false} end
 end
 table.insert(rows,row)
 if i%100==0 then task.wait() end
end
_G.EggTycoonMapExport={Rows=rows,Serialized=serialized,StaticMeshParts=staticMeshes}
return {Instances=#rows,NativeBytes=buffer.len(serialized),Roots=#roots,StaticMeshParts=staticMeshes}
