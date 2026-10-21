-- Local mission guidance; the server remains authoritative over every interaction.
local Players=game:GetService('Players')
local GuiService=game:GetService('GuiService')
local Guide={}
Guide.__index=Guide

local function make(class,properties,parent)
 local object=Instance.new(class)
 for key,value in pairs(properties) do object[key]=value end
 object.Parent=parent
 return object
end
local function outlined(parent,text,size,position,dimensions)
 local label=make('TextLabel',{BackgroundTransparency=1,Text=text,TextColor3=Color3.new(1,1,1),
  Font=Enum.Font.FredokaOne,TextSize=size,TextWrapped=true,Position=position,Size=dimensions},parent)
 make('UIStroke',{Color=Color3.fromRGB(15,19,24),Thickness=2.5},label)
 return label
end
function Guide.new(options)
 local self=setmetatable({Gui=options.Gui,Config=options.Config,Active=false,WasOpen=false},Guide)
 local marker=make('Frame',{Name='SetaMissao',BackgroundTransparency=1,Size=UDim2.fromOffset(160,75),AnchorPoint=Vector2.new(.5,.5),Visible=false,ZIndex=9},self.Gui)
 self.Marker=marker
 self.Arrow=make('Frame',{Name='Ponteiro',BackgroundTransparency=1,Position=UDim2.fromOffset(55,0),Size=UDim2.fromOffset(50,48)},marker)
 make('Frame',{Name='ContornoHaste',BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(15,19,24),Position=UDim2.fromOffset(2,16),Size=UDim2.fromOffset(30,16),ZIndex=10},self.Arrow)
 make('Frame',{Name='Haste',BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(255,232,39),Position=UDim2.fromOffset(3,20),Size=UDim2.fromOffset(29,8),ZIndex=11},self.Arrow)
 for _,side in ipairs({-1,1}) do
  make('Frame',{Name='ContornoPonta',BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(28,24+side*8),Size=UDim2.fromOffset(27,14),Rotation=-side*40,BackgroundColor3=Color3.fromRGB(15,19,24),ZIndex=12},self.Arrow)
 end
 for _,side in ipairs({-1,1}) do
  make('Frame',{Name='Ponta',BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(28,24+side*8),Size=UDim2.fromOffset(26,7),Rotation=-side*40,BackgroundColor3=Color3.fromRGB(255,232,39),ZIndex=13},self.Arrow)
 end
 self.Caption=outlined(marker,'',13,UDim2.fromOffset(0,46),UDim2.fromOffset(160,29))
 self.Arrow.ZIndex=10;self.Caption.ZIndex=10
 self.World=make('Folder',{Name='EggTycoonMissionGuide'},workspace)
 self.Chevrons={}
 for i=1,6 do
  local part=make('Part',{Name='SetaChao',Size=Vector3.new(.38,.13,1.7),Anchored=true,CanCollide=false,
   CanTouch=false,CanQuery=false,CastShadow=false,Material=Enum.Material.Neon,Color=Color3.fromRGB(255,228,35),Transparency=1},self.World)
  self.Chevrons[i]=part
 end
 self.Cleanup=self.Gui.Destroying:Connect(function() if self.World then self.World:Destroy() end end)
 return self
end
function Guide:TrackMission(id)
 self.Selected=id;self.Active=true
end
function Guide:Stop()
 self.Active=false;self.Selected=nil;self:Hide()
end
function Guide:Hide()
 self.Marker.Visible=false
 for _,part in ipairs(self.Chevrons) do part.Transparency=1 end
end
function Guide:BuildGoal(state,kind,name)
 local cf=state.PlotCFrame or (state.PlotId and self.Config.PlotCFrame(state.PlotId))
 if not cf then return end
 for _,build in ipairs(state.Builds or {}) do
  if build.Kind==kind then return self.Config.ItemCFrame(cf,build).Position+Vector3.new(0,2,0),name end
 end
 return (cf*CFrame.new(0,2,-65)).Position,'Sua tycoon'
end
function Guide:EggGoal(state,position)
 local species=1
 for index in ipairs(self.Config.Species) do
  species=index
  if not (state.Discovered and (state.Discovered[tostring(index)] or state.Discovered[index])) then break end
 end
 local world=workspace:FindFirstChild('EggTycoonV3')
 local nests=world and world:FindFirstChild('Nests')
 local target,distance
 if nests then
  for _,nest in ipairs(nests:GetChildren()) do
   if nest:IsA('Model') and nest:GetAttribute('Species')==species and nest:GetAttribute('Available')~=false then
    local point=nest:GetPivot().Position
    local d=(point-position).Magnitude
    if not distance or d<distance then target=point;distance=d end
   end
  end
 end
 return target or Vector3.new(-42,2,738+(species-1)*180),'Ovo • '..self.Config.Species[species].Biome
end
function Guide:StolenRoute(state,position)
 local own=state.PlotId
 if not own then return end
 local destination=self.Config.PlotCFrame(own)
 -- Leave the victim's door before following the ring outside the protected plaza.
 for id=1,8 do
  if id~=own then
   local cf=self.Config.PlotCFrame(id)
   local p=cf:PointToObjectSpace(position)
   if math.abs(p.X)<80 and math.abs(p.Z)<80 then return (cf*CFrame.new(0,2,-90)).Position,'Saída da tycoon' end
  end
 end
 local localOwn=destination:PointToObjectSpace(position)
 if math.abs(localOwn.X)<40 and localOwn.Z>-110 and localOwn.Z<80 then
  return (destination*CFrame.new(0,2,-65)).Position,'Entregue a criatura'
 end
 local a=math.atan2(position.X,position.Z)
 local d=destination.Position
 local b=math.atan2(d.X,d.Z)
 local delta=(b-a+math.pi)%(2*math.pi)-math.pi
 if math.abs(delta)<math.rad(10) then return (destination*CFrame.new(0,2,-90)).Position,'Sua tycoon' end
 local nextAngle=a+math.clamp(delta,-math.rad(20),math.rad(20))
 return Vector3.new(math.sin(nextAngle)*330,2,math.cos(nextAngle)*330),'Contorne a praça'
