-- Server-authoritative weapons, batteries, entry barriers and upgrades.
local Players = game:GetService("Players")
local Combat = {}
Combat.__index = Combat

local function rootOf(player)
 local c=player.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart"),h
end
local function finiteVector(v)
 return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z and v.Magnitude<1e7
end
local defenseNames={Perimeter=true,Frame=true,Roof=true,RoofFrame=true,DoorHeader=true,Laser=true,LaserBeam=true}
local function ownsPlot(state)
 return state and state.Player and state.Plot and state.Plot.Parent
  and state.Plot:GetAttribute("OwnerUserId")==state.Player.UserId
end
function Combat.new(ctx)
 return setmetatable({ctx=ctx,C=ctx.Config,PartDefaults=setmetatable({},{__mode="k"}),LabelDefaults=setmetatable({},{__mode="k"}),PlotPresentation=setmetatable({},{__mode="k"})},Combat)
end
function Combat:SetPartVisible(part,visible)
 local original=self.PartDefaults[part]
 local revision=part:GetAttribute("BaseShellRevision")
 local hasShellDefaults=part:GetAttribute("BaseShellTransparency")~=nil
 if not original or original.Revision~=revision or original.HasShellDefaults~=hasShellDefaults then
  original={Revision=revision,HasShellDefaults=hasShellDefaults}
  for _,key in ipairs({"Transparency","CanCollide","CanTouch","CanQuery"}) do
   local value=part:GetAttribute("BaseShell"..key)
   original[key]=value==nil and part[key] or value
  end
  self.PartDefaults[part]=original
 end
 part.Transparency=visible and original.Transparency or 1
 part.CanCollide=visible and original.CanCollide or false
 part.CanTouch=visible and original.CanTouch or false
 part.CanQuery=visible and original.CanQuery or false
end
function Combat:ApplyPlotDefenses(plot,owned,built,open)
 built=true -- The shell is part of every plot; only its powered entrance depends on ownership.
 local previous=self.PlotPresentation[plot]
 local generation=plot:GetAttribute("BaseShellGeneration")
 if previous and previous.Owned==owned and previous.Built==built and previous.Open==open and previous.Generation==generation then return end
 for _,part in ipairs(plot:GetChildren()) do
  if part:IsA("BasePart") then
   if defenseNames[part.Name] or part:GetAttribute("BaseShellPart") then
    local isLaser=part.Name=="Laser" or part.Name=="LaserBeam"
    self:SetPartVisible(part,not isLaser or (owned and not open))
    if isLaser then part.CanCollide=false;part.CanTouch=false end
    if part.Name=="Laser" then part:SetAttribute("Open",not built or open or not owned) end
   elseif part.Name=="Battery" then
    self:SetPartVisible(part,owned)
    for _,label in ipairs(part:GetDescendants()) do
     if label:IsA("BillboardGui") or label:IsA("SurfaceGui") then
      if self.LabelDefaults[label]==nil then
       local saved=label:GetAttribute("BaseShellEnabled")
       self.LabelDefaults[label]=saved==nil and label.Enabled or saved
      end
      label.Enabled=owned and self.LabelDefaults[label] or false
     end
    end
   end
  end
 end
 plot:SetAttribute("DefensesBuilt",true)
 self.PlotPresentation[plot]={Owned=owned,Built=true,Open=open,Generation=generation}
end
function Combat:SetPlotVacant(plot)
 if not plot then return end
 self:ApplyPlotDefenses(plot,false,false,true)
end
function Combat:BuildDefenses(state)
 local function reject(message) self.ctx:Toast(state.Player,message);return false end
 if not state or not state.Player then return false end
 if not state.Ready or not ownsPlot(state) then return reject("Escolha uma tycoon para usar a base pronta.") end
 if state.Leaving or state.OperationBusy then return reject("Aguarde a operação atual terminar.") end
 -- Compatibility with an old client: acknowledge the ready shell without charging
 -- or clearing a breach that is already in progress.
 state.Profile.DefensesBuilt=true
 self:ApplyPlotDefenses(state.Plot,true,true,(state.Runtime.BreachUntil or 0)>os.clock())
 self.ctx:Sync(state)
 return true
end
function Combat:Reset(state)
 local r=state.Runtime
 r.ActiveBatteryLevel=state.Profile.BatteryLevel
 r.BatteryMax=self.C.BatteryHP[r.ActiveBatteryLevel] or self.C.BatteryHP[1]
 r.BatteryHP=r.BatteryMax
 r.BreachUntil=0
  r.BatteryUpgradeDeferred=false
 r.Positions={}
 state.Energy=100
 state.LastCombat=0
 if ownsPlot(state) then state.Profile.DefensesBuilt=true;self:ApplyPlotDefenses(state.Plot,true,true,false) end
