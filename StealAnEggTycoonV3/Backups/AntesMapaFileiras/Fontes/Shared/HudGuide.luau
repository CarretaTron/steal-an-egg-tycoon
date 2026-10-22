-- Local mission guidance; the server remains authoritative over every interaction.
local Players=game:GetService('Players')
local GuiService=game:GetService('GuiService')
local Rules=require(script.Parent.BuildRules)
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
 local self=setmetatable({Gui=options.Gui,Config=options.Config,Active=false,WasOpen=false,Hidden=false,
  ResolveClock=0,GoalDirty=true,GroundTargets={},Pulse=0},Guide)
 local marker=make('Frame',{Name='SetaMissao',BackgroundTransparency=1,Size=UDim2.fromOffset(180,88),AnchorPoint=Vector2.new(.5,.5),Visible=false,ZIndex=9},self.Gui)
 self.Marker=marker
 self.Arrow=make('Frame',{Name='Ponteiro',BackgroundTransparency=1,Position=UDim2.fromOffset(66,0),Size=UDim2.fromOffset(48,48),ZIndex=10},marker)
 local disc=make('Frame',{Name='Disco',BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(24,34,46),BackgroundTransparency=.12,Size=UDim2.fromScale(1,1),ZIndex=10},self.Arrow)
 make('UICorner',{CornerRadius=UDim.new(1,0)},disc)
 make('UIStroke',{Color=Color3.fromRGB(255,220,83),Thickness=1.5,Transparency=.12},disc)
 for _,side in ipairs({-1,1}) do
  local arm=make('Frame',{Name=side==-1 and 'PontaSuperior' or 'PontaInferior',BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(24,24+side*7.5),Size=UDim2.fromOffset(27,7),Rotation=-side*42,BackgroundColor3=Color3.fromRGB(255,220,83),ZIndex=12},self.Arrow)
  make('UICorner',{CornerRadius=UDim.new(0,3)},arm)
 end
 local captionPlate=make('Frame',{Name='Destino',BackgroundColor3=Color3.fromRGB(24,34,46),BackgroundTransparency=.15,BorderSizePixel=0,Position=UDim2.fromOffset(0,52),Size=UDim2.fromOffset(180,36),ZIndex=9},marker)
 make('UICorner',{CornerRadius=UDim.new(0,9)},captionPlate)
 self.Caption=outlined(captionPlate,'',13,UDim2.fromOffset(7,1),UDim2.fromOffset(166,34))
 self.Arrow.ZIndex=10;self.Caption.ZIndex=10
 self.World=make('Folder',{Name='EggTycoonMissionGuide'},workspace)
 self.Chevrons={}
 for i=1,6 do
  local part=make('Part',{Name='SetaChao',Size=Vector3.new(.3,.08,2.15),Anchored=true,CanCollide=false,
   CanTouch=false,CanQuery=false,CastShadow=false,Material=Enum.Material.Neon,Color=Color3.fromRGB(255,220,83),Transparency=1},self.World)
  self.Chevrons[i]=part
 end
 self.Cleanup=self.Gui.Destroying:Connect(function() if self.World then self.World:Destroy() end end)
 return self
end
function Guide:TrackMission(id)
 self.Selected=id;self.Active=true;self.GoalDirty=true
end
function Guide:SetHidden(hidden)
 self.Hidden=hidden==true
 self.GoalDirty=true
 self.ResolveClock=.1
 if self.Hidden then self:Hide() end
end
function Guide:IsHidden() return self.Hidden==true end
function Guide:Stop()
 self.Active=false;self.Selected=nil;self.AutomaticSetup=false;self.Goal=nil;self.GoalDirty=true;self:Hide()
end
function Guide:Hide()
 self.Marker.Visible=false
 for _,part in ipairs(self.Chevrons) do part.Transparency=1 end
 self.SmoothedScreen=nil;self.SmoothedAngle=nil
end
function Guide:BuildGoal(state,kind,name)
 local cf=state.PlotCFrame or (state.PlotId and self.Config.PlotCFrame(state.PlotId))
 if not cf then return end
 for _,build in ipairs(state.Builds or {}) do
  if build.Kind==kind then return self.Config.ItemCFrame(cf,build).Position+Vector3.new(0,2,0),name end
 end
 return (cf*CFrame.new(0,2,-65)).Position,'Sua tycoon'
end
function Guide:ClaimGoal(position)
 local world=workspace:FindFirstChild('EggTycoonV3')
 local plots=world and world:FindFirstChild('Plots')
 local target,distance
 if plots then for _,plot in ipairs(plots:GetChildren()) do
  local owner=plot:GetAttribute('OwnerUserId')
  if not owner or owner==0 then
   local pad=plot:FindFirstChild('ClaimPad',true)
   if pad and pad:IsA('BasePart') then
    local point=pad.Position+Vector3.new(0,2,0)
    local d=(point-position).Magnitude
    if not distance or d<distance then target=point;distance=d end
   end
  end
 end end
 return target,target and 'Escolha esta tycoon' or nil