end
function Guide:Resolve(state,position)
 if state.Carrying then
  if tostring(state.Carry):lower():find('ovo',1,true) then return self:BuildGoal(state,'Incubator','Incubadora') end
  return self:StolenRoute(state,position)
 end
 local selected=self.Selected
 if selected then
  for _,mission in ipairs(state.Missions or {}) do
   if mission.Id==selected and mission.Complete then selected=nil;self.Selected=nil;break end
  end
 end
 if not selected then
  for _,mission in ipairs(state.Missions or {}) do if not mission.Complete then selected=mission.Id;break end end
 end
 if not selected and #(state.Missions or {})>0 then return end
 if selected=='first_hatch' or not selected then
  if next(state.Pending or {}) then return self:BuildGoal(state,'Incubator','Aguarde a eclosão') end
  return self:EggGoal(state,position)
 elseif selected=='first_sale' or selected=='busy_factory' then
  if #(state.Creatures or {})==0 then
   if next(state.Pending or {}) then return self:BuildGoal(state,'Incubator','Aguarde a eclosão') end
   return self:EggGoal(state,position)
  end
  if (state.Income or 0)<=0 then return self:BuildGoal(state,'Habitat','Conecte as esteiras') end
  return self:BuildGoal(state,'Seller','Venda seus recursos')
 elseif selected=='engineer' then return self:BuildGoal(state,'Habitat','Melhore o habitat')
 elseif selected=='defender' then
  local world=workspace:FindFirstChild('EggTycoonV3')
  local plots=world and world:FindFirstChild('Plots')
  local point,distance
  if plots then for _,plot in ipairs(plots:GetChildren()) do
   local owner=plot:GetAttribute('OwnerUserId')
   local battery=plot:FindFirstChild('Battery')
   if battery and owner and owner~=0 and owner~=Players.LocalPlayer.UserId then
    local d=(battery.Position-position).Magnitude
    if not distance or d<distance then point=battery.Position;distance=d end
   end
  end end
  return point,point and 'Bateria rival' or nil
 elseif selected=='explorer' or selected=='collector' then return self:EggGoal(state,position) end
end
function Guide:Update(state,menuOpen)
 if menuOpen and not self.WasOpen then self.Active=true end
 self.WasOpen=menuOpen==true
 local character=Players.LocalPlayer.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 local camera=workspace.CurrentCamera
 if not self.Active or not root or not camera or not state.PlotId then self:Hide();return end
 local goal,caption=self:Resolve(state,root.Position)
 if not goal then self:Hide();return end
 local flat=Vector3.new(goal.X-root.Position.X,0,goal.Z-root.Position.Z)
 if flat.Magnitude<9 then self:Hide();return end
 self.Marker.Visible=true
 self.Marker:SetAttribute('Target',caption)
 self.Marker:SetAttribute('TargetPosition',goal)
 local viewport=camera.ViewportSize
 local inset=GuiService:GetGuiInset()
 local height=viewport.Y-(self.Gui.IgnoreGuiInset and 0 or inset.Y)
 local point,onScreen=camera:WorldToViewportPoint(goal+Vector3.new(0,5,0))
 local x,y=point.X,point.Y-(self.Gui.IgnoreGuiInset and 0 or inset.Y)
 if point.Z<0 then x=viewport.X-x;y=height-y end
 local margin=math.min(125,viewport.X*.2)
 local safeX=math.clamp(x,margin,math.max(margin,viewport.X-margin))
 local safeY=math.clamp(y,80,math.max(80,height-115))
 local navigation=self.Gui:FindFirstChild('Navegacao')
 if navigation and navigation.Visible then
  local p,s=navigation.AbsolutePosition,navigation.AbsoluteSize
  if safeY>p.Y-40 and safeY<p.Y+s.Y+40 then
   safeX=math.max(safeX,math.min(viewport.X-margin,p.X+s.X+90))
  end
 end
 local panel=self.Gui:FindFirstChild('Painel')
 if panel and panel.Visible then self.Marker.Visible=false end
 self.Marker.Position=UDim2.fromOffset(safeX,safeY)
 self.Arrow.Rotation=onScreen and 90 or math.deg(math.atan2(y-height*.5,x-viewport.X*.5))
 self.Caption.Text=caption..' • '..math.floor(flat.Magnitude)
 local direction=flat.Unit
 local right=Vector3.new(-direction.Z,0,direction.X)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={character,self.World};params.IgnoreWater=true
 for index,part in ipairs(self.Chevrons) do
  local pair=math.ceil(index/2)
  local side=index%2==1 and -1 or 1
  local p=root.Position+direction*(4+pair*3)+right*side*.5
  local hit=workspace:Raycast(p+Vector3.new(0,7,0),Vector3.new(0,-24,0),params)
  local yGround=hit and hit.Position.Y+.16 or root.Position.Y-2.7
  local origin=Vector3.new(p.X,yGround,p.Z)
  part.CFrame=CFrame.lookAt(origin,origin+direction)*CFrame.Angles(0,side*math.rad(35),0)
  part.Transparency=.15+(pair-1)*.12
 end
end
function Guide:Destroy()
 if self.Cleanup then self.Cleanup:Disconnect() end
 self.Marker:Destroy();self.World:Destroy()
end
return Guide
