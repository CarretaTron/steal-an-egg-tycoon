local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local ProximityPromptService=game:GetService("ProximityPromptService")
local shared=ReplicatedStorage:WaitForChild("EggTycoonV3")
local Config=require(shared.Shared.Config)
local Art=require(shared.Shared.Art)
Art.Init()
local World=require(script.Parent.WorldFactory).Build()
local remoteFolder=shared:FindFirstChild("Remotes") or Instance.new("Folder")
remoteFolder.Name="Remotes";remoteFolder.Parent=shared
local ctx={Config=Config,Art=Art,World=World,States={},Services={},Remotes={},Connections={},Nests={},Guards={},Running=true}
for _,name in ipairs({"Command","State","Toast","FX"}) do
 local r=remoteFolder:FindFirstChild(name) or Instance.new("RemoteEvent")
 r.Name=name;r.Parent=remoteFolder;ctx.Remotes[name]=r
end
local function guid() return HttpService:GenerateGUID(false) end
local function copy(t,seen)
 if type(t)~="table" then return t end
 seen=seen or {};if seen[t] then return nil end;seen[t]=true
 local out={};for k,v in pairs(t) do out[k]=copy(v,seen) end
 seen[t]=nil;return out
end
local function characterRoot(player)
 local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
 if not h or h.Health<=0 then return nil,h end
 return c:FindFirstChild("HumanoidRootPart"),h
end
local function addConnection(connection) table.insert(ctx.Connections,connection);return connection end
function ctx:Toast(player,message)
 if player and player.Parent==Players then self.Remotes.Toast:FireClient(player,tostring(message)) end
end
function ctx:GetState(player) return self.States[player.UserId] end
function ctx:Near(player,position,distance)
 local root=characterRoot(player)
 return root~=nil and (root.Position-position).Magnitude<=distance
end
function ctx:ApplySpeed(state)
 local _,hum=characterRoot(state.Player)
 if hum then
  hum.WalkSpeed=(Config.WalkSpeed+(state.Profile.SpeedLevel or 0)*Config.SpeedIncrement)*(state.Carry and Config.CarryMultiplier or 1)
  if state.Carry then hum:UnequipTools() end
 end
end
function ctx:HasTransfer(state)
 for _,s in pairs(self.States) do
  local c=s.Carry
  if c and c.Kind=="Creature" and (s==state or c.VictimUserId==state.Player.UserId) then return true end
 end
 return self.Services.Persistence:HasTransfer(state)
end
function ctx:Sync(state)
 if not state.Ready or state.Player.Parent~=Players then return end
 local now=os.clock();local p=state.Profile;local pending={}
 for habitatId,v in pairs(state.Pending or {}) do
  pending[habitatId]={Id=v.Id,Species=v.Species,Remaining=math.max(0,v.EndsAt-now)}
 end
 local carry=state.Carry
 local carryName=carry and (carry.Kind=="Egg" and "Ovo de " or "Criatura: ")..Config.Species[carry.Kind=="Egg" and carry.Species or carry.Creature.Species].Name or ""
 self.Remotes.State:FireClient(state.Player,{
  Cash=p.Cash,Rebirths=p.Rebirths,Income=state.Plot and self.Services.Production:Income(state) or 0,Carry=carryName,Carrying=carry~=nil,
  NeedsClaim=state.Plot==nil,DefensesBuilt=p.DefensesBuilt==true,
  PlotId=state.PlotId,PlotCFrame=state.Plot and state.Plot:GetPivot() or nil,PlotHalf=Config.PlotHalfFor(state.Plot),Energy=math.floor(state.Energy),BatteryHP=state.Runtime.BatteryHP,
  BatteryMax=state.Runtime.BatteryMax,BreachRemaining=math.max(0,(state.Runtime.BreachUntil or 0)-now),
  LastCombatRemaining=state.LastCombat>0 and math.max(0,Config.CombatLock-(now-state.LastCombat)) or 0,Inventory=copy(p.Inventory),Builds=copy(p.Builds),
  Creatures=copy(p.Creatures),Pending=pending,SpeedLevel=p.SpeedLevel,WeaponLevel=p.WeaponLevel,BatteryLevel=p.BatteryLevel,
  ProcessorLevel=p.ProcessorLevel,Discovered=copy(p.Discovered),SaveMode=state.SaveMode,
  Missions=self.Services.Progression and self.Services.Progression:Snapshot(state) or {},
 })
end
local function clearCarryVisual(state)
 if state.Runtime.CarryVisual then state.Runtime.CarryVisual:Destroy();state.Runtime.CarryVisual=nil end
 state.Runtime.LastAllowedCF=nil
end
local function carryVisual(state)
 clearCarryVisual(state)
 local c=state.Carry;if not c then return end
 local root=characterRoot(state.Player);if not root then return end
 local visual
 if c.Kind=="Egg" then visual=Art.Egg(c.Species,CFrame.new(0,-1000,0),.7,World.Decorations)
 else visual=Art.Creature(c.Creature.Species,CFrame.new(0,-1000,0),.6,World.Decorations) end
 visual.Name="Carry_"..state.Player.UserId
 for _,part in ipairs(visual:GetDescendants()) do
  if part:IsA("BasePart") then part.CanCollide=false;part.CanQuery=false;part.CanTouch=false end
 end
 state.Runtime.CarryVisual=visual
 state.Runtime.LastAllowedCF=root.CFrame