end
function Combat:DamageBattery(attacker,owner,damage)
 if not ownsPlot(attacker) or not ownsPlot(owner) or not owner.Ready or not attacker.Ready then return end
 if type(damage)~="number" or damage~=damage or damage<=0 or damage==math.huge then return end
 if owner==attacker or attacker.Leaving or owner.Leaving or (owner.Runtime.BreachUntil or 0)>os.clock() then return end
 local r=owner.Runtime
 r.BatteryHP=math.max(0,(r.BatteryHP or self.C.BatteryHP[1])-damage)
 owner.LastCombat=os.clock()
 attacker.LastCombat=os.clock()
  if not r.LastBatteryWarning or os.clock()-r.LastBatteryWarning>3 then
  r.LastBatteryWarning=os.clock()
  self.ctx:Toast(owner.Player,"Sua bateria está sendo atacada!")
 end
 if r.BatteryHP<=0 then
  r.BreachUntil=os.clock()+self.C.BreachTime
  if self.ctx.Services.Progression then self.ctx.Services.Progression:Record(attacker,"BatteriesBroken",1) end
  self.ctx:Toast(owner.Player,"Bateria destruída! Entrada aberta por 30 segundos.")
  self.ctx.Remotes.FX:FireAllClients("Breach",{Position=owner.Plot.Battery.Position,Duration=self.C.BreachTime})
 end
 self.ctx:Sync(owner)
end
function Combat:Attack(state,payload)
 if not state or not state.Ready or not ownsPlot(state) or type(payload)~="table" or state.Carry or state.Leaving then return end
 local weapon=self.C.Weapons[payload.Weapon]
 if not weapon or not finiteVector(payload.Target) then return end
 local required=payload.Weapon=="BlasterPlus" and 2 or (payload.Weapon=="Blaster" and 1 or 0)
 if (state.Profile.WeaponLevel or 0)<required then return end
 local root,hum=rootOf(state.Player)
 if not root or self.C.IsSafe(root.Position) then return end
 local tool=state.Player.Character:FindFirstChildOfClass("Tool")
 if not tool or tool:GetAttribute("WeaponKind")~=payload.Weapon then return end
 local now=os.clock()
 if now-(state.LastAttack or 0)<weapon.Cooldown or state.Energy<weapon.Energy then return end
 local from=root.Position+Vector3.new(0,1.2,0)
  local delta=payload.Target-from
  if delta.Magnitude<.05 then return end
  local direction=delta.Unit*weapon.Range
 state.LastAttack=now
 state.Energy=math.max(0,state.Energy-weapon.Energy)
 local rp=RaycastParams.new()
 rp.FilterType=Enum.RaycastFilterType.Exclude
 rp.FilterDescendantsInstances={state.Player.Character}
 rp.IgnoreWater=true
 local result=workspace:Raycast(from,direction,rp)
 local to=result and result.Position or from+direction
 self.ctx.Remotes.FX:FireAllClients("Shot",{From=from,To=to,Color=required==0 and Color3.fromRGB(255,210,125) or Color3.fromRGB(110,230,255)})
 if not result or self.C.IsSafe(to) then return end
 local hit=result.Instance
 for _,owner in pairs(self.ctx.States) do
  if ownsPlot(owner) and hit==owner.Plot:FindFirstChild("Battery") then
   self:DamageBattery(state,owner,weapon.Damage)
   return
  end
 end
 -- A humanoid only counts when its character belongs to a player. NPCs never take weapon damage.
 local model=hit:FindFirstAncestorOfClass("Model")
 local victim=model and Players:GetPlayerFromCharacter(model)
 if not victim or victim==state.Player then return end
 local victimState=self.ctx.States[victim.UserId]
 local victimRoot,victimHum=rootOf(victim)
 if not victimState or not victimState.Ready or victimState.Leaving or not ownsPlot(victimState) or not victimRoot or self.C.IsSafe(victimRoot.Position) then return end
 if victimState.Runtime.SpawnProtectedUntil and now<victimState.Runtime.SpawnProtectedUntil then return end
 state.LastCombat=now
 victimState.LastCombat=now
 victimHum:TakeDamage(weapon.Damage)