end
function Guide:SetupGoal(state)
 local cf=state.PlotCFrame or (state.PlotId and self.Config.PlotCFrame(state.PlotId))
 if not cf then return end
 -- A snapshot owns an immutable build list; validate its conveyor graph once.
 if self.SetupBuilds==state.Builds and self.SetupPlot==state.PlotId and self.SetupCF==cf then
  return self.SetupPosition,self.SetupCaption
 end
 self.SetupBuilds=state.Builds;self.SetupPlot=state.PlotId;self.SetupCF=cf
 self.SetupPosition=nil;self.SetupCaption=nil
 local present={}
 for _,build in ipairs(state.Builds or {}) do present[build.Kind]=true end
 for _,step in ipairs({
  {Kind='Incubator',X=-32,Z=-40,Caption='Monte a incubadora 🔨'},
  {Kind='Habitat',X=0,Z=16,Caption='Monte o habitat 🔨'},
  {Kind='Processor',X=0,Z=-16,Caption='Monte o processador 🔨'},
  {Kind='Seller',X=0,Z=-36,Caption='Monte o vendedor 🔨'},
 }) do
  if not present[step.Kind] then
   self.SetupPosition=(cf*CFrame.new(step.X,2,step.Z)).Position
   self.SetupCaption=step.Caption
   return self.SetupPosition,self.SetupCaption
  end
 end
 local graph=Rules.Graph(state.Builds or {})
 local firstHabitat
 for _,build in ipairs(state.Builds or {}) do if build.Kind=='Habitat' then
  firstHabitat=firstHabitat or build
  if Rules.Trace(state.Builds,build.Id,graph) then return end
 end end
 if firstHabitat then
  self.SetupPosition=self.Config.ItemCFrame(cf,firstHabitat).Position+Vector3.new(0,2,0)
  self.SetupCaption='Conecte habitat → processador → vendedor'
 end
 return self.SetupPosition,self.SetupCaption
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
 if state.NeedsClaim or not state.PlotId then return self:ClaimGoal(position) end
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
   if battery and plot:GetAttribute('DefensesBuilt')==true and owner and owner~=0 and owner~=Players.LocalPlayer.UserId then
    local d=(battery.Position-position).Magnitude
    if not distance or d<distance then point=battery.Position;distance=d end
   end
  end end
  return point,point and 'Bateria rival' or nil
 elseif selected=='explorer' or selected=='collector' then return self:EggGoal(state,position) end
end
function Guide:AutomaticGoal(state,position)
 -- Claiming a plot must work before the optional mission guide is enabled.
 if state.NeedsClaim or not state.PlotId then return self:ClaimGoal(position) end
 local rebirths=math.max(0,math.floor(tonumber(state.Rebirths) or 0))
 if self.SetupRebirth~=rebirths then
  if self.SetupRebirth~=nil then self.AutomaticSetup=nil;self.SetupBuilds=nil end
  self.SetupRebirth=rebirths
 end
 if self.AutomaticSetup==nil then
  -- Existing layouts keep the previous opt-in mission behavior. An empty kit
  -- receives onboarding until its first complete production line is assembled.
  self.AutomaticSetup=#(state.Builds or {})==0 and #(state.Creatures or {})==0
 end
 if not self.AutomaticSetup then return end
 if state.Carrying then return self:Resolve(state,position) end
 local point,caption=self:SetupGoal(state)
 if not point then self.AutomaticSetup=false;return end
 -- Explicitly tracked missions take precedence over the automatic setup hint.
 if not self.Selected then return point,caption end
end
-- These helpers are independent of frame rate and wrap around the shortest arc.
function Guide.SmoothingAlpha(dt,speed)
 return 1-math.exp(-math.max(0,dt)*(speed or 22))
end
function Guide.SmoothAngle(current,target,alpha)
 return current+((target-current+180)%360-180)*alpha
end
function Guide:UpdateGround(character,root)
 local flat=self.Goal and Vector3.new(self.Goal.X-root.Position.X,0,self.Goal.Z-root.Position.Z)
 self.GroundTargets={}
 if not flat or flat.Magnitude<9 then return end
 local direction=flat.Unit
 local params=self.GroundParams or RaycastParams.new();self.GroundParams=params
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={character,self.World};params.IgnoreWater=true
 -- One height sample per pair. Render interpolates the six arms every frame.
 for pair=1,3 do
  local p=root.Position+direction*(4+pair*4)
  local hit=workspace:Raycast(p+Vector3.new(0,7,0),Vector3.new(0,-24,0),params)
  local origin=Vector3.new(p.X,hit and hit.Position.Y+.13 or root.Position.Y-2.7,p.Z)
  local forward=CFrame.lookAt(origin,origin+direction)
  for _,side in ipairs({-1,1}) do
   local index=(pair-1)*2+(side==-1 and 1 or 2)
   self.GroundTargets[index]=forward*CFrame.new(side*.6,0,0)*CFrame.Angles(0,side*math.rad(35),0)
  end
 end
