-- Run in Edit through the Studio MCP. Read Rows in bounded JSON batches and
-- Serialized in bounded hexadecimal batches; write Map/scene.json + AuthoredMap.rbxm.
-- Native RBXM preserves the complete authored scene; JSON uses transparent pivots
-- for session mesh parts, which WorldFactory renews from Blender geometry in Play.
assert(not game:GetService('RunService'):IsRunning(),'Exporte o mapa no modo Editar.')
local roots={}
for _,object in ipairs(workspace:GetChildren()) do
 if not object:IsA('Camera') and not object:IsA('Terrain') then table.insert(roots,object) end
end
local serialized=game:GetService('SerializationService'):SerializeInstancesAsync(roots)
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
local fields={'Name','Size','CFrame','Color','Material','MaterialVariant','Transparency','Reflectance','Anchored','CanCollide','CanTouch','CanQuery','CastShadow','Shape','TopSurface','BottomSurface','LeftSurface','RightSurface','FrontSurface','BackSurface','PrimaryPart','PivotOffset','StudsOffset','StudsOffsetWorldSpace','MaxDistance','AlwaysOnTop','Adornee','Text','TextColor3','TextSize','Font','TextStrokeTransparency','TextStrokeColor3','TextScaled','TextWrapped','TextXAlignment','TextYAlignment','BackgroundColor3','BackgroundTransparency','BorderSizePixel','AnchorPoint','Rotation','ZIndex','Visible','CornerRadius','Thickness','LightEmission','Brightness','Range','Value','ActionText','ObjectText','KeyboardKeyCode','GamepadKeyCode','MaxActivationDistance','HoldDuration','RequiresLineOfSight','ClickablePrompt','Style','Color3','ResetOnSpawn','PixelsPerStud','Face','Duration','Neutral','Enabled','Active','BaseMaterial','ColorMap','NormalMap','MetalnessMap','RoughnessMap','StudsPerTile','ModelStreamingMode'}
local rows={}
for i,object in ipairs(list) do
 local placeholder=object:IsA('MeshPart')
 if placeholder then
  local world=workspace:FindFirstChild('EggTycoonV3')
  local model=object:FindFirstAncestorOfClass('Model')
  local sessionArt=world and (object:IsDescendantOf(world.Guardians) or (model and model.Name=='Egg' and model.Parent and model.Parent.Parent==world.Nests))
  assert(sessionArt,'Mesh decorativo exige exportação própria; snapshot RBXM preservado: '..object:GetFullName())
 end
 assert(not object:IsA('UnionOperation'),'Use o snapshot RBXM nativo para preservar operações sólidas.')
 local row={Id=ids[object],Class=placeholder and 'Part' or object.ClassName,Parent=ids[object.Parent],Properties={},Attributes={},Tags=object:GetTags()}
 for _,field in ipairs(fields) do
  local ok,value=pcall(function() return object[field] end)
  if ok then row.Properties[field]=pack(value) end
 end
 if object:IsA('GuiObject') then row.Properties.Position=pack(object.Position) end
 for name,value in pairs(object:GetAttributes()) do
  local kind=typeof(value)
  if kind=='string' or kind=='boolean' or kind=='number' then row.Attributes[name]=pack(value)
  else assert(placeholder and name=='RestCF','Atributo não suportado no JSON: '..name) end
 end
 if placeholder then
  row.Attributes.SessionArtPlaceholder={Type='boolean',Value=true}
  row.Properties.Transparency={Type='number',Value=1}
  for _,field in ipairs({'CanCollide','CanTouch','CanQuery'}) do row.Properties[field]={Type='boolean',Value=false} end
 end
 table.insert(rows,row)
 if i%100==0 then task.wait() end
end
_G.EggTycoonMapExport={Rows=rows,Serialized=serialized}
return {Instances=#rows,NativeBytes=buffer.len(serialized),Roots=#roots}