end
function Combat:Upgrade(state,kind)
 if not state or not state.Ready or not ownsPlot(state) or state.Leaving or state.OperationBusy then return end
 local p,C=state.Profile,self.C
 local cost,field,limit
 if kind=="Battery" then field="BatteryLevel";limit=4;cost=C.BatteryPrices[p.BatteryLevel]
 elseif kind=="Weapon" then field="WeaponLevel";limit=2;cost=C.WeaponPrices[(p.WeaponLevel or 0)+1]
 elseif kind=="Speed" then field="SpeedLevel";limit=#C.SpeedPrices;cost=C.SpeedPrices[(p.SpeedLevel or 0)+1]
 elseif kind=="Processor" then field="ProcessorLevel";limit=#C.ProcessorMultipliers;cost=C.ProcessorPrices[p.ProcessorLevel or 1]
 else return end
 if (p[field] or 0)>=limit or not cost then self.ctx:Toast(state.Player,"Melhoria máxima atingida.");return end
 if p.Cash<cost then self.ctx:Toast(state.Player,"Dinheiro insuficiente.");return end
 p.Cash-=cost
 p[field]=(p[field] or 0)+1
 if kind=="Battery" then
   if state.Runtime.BatteryUpgradeDeferred or (state.LastCombat>0 and os.clock()-state.LastCombat<C.CombatLock) or (state.Runtime.BreachUntil or 0)>os.clock() then
    state.Runtime.BatteryUpgradeDeferred=true
   self.ctx:Toast(state.Player,"Melhoria comprada: será aplicada na reconstrução da bateria.")
  else
   state.Runtime.ActiveBatteryLevel=p.BatteryLevel
   state.Runtime.BatteryMax=C.BatteryHP[p.BatteryLevel]
   state.Runtime.BatteryHP=state.Runtime.BatteryMax
  end
 elseif kind=="Speed" then self.ctx:ApplySpeed(state)
 elseif kind=="Weapon" and self.ctx.GrantTools then self.ctx:GrantTools(state) end
 self.ctx:Sync(state)
end
function Combat:Step(dt)
 local now=os.clock()
 for _,s in pairs(self.ctx.States) do
  if not s.Ready or s.Leaving or not ownsPlot(s) then continue end
  local r=s.Runtime
  s.Energy=math.min(100,(s.Energy or 100)+dt*10)
  if (r.BreachUntil or 0)>0 and now>=r.BreachUntil then
   r.BreachUntil=0
   r.ActiveBatteryLevel=s.Profile.BatteryLevel
   r.BatteryMax=self.C.BatteryHP[r.ActiveBatteryLevel]
   r.BatteryHP=r.BatteryMax
    r.BatteryUpgradeDeferred=false
   self.ctx:Toast(s.Player,"Bateria reconstruída. Entrada protegida.")
  end
  local open=(r.BreachUntil or 0)>now
  self:ApplyPlotDefenses(s.Plot,true,true,open)
  local battery=s.Plot:FindFirstChild("Battery")
  if battery then
   battery:SetAttribute("HP",r.BatteryHP)
   battery:SetAttribute("MaxHP",r.BatteryMax)
   battery.Color=open and Color3.fromRGB(75,78,87) or Color3.fromRGB(90,225,255)
   local label=s.Plot:FindFirstChild("BatteryLabel",true)
   local text=label and label:FindFirstChild("Text",true)
   if text and text:IsA("TextLabel") then
    text.Text=open and ("RECONSTRUINDO • "..math.ceil(r.BreachUntil-now).."s") or ("BATERIA "..math.ceil(r.BatteryHP).." / "..r.BatteryMax)
   end
  end
  -- ApplyPlotDefenses restores authored transparency and query settings on each
  -- transition. Do not overwrite that presentation with hard-coded values here.
  local cf=s.Plot:GetPivot()
  for _,visitor in pairs(self.ctx.States) do
   local root=rootOf(visitor.Player)
   if not root then continue end
   local lp=cf:PointToObjectSpace(root.Position)
   local previous=r.Positions[visitor.Player.UserId]
   r.Positions[visitor.Player.UserId]=lp
   if visitor==s or open then continue end
   -- Crossing inward through the entry is blocked. Crossing outward always works.
   local inside=math.abs(lp.X)<79 and lp.Z>-79.5 and lp.Z<79 and lp.Y<30
   local wasInside=previous and math.abs(previous.X)<79 and previous.Z>-79.5 and previous.Z<79 and previous.Y<30
   if inside and not wasInside then
    local safe=cf*CFrame.new(0,4,-87)
    root.CFrame=CFrame.lookAt(safe.Position,safe.Position+cf.LookVector)
    root.AssemblyLinearVelocity=Vector3.zero
    r.Positions[visitor.Player.UserId]=Vector3.new(0,4,-87)
    if now-(visitor.Runtime.LastLaserNotice or 0)>2 then
     visitor.Runtime.LastLaserNotice=now
     self.ctx:Toast(visitor.Player,"Destrua a bateria externa para abrir esta entrada.")
    end
   end
  end
 end
end
return Combat