end
function ctx:RestoreCarry(state,reason)
 if state.Runtime.TransferCommitting then return false end
 local c=state.Carry;if not c then return true end
 if c.Kind=="Creature" then
  local wasBusy=state.OperationBusy
  state.OperationBusy=true
  local ok,cancelled,status=pcall(function() return self.Services.Persistence:CancelTransfer(c) end)
  if ok and not cancelled and status=="Committed" then
   -- The journal can have committed even when its network acknowledgement was lost.
   -- Finish that recorded decision; never invent a new transfer after a cancelled carry.
   local victim=self.States[c.VictimUserId]
   if victim then
    state.Runtime.TransferCommitting=true;c.Committing=true
    local finalized,committed=pcall(function() return self.Services.Persistence:CommitTransfer(victim,state,c) end)
    state.Runtime.TransferCommitting=false;c.Committing=nil
    if finalized and committed then
     state.Carry=nil;clearCarryVisual(state);self:ApplySpeed(state)
     if victim.Plot then self.Services.Production:RenderCreatures(victim) end
     if state.Plot then self.Services.Production:RenderCreatures(state) end
     state.OperationBusy=wasBusy;self:Sync(victim);self:Sync(state)
     self:Toast(state.Player,"Transferência já confirmada pelo servidor; criatura entregue.")
     return true
    end
   end
  end
  state.OperationBusy=wasBusy
  if not ok or cancelled~=true then
   self:Toast(state.Player,"Aguardando confirmação segura da transferência. Tente novamente.")
   if not ok then warn("[EggTycoonV3] Cancel transfer unresolved:",cancelled) end
   return false
  end
 end
 state.Carry=nil;clearCarryVisual(state);self:ApplySpeed(state)
 if c.Kind=="Creature" then
  local victim=self.States[c.VictimUserId]
  if victim and victim.Ready then
   if victim.Plot then self.Services.Production:RenderCreatures(victim) end
   self:Sync(victim)
   self:Toast(victim.Player,"Sua criatura retornou ao habitat.")
  end
 elseif c.NestId and self.Nests[c.NestId] then
  self.Nests[c.NestId].RespawnAt=math.min(self.Nests[c.NestId].RespawnAt or math.huge,os.clock()+3)
 end
 self:Sync(state)
 if reason then self:Toast(state.Player,reason) end
 return true
end
local function createTool(name,kind,color)
 local tool=Instance.new("Tool");tool.Name=name;tool.RequiresHandle=true;tool.CanBeDropped=false;tool:SetAttribute("WeaponKind",kind)
 local handle=Instance.new("Part");handle.Name="Handle";handle.Size=kind=="Baton" and Vector3.new(.45,3,.45) or Vector3.new(.7,1,2)
 handle.Color=color;handle.Material=kind=="Baton" and Enum.Material.Wood or Enum.Material.Metal
 handle.CanCollide=false;handle.Massless=true;handle.Parent=tool
 local hasArt,prop=pcall(function() return Art.Prop(kind=="Baton" and "Baton" or "Blaster",handle.CFrame,.7,tool) end)
 if hasArt and prop then
  handle.Transparency=1
  for _,part in ipairs(prop:GetDescendants()) do if part:IsA("BasePart") then
   part.Anchored=false;part.CanCollide=false;part.CanQuery=false;part.Massless=true
   local weld=Instance.new("WeldConstraint");weld.Part0=handle;weld.Part1=part;weld.Parent=part
  end end
 end
 if kind~="Baton" and not (hasArt and prop) then
  local barrel=Instance.new("Part");barrel.Name="EnergyBarrel";barrel.Size=Vector3.new(.35,.35,1.2);barrel.Material=Enum.Material.Neon
  barrel.Color=Color3.fromRGB(90,230,255);barrel.CanCollide=false;barrel.Massless=true;barrel.CFrame=handle.CFrame*CFrame.new(0,.35,-1)
  barrel.Parent=tool;local weld=Instance.new("WeldConstraint");weld.Part0=handle;weld.Part1=barrel;weld.Parent=barrel
 end
 return tool
end
function ctx:GrantTools(state)
 if not state.Plot then return end
 local backpack=state.Player:FindFirstChildOfClass("Backpack")
 if not backpack then return end
 local char=state.Player.Character
 for _,container in ipairs({backpack,char}) do
  if container then for _,x in ipairs(container:GetChildren()) do if x:IsA("Tool") and x:GetAttribute("WeaponKind") then x:Destroy() end end end
 end
 createTool("Bastão","Baton",Color3.fromRGB(153,104,60)).Parent=backpack
 if state.Profile.WeaponLevel>=1 then createTool("Blaster","Blaster",Color3.fromRGB(71,106,151)).Parent=backpack end
 if state.Profile.WeaponLevel>=2 then createTool("Blaster +","BlasterPlus",Color3.fromRGB(174,100,224)).Parent=backpack end
end
ctx.Services.Building=require(script.Parent.Building).new(ctx)
ctx.Services.Production=require(script.Parent.Production).new(ctx)
ctx.Services.Persistence=require(script.Parent.Persistence).new(ctx)
ctx.Services.Combat=require(script.Parent.Combat).new(ctx)
ctx.Services.Progression=require(script.Parent.Progression).new(ctx)

local function nestVisible(n,visible)
 n.Model:SetAttribute("Available",visible)
 local egg=n.Model:FindFirstChild("Egg")
 if egg then for _,part in ipairs(egg:GetDescendants()) do
  if part:IsA("BasePart") then
   if part:GetAttribute("OriginalTransparency")==nil then part:SetAttribute("OriginalTransparency",part.Transparency) end
   part.Transparency=visible and part:GetAttribute("OriginalTransparency") or 1;part.CanQuery=visible
  elseif part:IsA("ProximityPrompt") then part.Enabled=visible end
 end end
end
for _,model in ipairs(World.Nests:GetChildren()) do
 local id=model:GetAttribute("NestId")
 if id then ctx.Nests[id]={Model=model,Species=model:GetAttribute("Species"),RespawnAt=0};nestVisible(ctx.Nests[id],true) end
end
for _,model in ipairs(World.Guardians:GetChildren()) do
 if model:IsA("Model") and model.PrimaryPart then
  local home=model:GetPivot();local species=model:GetAttribute("Species") or 1
  ctx.Guards[model:GetAttribute("NestId") or model.Name]={Model=model,Home=home,Species=species,Target=nil,AttackAt=0,NextAttack=0,Phase=0}
 end