end
-- Called every frame; destination lookup and ground sampling are capped at 10 Hz.
function Guide:Update(state,menuOpen,dt)
 if menuOpen and not self.WasOpen then self.Active=true;self.GoalDirty=true end
 self.WasOpen=menuOpen==true
 if self.Hidden then self:Hide();return end
 local character=Players.LocalPlayer.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 if not root or not workspace.CurrentCamera then self.Goal=nil;self:Hide();return end
 self.ResolveClock=(self.ResolveClock or 0)+math.max(0,dt or .1)
 if not self.GoalDirty and self.ResolveClock<.1 then return end
 self.ResolveClock=self.ResolveClock%.1;self.GoalDirty=false
 local goal,caption=self:AutomaticGoal(state,root.Position)
 if not goal and self.Active then goal,caption=self:Resolve(state,root.Position) end
 self.Goal=goal;self.GoalCaption=caption
 self.GroundTargets=self.GroundTargets or {}
 if not goal then self.GroundTargets={};self:Hide();return end
 self.Marker:SetAttribute('Target',caption)
 self.Marker:SetAttribute('TargetPosition',goal)
 self:UpdateGround(character,root)
end
-- Camera projection, UI movement and ground interpolation stay at the display rate.
function Guide:Render(dt)
 if self.Hidden or not self.Goal then self:Hide();return end
 local character=Players.LocalPlayer.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 local camera=workspace.CurrentCamera
 if not root or not camera then self:Hide();return end
 local flat=Vector3.new(self.Goal.X-root.Position.X,0,self.Goal.Z-root.Position.Z)
 if flat.Magnitude<9 then self:Hide();return end
 local viewport=camera.ViewportSize
 local top,bottom=GuiService:GetGuiInset()
 local insetY=self.Gui.IgnoreGuiInset and 0 or top.Y
 local height=viewport.Y-insetY-(self.Gui.IgnoreGuiInset and 0 or bottom.Y)
 local point,onScreen=camera:WorldToViewportPoint(self.Goal+Vector3.new(0,5,0))
 local x,y=point.X,point.Y-insetY
 if point.Z<0 then x=viewport.X-x;y=height-y end
 local margin=math.min(110,viewport.X*.25)
 local safeX=math.clamp(x,margin,math.max(margin,viewport.X-margin))
 local safeY=math.clamp(y,60,math.max(60,height-95))
 local navigation=self.Gui:FindFirstChild('Navegacao')
 if navigation and navigation.Visible then
  local p,s=navigation.AbsolutePosition,navigation.AbsoluteSize
  if safeY>p.Y-insetY-45 and safeY<p.Y-insetY+s.Y+45 then
   safeX=math.max(safeX,math.min(viewport.X-margin,p.X+s.X+100))
  end
 end
 local alpha=Guide.SmoothingAlpha(dt,22)
 local desired=Vector2.new(safeX,safeY)
 local smooth=self.SmoothedScreen and self.SmoothedScreen:Lerp(desired,alpha) or desired
 self.SmoothedScreen=Vector2.new(math.clamp(smooth.X,margin,math.max(margin,viewport.X-margin)),math.clamp(smooth.Y,60,math.max(60,height-95)))
 local angle=onScreen and math.deg(math.atan2(y-(safeY-20),x-safeX)) or math.deg(math.atan2(y-height*.5,x-viewport.X*.5))
 self.SmoothedAngle=self.SmoothedAngle and Guide.SmoothAngle(self.SmoothedAngle,angle,alpha) or angle
 self.Marker.Position=UDim2.fromOffset(self.SmoothedScreen.X,self.SmoothedScreen.Y)
 self.Arrow.Rotation=self.SmoothedAngle
 self.Caption.Text=(self.GoalCaption or 'Destino')..' • '..math.floor(flat.Magnitude)
 local panel=self.Gui:FindFirstChild('Painel')
 self.Marker.Visible=not (panel and panel.Visible)
 self.Pulse=(self.Pulse or 0)+dt
 local groundAlpha=Guide.SmoothingAlpha(dt,24)
 for index,part in ipairs(self.Chevrons) do
  local target=self.GroundTargets and self.GroundTargets[index]
  if target then
   part.CFrame=part.Transparency>=1 and target or part.CFrame:Lerp(target,groundAlpha)
   local pair=math.ceil(index/2)
   part.Transparency=.15+(pair-1)*.12+math.sin(self.Pulse*4-pair)*.045
  else part.Transparency=1 end
 end
end
function Guide:Destroy()
 if self.Cleanup then self.Cleanup:Disconnect() end
 self.Marker:Destroy();self.World:Destroy()
end
return Guide