end
local function stealEgg(state,nestId)
 if not state.Plot then ctx:Toast(state.Player,"Escolha uma tycoon livre antes de buscar seu ovo.");return end
 local n=ctx.Nests[nestId]
 if not n or state.Carry or not state.Ready or state.Leaving or n.RespawnAt>os.clock() or n.Model:GetAttribute("Available")~=true then return end
 local egg=n.Model:FindFirstChild("Egg");local part=egg and egg.PrimaryPart or n.Model.PrimaryPart
 if not part or not ctx:Near(state.Player,part.Position,13) then return end
 state.Carry={Kind="Egg",Species=n.Species,NestId=nestId}
 n.RespawnAt=os.clock()+(n.Model:GetAttribute("RespawnSeconds") or 22)
 nestVisible(n,false)
 if ctx.Guards[nestId] then ctx.Guards[nestId].Target=state.Player.UserId end
 carryVisual(state);ctx:ApplySpeed(state);ctx:Sync(state)
 ctx:Toast(state.Player,"O guardião percebeu! Leve o ovo à sua incubadora.")
end
local function renderPending(state,habitatId,pending)
 if not state.Plot then return end
 local build=ctx.Services.Building:GetBuild(state,habitatId);if not build then return end
 local folder=state.Plot:FindFirstChild("Incubations") or Instance.new("Folder")
 folder.Name="Incubations";folder.Parent=state.Plot
 local cf=Config.ItemCFrame(state.Plot:GetPivot(),build)*CFrame.new(0,1,0)
 local model=Art.Egg(pending.Species,cf,.85,folder);model.Name=pending.Id
 if model.PrimaryPart then
  local billboard=Instance.new("BillboardGui");billboard.Name="Timer";billboard.Size=UDim2.fromOffset(160,45);billboard.StudsOffset=Vector3.new(0,4,0);billboard.AlwaysOnTop=true;billboard.Parent=model.PrimaryPart
  local label=Instance.new("TextLabel");label.Name="Label";label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.TextColor3=Color3.new(1,1,1);label.TextStrokeTransparency=.15;label.Font=Enum.Font.GothamBold;label.TextScaled=true;label.Parent=billboard
 end
end
local function deliveryPosition(state,buildId,egg)
 if not state.Plot then return nil end
 if egg then
  local build=buildId and ctx.Services.Building:GetBuild(state,buildId)
  if build and build.Kind=="Incubator" then return Config.ItemCFrame(state.Plot:GetPivot(),build).Position,build.Id end
  for _,candidate in ipairs(state.Profile.Builds) do
   local position=Config.ItemCFrame(state.Plot:GetPivot(),candidate).Position
   if candidate.Kind=="Incubator" and ctx:Near(state.Player,position,14) then return position,candidate.Id end
  end
 else return (state.Plot:GetPivot()*CFrame.new(0,0,-65*Config.PlotHalfFor(state.Plot)/Config.LegacyPlotHalf)).Position end
 return nil
end
local function deliver(state,buildId)
 if not state.Plot then return end
 local c=state.Carry;if not c or state.OperationBusy then return end
 if c.Kind=="Creature" then
  local root=characterRoot(state.Player);local previous=state.Runtime.LastAllowedCF
  if not root or Config.IsSafe(root.Position) or (previous and (root.Position-previous.Position).Magnitude>25) then
   if root and previous then root.CFrame=previous;root.AssemblyLinearVelocity=Vector3.zero end
   ctx:Toast(state.Player,"Conclua o percurso até sua base antes de entregar.");return
  end
 end
 local pos,incubatorId=deliveryPosition(state,buildId,c.Kind=="Egg")
 if not pos or not ctx:Near(state.Player,pos,16) then ctx:Toast(state.Player,c.Kind=="Egg" and "Aproxime-se da sua incubadora." or "Leve a criatura à entrada da sua base.");return end
 if c.Kind=="Egg" then
  local habitat=ctx.Services.Building:FreeHabitat(state)
  if not habitat then ctx:Toast(state.Player,"Você precisa de um habitat vazio.");return end
  local pending={Id=guid(),Species=c.Species,IncubatorId=incubatorId,EndsAt=os.clock()+Config.Species[c.Species].Hatch}
  state.Pending[habitat.Id]=pending;state.Carry=nil;clearCarryVisual(state);ctx:ApplySpeed(state)
  renderPending(state,habitat.Id,pending);ctx:Sync(state);ctx:Toast(state.Player,"Incubação iniciada! O habitat foi reservado.")
 else
  local victim=ctx.States[c.VictimUserId]
  local destination=ctx.Services.Building:GetBuild(state,c.DestinationHabitatId)
  if not victim or not victim.Plot or victim.Leaving or not destination or destination.Kind~="Habitat" then ctx:RestoreCarry(state,"O roubo foi cancelado; criatura devolvida.");return end
  for _,cr in ipairs(state.Profile.Creatures) do if cr.HabitatId==destination.Id then ctx:RestoreCarry(state,"O habitat de destino está ocupado.");return end end
  state.OperationBusy=true;state.Runtime.TransferCommitting=true;c.Committing=true
  local ok,result=pcall(function() return ctx.Services.Persistence:CommitTransfer(victim,state,c) end)
  state.Runtime.TransferCommitting=false;c.Committing=nil;state.OperationBusy=false
  if ok and result then
   state.Carry=nil;clearCarryVisual(state);ctx:ApplySpeed(state)
   ctx.Services.Production:RenderCreatures(state);ctx.Services.Production:RenderCreatures(victim)
   state.Profile.Discovered[tostring(c.Creature.Species)]=true
   ctx:Toast(state.Player,"Criatura entregue! Ela agora produz na sua base.");ctx:Toast(victim.Player,"Uma criatura sua foi roubada.")
   ctx:Sync(state);ctx:Sync(victim)
  else
   if not ok then warn("[EggTycoonV3] CommitTransfer:",result) end
   ctx:RestoreCarry(state,"Não foi possível confirmar o roubo; criatura devolvida.")
  end
 end
end
local function theftContext(state,victimId,creatureId)
 local victim=ctx.States[tonumber(victimId)]
  if not state.Plot or not victim or not victim.Plot or victim==state or not victim.Ready or victim.Leaving or state.Carry or state.OperationBusy then return end
 local creature
 for _,c in ipairs(victim.Profile.Creatures) do if c.Id==creatureId then creature=c;break end end
 if not creature or ctx.Services.Building:Reserved(victim,creature.HabitatId) then return end
 local build=ctx.Services.Building:GetBuild(victim,creature.HabitatId)
 if not build or not ctx:Near(state.Player,Config.ItemCFrame(victim.Plot:GetPivot(),build).Position,16) then return end
 local root=characterRoot(state.Player)
 local lp=root and victim.Plot:GetPivot():PointToObjectSpace(root.Position)
 local previous=victim.Runtime.Positions and victim.Runtime.Positions[state.Player.UserId]
 local half=Config.PlotHalfFor(victim.Plot)
 local insideHalf,front,roof=half-1,-half+.5,30*half/Config.LegacyPlotHalf
 local alreadyInside=previous and math.abs(previous.X)<insideHalf and previous.Z>front and previous.Z<insideHalf and previous.Y<roof
 if not lp or math.abs(lp.X)>=insideHalf or lp.Z<=front or lp.Z>=insideHalf or lp.Y>=roof or (victim.Profile.DefensesBuilt~=false and (victim.Runtime.BreachUntil or 0)<=os.clock() and not alreadyInside) then return end
 local habitat=ctx.Services.Building:FreeHabitat(state)
  if not habitat then return nil,nil,nil,"Você precisa de um habitat livre na sua base." end
  return victim,creature,habitat
end
local function stealCreature(state,victimId,creatureId)
  local victim,creature,habitat,reason=theftContext(state,victimId,creatureId)
  if not victim then if reason then ctx:Toast(state.Player,reason) end;return end
 local carry={Kind="Creature",Creature=copy(creature),VictimUserId=victim.Player.UserId,SourceHabitatId=creature.HabitatId,DestinationHabitatId=habitat.Id,TransferId=guid()}
 state.OperationBusy=true;state.Carry=carry
  -- Reserve the last legal position and disable weapons before journal IO can yield.
  carryVisual(state);ctx:ApplySpeed(state);ctx:Sync(state)
 victim.LastCombat=os.clock();state.LastCombat=os.clock()
 ctx:Toast(victim.Player,"Alguém está levando sua criatura! Intercepte o ladrão.")
 ctx.Services.Production:RenderCreatures(victim);ctx:Sync(victim)
 local ok,result=pcall(function() return ctx.Services.Persistence:BeginTransfer(victim,state,creature,carry.TransferId) end)
 state.OperationBusy=false
 if not ok or not result or state.Leaving or victim.Leaving or state.Carry~=carry or not characterRoot(state.Player) then
  if state.Carry==carry then ctx:RestoreCarry(state,"Não foi possível iniciar o roubo.") end
  if ok and result and state.Carry~=carry then task.spawn(function() ctx.Services.Persistence:CancelTransfer(carry) end) end
  return
 end
  ctx:Sync(state)
 ctx:Toast(state.Player,"Leve a criatura à sua base. A praça e o corredor estão bloqueados durante o roubo.")
end
local function rebirth(state)
 if not state.Plot then ctx:Toast(state.Player,"Escolha sua tycoon antes de renascer.");return end
 local cost=Config.RebirthCost*3^state.Profile.Rebirths
 if state.Profile.Cash<cost then ctx:Toast(state.Player,"Rebirth requer $"..tostring(cost)..".");return end
 if ctx:HasTransfer(state) then ctx:Toast(state.Player,"Conclua os roubos em andamento antes do rebirth.");return end
 if state.LastCombat>0 and os.clock()-state.LastCombat<Config.CombatLock then ctx:Toast(state.Player,"Aguarde o fim da invasão para renascer.");return end
 if state.Carry then ctx:RestoreCarry(state) end
 state.OperationBusy=true;state.Generation+=1
 local p=state.Profile
 p.Rebirths+=1;p.Cash=0;p.SpeedLevel=0;p.WeaponLevel=0;p.BatteryLevel=1;p.ProcessorLevel=1
  p.Inventory=copy(Config.StarterInventory);p.Builds={};p.Creatures={};p.StoredHabitats={};p.Incubations={};p.ResourceEscrow={};p.StarterPlaced=true;p.DefensesBuilt=true;state.Pending={}
 local pending=state.Plot:FindFirstChild("Incubations");if pending then pending:ClearAllChildren() end
 ctx.Services.Building:Render(state);ctx.Services.Production:RenderCreatures(state);ctx.Services.Combat:Reset(state)
 ctx:GrantTools(state);ctx:ApplySpeed(state);ctx:Sync(state)
 local ok,err=pcall(function() ctx.Services.Persistence:Save(state) end)
 if not ok then warn("[EggTycoonV3] Rebirth save:",err) end
 state.OperationBusy=false;ctx:Toast(state.Player,"Rebirth concluído! Produção permanente +25%.")
end

-- Prompt hold time and continuous distance are validated on the server.
local holds={}
local claimPlot
local function promptPosition(prompt)
 local parent=prompt.Parent
 if parent and parent:IsA("BasePart") then return parent.Position end
 if parent and parent:IsA("Attachment") then return parent.WorldPosition end
 if parent and parent:IsA("Model") then return parent:GetPivot().Position end
 return nil
end
local function setupPrompt(prompt)
 if not prompt:IsA("ProximityPrompt") then return end
 local action=prompt:GetAttribute("Action")
 if action=="ClaimPlot" then prompt.HoldDuration=.35;prompt.ActionText="Escolher tycoon";prompt.ObjectText="Terreno livre"
 elseif action=="StealCreature" then prompt.HoldDuration=2;prompt.ActionText="Roubar criatura";prompt.ObjectText="Leve até sua base"
 elseif action=="StealEgg" then prompt.HoldDuration=.6;prompt.ActionText="Roubar ovo"
 elseif action=="Deliver" then prompt.HoldDuration=.35;prompt.ActionText="Entregar / incubar" end
end
for _,d in ipairs(World:GetDescendants()) do setupPrompt(d) end
addConnection(World.DescendantAdded:Connect(setupPrompt))
local function beginHold(prompt,player)
  if not prompt:IsDescendantOf(World) or not prompt.Enabled then return end
 local state=ctx:GetState(player);local pos=promptPosition(prompt)
  if not state or not state.Ready or state.Leaving or state.OperationBusy or not pos or not ctx:Near(player,pos,math.min(prompt.MaxActivationDistance+3,18)) then return end
  if prompt:GetAttribute("Action")=="StealCreature" then
   local victim=theftContext(state,prompt:GetAttribute("OwnerUserId"),prompt:GetAttribute("CreatureId"))
   if not victim then return end
   local now=os.clock()
   if not victim.Runtime.LastTheftWarning or now-victim.Runtime.LastTheftWarning>=3 then
    victim.Runtime.LastTheftWarning=now
    ctx:Toast(victim.Player,"Alguém está tentando roubar uma criatura da sua base!")
   end
  end
 holds[player.UserId]={Prompt=prompt,Started=os.clock(),Valid=true}
end
local function triggerPrompt(prompt,player)
 if not prompt:IsDescendantOf(World) or not prompt.Enabled then return end
 local state=ctx:GetState(player);local pos=promptPosition(prompt)
 if not state or not state.Ready or state.OperationBusy or state.Leaving or not pos or not ctx:Near(player,pos,math.min(prompt.MaxActivationDistance+3,18)) then return end
 local hold=holds[player.UserId]
 if prompt.HoldDuration>0 and (not hold or hold.Prompt~=prompt or not hold.Valid or os.clock()-hold.Started<math.max(0,prompt.HoldDuration-.1) or os.clock()-hold.Started>8) then return end
 holds[player.UserId]=nil
 local action=prompt:GetAttribute("Action")
 if action=="ClaimPlot" then claimPlot(state,prompt:GetAttribute("PlotId"))
 elseif not state.Plot then ctx:Toast(player,"Escolha uma tycoon livre primeiro.")
 elseif action=="StealEgg" then stealEgg(state,prompt:GetAttribute("NestId"))
 elseif action=="StealCreature" then stealCreature(state,prompt:GetAttribute("OwnerUserId"),prompt:GetAttribute("CreatureId"))
 elseif action=="Deliver" and (not prompt:GetAttribute("OwnerUserId") or prompt:GetAttribute("OwnerUserId")==player.UserId) then deliver(state,prompt:GetAttribute("BuildId")) end
end
addConnection(ProximityPromptService.PromptButtonHoldBegan:Connect(beginHold))
addConnection(ProximityPromptService.PromptTriggered:Connect(triggerPrompt))

local buildActions={Place=true,Move=true,Store=true,BuyItem=true,ReleaseCreature=true,UpgradeHabitat=true}
addConnection(ctx.Remotes.Command.OnServerEvent:Connect(function(player,action,payload)
 local state=ctx:GetState(player)
 if not state or not state.Ready or state.Leaving or type(action)~="string" then return end
 local now=os.clock()
 if action=="GetState" then if now-(state.Runtime.LastGetState or 0)>.3 then state.Runtime.LastGetState=now;ctx:Sync(state) end;return end
 if action=="Attack" then if state.Plot then ctx.Services.Combat:Attack(state,payload) end;return end
 if state.OperationBusy or now-(state.Runtime.LastCommand or 0)<.12 then return end
 state.Runtime.LastCommand=now
 if action=="ClaimPlot" then
  claimPlot(state,type(payload)=="table" and payload.PlotId or nil);return
 end
 if not state.Plot then ctx:Toast(player,"Escolha uma tycoon livre primeiro.");return end
 if buildActions[action] then
  local root=characterRoot(player);local localPosition=root and state.Plot:GetPivot():PointToObjectSpace(root.Position)
  local half=Config.PlotHalfFor(state.Plot)
  if not localPosition or math.abs(localPosition.X)>half+10 or math.abs(localPosition.Z)>half+15 then ctx:Toast(player,"Volte à sua base para construir.");return end
  ctx.Services.Building:Command(state,action,type(payload)=="table" and payload or {})
 elseif action=="BuildDefenses" then
  ctx.Services.Combat:BuildDefenses(state)
 elseif action=="Upgrade" then
  if type(payload)=="table" then ctx.Services.Combat:Upgrade(state,payload.Kind) end
  elseif action=="ClaimMission" then
   if type(payload)=="table" and type(payload.Id)=="string" then
    local claimed,message=ctx.Services.Progression:Claim(state,payload.Id)
    if message then ctx:Toast(player,message) end
    if claimed then ctx:Sync(state) end
   end
 elseif action=="Rebirth" then rebirth(state)
 elseif action=="Drop" then ctx:RestoreCarry(state,"Transporte abandonado.")
 elseif action=="Deliver" then deliver(state,type(payload)=="table" and payload.BuildId or nil) end
end))

local function makeDeliveryPad(state)
 local old=state.Plot:FindFirstChild("DeliveryPad");if old then old:Destroy() end
 local part=Instance.new("Part");part.Name="DeliveryPad";part.Size=Vector3.new(12,.2,8);part.Anchored=true;part.CanCollide=false
 part.Material=Enum.Material.Neon;part.Color=Color3.fromRGB(102,234,164);part.Transparency=.5;part.CFrame=state.Plot:GetPivot()*CFrame.new(0,.15,-65*Config.PlotHalfFor(state.Plot)/Config.LegacyPlotHalf);part.Parent=state.Plot
 local p=Instance.new("ProximityPrompt");p.ActionText="Entregar criatura";p.ObjectText="Sua base";p.RequiresLineOfSight=false;p.MaxActivationDistance=12;p.HoldDuration=.35
 p:SetAttribute("Action","Deliver");p:SetAttribute("OwnerUserId",state.Player.UserId);p.Parent=part
end
local function ownerSign(plot,player)
 local sign=plot:FindFirstChild("OwnerSign")
 local title=sign and sign:FindFirstChild("Title",true)
 local subtitle=sign and sign:FindFirstChild("Subtitle",true)
 if title and title:IsA("TextLabel") then title.Text=player and ("BASE DE "..string.upper(player.DisplayName)) or "BASE DISPONÍVEL" end
 if subtitle and subtitle:IsA("TextLabel") then subtitle.Text=player and "Roube • incube • produza • defenda" or "Escolha na placa verde da entrada" end
end
local function claimLabel(plot,pad)
 local label=pad:FindFirstChild("ClaimLabel") or plot:FindFirstChild("ClaimLabel")
 -- Previous in-progress maps parented this billboard to the plot instead of its pad.
 if label then label.Parent=pad end
 return label
end
local function claimAvailable(plot,available)
 local pad=plot:FindFirstChild("ClaimPad")
 if not pad then return end
 pad.Transparency=available and .15 or 1
 pad.CanQuery=available
 local prompt=pad:FindFirstChild("ClaimPlot")
 if prompt then prompt.Enabled=available end
 local label=claimLabel(plot,pad)
 if label then label.Enabled=available end
end
for id=1,8 do
 local plot=World.Plots:FindFirstChild(string.format("Plot_%02d",id))
 if plot then
  plot:SetAttribute("OwnerUserId",0)
  for _,name in ipairs({"Structures","Creatures","Incubations"}) do
   local folder=plot:FindFirstChild(name);if folder then folder:ClearAllChildren() end
  end
  local oldDelivery=plot:FindFirstChild("DeliveryPad");if oldDelivery then oldDelivery:Destroy() end
  local pad=plot:FindFirstChild("ClaimPad")
  if not pad then
   pad=Instance.new("Part");pad.Name="ClaimPad";pad.Size=Vector3.new(16,.4,10);pad.Anchored=true;pad.CanCollide=false;pad.CanTouch=false
   pad.CFrame=plot:GetPivot()*CFrame.new(0,.25,-96*Config.PlotHalfFor(plot)/Config.LegacyPlotHalf);pad.Material=Enum.Material.Neon;pad.Color=Color3.fromRGB(112,255,66)
   pad:SetAttribute("PlotId",id);pad.Parent=plot
  end
  local prompt=pad:FindFirstChild("ClaimPlot") or Instance.new("ProximityPrompt")
  prompt.Name="ClaimPlot";prompt.ActionText="Escolher tycoon";prompt.ObjectText="Terreno livre";prompt.HoldDuration=.35
  prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=12;prompt:SetAttribute("Action","ClaimPlot");prompt:SetAttribute("PlotId",id);prompt.Parent=pad
  if not claimLabel(plot,pad) then
   local label=Art.Label(pad,pad,"TYCOON LIVRE","ESCOLHA SUA BASE",Color3.fromRGB(154,255,100),110);label.Name="ClaimLabel"
  end
  ctx.Services.Combat:SetPlotVacant(plot)
  claimAvailable(plot,true);ownerSign(plot,nil)
 end
end

claimPlot=function(state,id)
 if not state or not state.Ready or state.Leaving or state.OperationBusy or state.Player.Parent~=Players then return false end
 if state.Plot then ctx:Toast(state.Player,"Você já escolheu uma tycoon neste servidor.");return false end
 if type(id)~="number" or id~=id or id%1~=0 or id<1 or id>8 then return false end
 local plot=World.Plots:FindFirstChild(string.format("Plot_%02d",id))
 local pad=plot and plot:FindFirstChild("ClaimPad")
 local prompt=pad and pad:FindFirstChild("ClaimPlot")
 if not plot or not pad or not prompt or not prompt.Enabled or (plot:GetAttribute("OwnerUserId") or 0)~=0 then
  ctx:Toast(state.Player,"Essa tycoon já foi escolhida. Procure outra placa verde.");return false
 end
 if not ctx:Near(state.Player,pad.Position,prompt.MaxActivationDistance+2) then
  ctx:Toast(state.Player,"Aproxime-se da placa verde da tycoon que quer escolher.");return false
 end
 -- Reserve both sides before rendering can yield: concurrent requests cannot share a plot.
 local profileBefore,runtimeBefore=copy(state.Profile),copy(state.Runtime)
 state.OperationBusy=true;state.Plot=plot;state.PlotId=id
 plot:SetAttribute("OwnerUserId",state.Player.UserId);claimAvailable(plot,false)
 local ok,err=xpcall(function()
  ctx.Services.Persistence:RestoreIncubations(state)
  state.Profile.DefensesBuilt=true
  ctx.Services.Combat:Reset(state)
  ctx.Services.Building:Render(state);ctx.Services.Production:RenderCreatures(state);makeDeliveryPad(state)
  for habitatId,pending in pairs(state.Pending) do renderPending(state,habitatId,pending) end
  ownerSign(plot,state.Player)
 end,debug.traceback)
 if not ok then
  for _,name in ipairs({"Structures","Creatures","Incubations"}) do local f=plot:FindFirstChild(name);if f then f:ClearAllChildren() end end
  local delivery=plot:FindFirstChild("DeliveryPad");if delivery then delivery:Destroy() end
  state.Profile=profileBefore;state.Runtime=runtimeBefore;state.Pending=nil;state.Plot=nil;state.PlotId=nil
  plot:SetAttribute("OwnerUserId",0);ctx.Services.Combat:SetPlotVacant(plot);claimAvailable(plot,true);ownerSign(plot,nil)
  state.OperationBusy=false
  warn("[EggTycoonV3] Claim preservado para nova tentativa:",err)
  ctx:Sync(state);ctx:Toast(state.Player,"Não foi possível montar sua base agora. Seu progresso foi preservado; tente novamente.")
  return false
 end
 state.OperationBusy=false
 ctx:GrantTools(state);ctx:ApplySpeed(state);ctx:Sync(state)
 ctx:Toast(state.Player,#state.Profile.Builds==0 and "Tycoon escolhida! Abra o martelo dentro do terreno e posicione seu kit gratuito." or "Tycoon escolhida! Sua base salva foi restaurada neste terreno.")
 return true
end
local function spawnCharacter(state,character)
 local root=character:WaitForChild("HumanoidRootPart",10);local hum=character:FindFirstChildOfClass("Humanoid")
 if not root or not hum or state.Leaving or not state.Ready then return end
 local spawn=World.Decorations:FindFirstChild("SpawnSeguro")
 character:PivotTo(spawn and spawn.CFrame*CFrame.new(0,4,0) or CFrame.new(0,5,0))
 state.Runtime.SpawnProtectedUntil=os.clock()+3
 ctx:GrantTools(state);ctx:ApplySpeed(state)
 addConnection(hum.Died:Connect(function()
  holds[state.Player.UserId]=nil
  ctx:RestoreCarry(state,"Você foi derrotado. Seu transporte foi devolvido.")
 end))
end
local joining={}
local function join(player)
 if ctx.States[player.UserId] or joining[player.UserId] then return end
 joining[player.UserId]=true
 local spawn=World.Decorations:FindFirstChild("SpawnSeguro")
 if spawn and spawn:IsA("SpawnLocation") then player.RespawnLocation=spawn end
 local ok,profile,mode=pcall(function() return ctx.Services.Persistence:Load(player) end)
 if not ok or not profile then
  joining[player.UserId]=nil
  player:Kick("Não foi possível carregar seu progresso com segurança. Tente novamente.")
  warn("[EggTycoonV3] Profile load:",mode or profile);return
 end
 -- No runtime queues exist in the lobby: saving here retains stored incubation and packets.
 local state={Player=player,Profile=profile,Carry=nil,LastCombat=0,Energy=100,LastAttack=0,Generation=0,Runtime={},SaveMode=mode,Ready=true}
 if player.Parent~=Players then
  ctx.Services.Persistence:Release(state);joining[player.UserId]=nil;return
 end
 ctx.States[player.UserId]=state;joining[player.UserId]=nil
 addConnection(player.CharacterAdded:Connect(function(character) spawnCharacter(state,character) end))
 if player.Character then task.spawn(spawnCharacter,state,player.Character) end
 ctx:Sync(state)
 task.delay(2,function()
  if state.Leaving then return end
  if not state.Plot then ctx:Toast(player,"Você nasceu na praça. Escolha uma tycoon livre na placa verde da entrada.") end
  if mode and string.find(mode,"Sessão") then ctx:Toast(player,"TESTE LOCAL: APIs desativadas; progresso desta sessão não é persistente.") end
 end)
end
local leave
local function deferLeave(state)
  state.Runtime.LeaveInProgress=false
  if state.Runtime.LeaveRetryScheduled or ctx.Closing then return false end
  state.Runtime.LeaveRetryScheduled=true
  task.delay(5,function()
   state.Runtime.LeaveRetryScheduled=false
   if ctx.States[state.Player.UserId]==state then leave(state.Player) end
  end)
  return false
end
leave=function(player,forceSnapshot)
 local state=ctx.States[player.UserId];if not state then return end
  if state.Runtime.LeaveInProgress then return false end
  state.Runtime.LeaveInProgress=true
 state.Leaving=true;holds[player.UserId]=nil
 local deadline=os.clock()+20
 while state.OperationBusy and os.clock()<deadline do task.wait(.1) end
  if state.OperationBusy then return deferLeave(state) end
  local restored=ctx:RestoreCarry(state)
 for _,carrier in pairs(ctx.States) do
  if carrier.Carry and carrier.Carry.Kind=="Creature" and carrier.Carry.VictimUserId==player.UserId then
   while carrier.Runtime.TransferCommitting and os.clock()<deadline do task.wait(.1) end
    if carrier.Runtime.TransferCommitting or not ctx:RestoreCarry(carrier,"O dono saiu; a criatura retornou à base original.") then restored=false end
  end
 end
  -- Keep the plot and its reservations until the journal decision can be resolved.
  -- On shutdown the frozen profile retains journal references for recovery next session.
  if not restored and not forceSnapshot then return deferLeave(state) end
  local ok,released=pcall(function() return ctx.Services.Persistence:Release(state) end)
  local queued=ctx.Services.Persistence.PendingReleases and ctx.Services.Persistence.PendingReleases[player.UserId]
  if not ok or (released~=true and not queued) then
   warn("[EggTycoonV3] Release retained for retry:",released)
   return deferLeave(state)
  end
 if state.Plot then
  local plot=state.Plot
  for _,name in ipairs({"Structures","Creatures","Incubations"}) do local f=plot:FindFirstChild(name);if f then f:ClearAllChildren() end end
  local pad=plot:FindFirstChild("DeliveryPad");if pad then pad:Destroy() end
  plot:SetAttribute("OwnerUserId",0);ctx.Services.Combat:SetPlotVacant(plot)
  claimAvailable(plot,true);ownerSign(plot,nil)
 end
 ctx.States[player.UserId]=nil
  state.Ready=false;state.Runtime.LeaveInProgress=false
  return true
end
addConnection(Players.PlayerAdded:Connect(function(player) task.spawn(join,player) end))
addConnection(Players.PlayerRemoving:Connect(leave))
for _,player in ipairs(Players:GetPlayers()) do task.spawn(join,player) end

local function guardStep(dt)
 local now=os.clock()
 for _,g in pairs(ctx.Guards) do
  local model=g.Model;if not model.Parent then continue end
  local spec=Config.Species[g.Species];local pivot=model:GetPivot();local position=pivot.Position
  local target=g.Target and ctx.States[g.Target]
  local root=target and characterRoot(target.Player)
  if not root or (root.Position-g.Home.Position).Magnitude>135 or root.Position.Y>30 then target=nil;root=nil;g.Target=nil end
  if not root then
   local closest=26
   for _,s in pairs(ctx.States) do
    local candidate=characterRoot(s.Player)
    if candidate then local distance=(candidate.Position-position).Magnitude
     if distance<closest and (candidate.Position-g.Home.Position).Magnitude<130 then closest=distance;target=s;root=candidate;g.Target=s.Player.UserId end
    end
   end
  end
  if g.AttackAt>0 then
   if now>=g.AttackAt then
    if target and root and (root.Position-g.AttackPosition).Magnitude<11 then
     local _,hum=characterRoot(target.Player);if hum then hum:TakeDamage(spec.Damage) end
    end
    g.AttackAt=0;g.NextAttack=now+1.25
   end
  elseif root and (root.Position-position).Magnitude<11 and now>=g.NextAttack then
   g.AttackAt=now+.65;g.AttackPosition=root.Position
   ctx.Remotes.FX:FireAllClients("GuardianWarning",{Position=root.Position,Radius=11,Duration=.65,Species=g.Species})
  else
   local destination=root and root.Position or g.Home.Position
   local delta=Vector3.new(destination.X-position.X,0,destination.Z-position.Z)
   if delta.Magnitude>1 then
    local move=delta.Unit*math.min(spec.Speed*dt,delta.Magnitude)
    local nextPosition=position+move
    local cf=CFrame.lookAt(nextPosition,nextPosition+delta.Unit)
    model:PivotTo(cf)
   elseif not root then model:PivotTo(g.Home) end
  end
  model:SetAttribute("Chasing",root~=nil)
  model:SetAttribute("Attacking",g.AttackAt>0)
 end
end
local accumulator,syncTimer,saveTimer,releaseRetryTimer=0,0,0,0
addConnection(RunService.Heartbeat:Connect(function(dt)
 if not ctx.Running then return end
 accumulator+=dt;if accumulator<.1 then return end
 dt=math.min(accumulator,.4);accumulator=0;local now=os.clock()
 ctx.Services.Combat:Step(dt);guardStep(dt)
 for id,n in pairs(ctx.Nests) do if n.RespawnAt>0 and now>=n.RespawnAt then n.RespawnAt=0;nestVisible(n,true) end end
 for userId,hold in pairs(holds) do
  local s=ctx.States[userId];local pos=promptPosition(hold.Prompt)
  if not s or not pos or not hold.Prompt.Parent or not ctx:Near(s.Player,pos,math.min(hold.Prompt.MaxActivationDistance+3,18)) then hold.Valid=false end
  if now-hold.Started>8 then holds[userId]=nil end
 end
 for _,s in pairs(ctx.States) do
  if not s.Ready or s.Leaving or s.OperationBusy or not s.Plot then continue end
  ctx.Services.Production:Step(s,dt)
  local root=characterRoot(s.Player)
  if s.Carry and root then
   if s.Carry.Kind=="Creature" then
    local lastAllowed=s.Runtime.LastAllowedCF
    local tooFar=lastAllowed and (root.Position-lastAllowed.Position).Magnitude>math.max(25,(Config.WalkSpeed+(s.Profile.SpeedLevel or 0)*Config.SpeedIncrement)*dt*3)
    if Config.IsSafe(root.Position) or tooFar then
     if s.Runtime.LastAllowedCF then root.CFrame=s.Runtime.LastAllowedCF;root.AssemblyLinearVelocity=Vector3.zero end
     if now-(s.Runtime.LastSafeWarning or 0)>3 then s.Runtime.LastSafeWarning=now;ctx:Toast(s.Player,"Criaturas roubadas não podem entrar na zona segura.") end
    else s.Runtime.LastAllowedCF=root.CFrame end
   end
   local visual=s.Runtime.CarryVisual
   if visual and visual.Parent then visual:PivotTo(root.CFrame*CFrame.new(0,.5,-3.2)) end
  end
  local changed=false
  for habitatId,p in pairs(s.Pending) do
   local folder=s.Plot:FindFirstChild("Incubations");local visual=folder and folder:FindFirstChild(p.Id)
   local timer=visual and visual:FindFirstChild("Timer",true);local label=timer and timer:FindFirstChild("Label")
   if label then label.Text="Chocando: "..math.max(0,math.ceil(p.EndsAt-now)).."s" end
   if now>=p.EndsAt then
    local build=ctx.Services.Building:GetBuild(s,habitatId)
    if build and build.Kind=="Habitat" then
     table.insert(s.Profile.Creatures,{Id=p.Id,Species=p.Species,HabitatId=habitatId,Stored=0})
      if ctx.Services.Progression then ctx.Services.Progression:Record(s,"Hatches",1) end
     s.Profile.Discovered[tostring(p.Species)]=true
     ctx:Toast(s.Player,Config.Species[p.Species].Name.." nasceu! Conecte habitat → processador → vendedor.")
    end
    s.Pending[habitatId]=nil;if visual then visual:Destroy() end;changed=true
   end
  end
  if changed then ctx.Services.Production:RenderCreatures(s);ctx:Sync(s) end
 end
 syncTimer+=dt;saveTimer+=dt
  releaseRetryTimer+=dt
  if releaseRetryTimer>=5 then
   releaseRetryTimer=0
   task.spawn(function()
    local ok,err=pcall(function() ctx.Services.Persistence:RetryPending() end)
    if not ok then warn("[EggTycoonV3] Pending release retry:",err) end
   end)
  end
 if syncTimer>=1 then syncTimer=0;for _,s in pairs(ctx.States) do ctx:Sync(s) end end
 if saveTimer>=Config.AutoSave then
  saveTimer=0
  for _,s in pairs(ctx.States) do if s.Ready and not s.Leaving and not s.OperationBusy and not s.Runtime.Saving then
   s.Runtime.Saving=true;task.spawn(function()
    local ok,err=pcall(function() ctx.Services.Persistence:Save(s) end)
    s.Runtime.Saving=false;if not ok then warn("[EggTycoonV3] Autosave:",err) end
   end)
  end end
 end
end))
function ctx:Shutdown()
 self.Running=false
 for _,connection in ipairs(self.Connections) do connection:Disconnect() end
end
if RunService:IsStudio() then
 ctx.QA={ClaimPlot=claimPlot,PickupEgg=stealEgg,Deliver=deliver,Steal=stealCreature,Rebirth=rebirth,BeginHold=beginHold,TriggerPrompt=triggerPrompt}
 _G.EggTycoonV3=ctx
end
game:BindToClose(function()
  ctx.Running=false;ctx.Closing=true
  local deadline=os.clock()+25
 local remaining=0
 for _,s in pairs(ctx.States) do remaining+=1;task.spawn(function() leave(s.Player);remaining-=1 end) end
  while remaining>0 and os.clock()<deadline-3 do task.wait(.1) end
  for _,s in pairs(ctx.States) do
   if not s.Runtime.LeaveInProgress then task.spawn(leave,s.Player,true) end
  end
  local draining=false
  while os.clock()<deadline do
   local outstanding=next(ctx.States)~=nil or next(ctx.Services.Persistence.PendingReleases or {})~=nil
   if not outstanding and not draining then break end
   if not draining then
    draining=true
    task.spawn(function()
     pcall(function() ctx.Services.Persistence:RetryPending() end)
     draining=false
    end)
   end
   task.wait(.2)
  end
end)
print("[EggTycoonV3] Ready: 7 biomas, 8 bases, produção e roubos autoritativos.")
