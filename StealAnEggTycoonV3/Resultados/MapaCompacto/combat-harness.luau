
local now=100
local os={clock=function() return now end}
local checks=0
local function expect(value,message)
    checks+=1
    assert(value,"CHECK FAILED: "..message)
end
local Vector3={}
local vm={}
function Vector3.new(x,y,z) return setmetatable({_type="Vector3",X=x,Y=y,Z=z},vm) end
vm.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vm.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vm.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vm.__div=function(a,b) return Vector3.new(a.X/b,a.Y/b,a.Z/b) end
vm.__index=function(a,key)
    if key=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if key=="Unit" then return a/a.Magnitude end
end
Vector3.zero=Vector3.new(0,0,0)
local CFrame={}
local cm={}
function CFrame.new(x,y,z)
    local p=type(x)=="table" and x or Vector3.new(x or 0,y or 0,z or 0)
    return setmetatable({Position=p,LookVector=Vector3.new(0,0,-1)},cm)
end
function cm:PointToObjectSpace(p) return p-self.Position end
cm.__index=cm
cm.__mul=function(a,b) return CFrame.new(a.Position+b.Position) end
function CFrame.lookAt(p,_target) return CFrame.new(p) end
local Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end}
local Enum={RaycastFilterType={Exclude="Exclude"}}
local RaycastParams={new=function() return {} end}
local function typeof(value) return type(value)=="table" and value._type or type(value) end
local Node={}
Node.__index=Node
local function node(class,name,props)
    local n=setmetatable({ClassName=class,Name=name,Children={},Attributes={}},Node)
    for key,value in pairs(props or {}) do n[key]=value end
    return n
end
function Node:IsA(class)
    return self.ClassName==class or (class=="BasePart" and self.ClassName=="Part")
end
function Node:GetChildren() return self.Children end
function Node:GetDescendants()
    local all={}
    for _,child in ipairs(self.Children) do
        table.insert(all,child)
        for _,descendant in ipairs(child:GetDescendants()) do table.insert(all,descendant) end
    end
    return all
end
function Node:FindFirstChild(name,recursive)
    for _,child in ipairs(self.Children) do if child.Name==name then return child end end
    if recursive then
        for _,child in ipairs(self.Children) do
            local found=child:FindFirstChild(name,true)
            if found then return found end
        end
    end
end
function Node:FindFirstChildOfClass(class)
    for _,child in ipairs(self.Children) do if child:IsA(class) then return child end end
end
function Node:FindFirstAncestorOfClass(class)
    local p=self.Parent
    while type(p)=="table" do if p:IsA(class) then return p end;p=p.Parent end
end
function Node:GetAttribute(name) return self.Attributes[name] end
function Node:SetAttribute(name,value) self.Attributes[name]=value end
function Node:GetPivot() return self.Pivot end
local function append(parent,child)
    child.Parent=parent;table.insert(parent.Children,child);parent[child.Name]=child
    return child
end
local Players={}
function Players:GetPlayerFromCharacter(model) return model.Player end
-- Presentation is intentionally NOT simulated. Record only the Combat contract.
local generatorPresentation={}
local generatorUpdates={}
local Generator={}
function Generator.Present(plot,owned,open)
    generatorPresentation[plot]={Owned=owned,Open=open}
end
function Generator.Update(plot,hp,maximum,open,remaining,level)
    generatorUpdates[plot]={HP=hp,Maximum=maximum,Open=open,Remaining=remaining,Level=level}
end
local BaseShell={}
function BaseShell.SetHalf(plot,half)
    -- Record the requested extent without rendering or resizing mock geometry.
    plot:SetAttribute("PlotHalf",half)
    return plot
end
local generatorModule={}
local baseShellModule={}
local replicatedStorage={EggTycoonV3={Shared={Generator=generatorModule,BaseShell=baseShellModule}}}
local game={GetService=function(_self,name)
    if name=="Players" then return Players end
    assert(name=="ReplicatedStorage","Unexpected service: "..tostring(name))
    return replicatedStorage
end}
local function require(module)
    if module==generatorModule then return Generator end
    if module==baseShellModule then return BaseShell end
    error("Unexpected module dependency")
end
local workspace={}
function workspace:Raycast(_from,_direction,_params) return self.Hit end
local function makePlayer(id)
    local player={UserId=id,Parent=Players}
    local character=node("Model","Character",{Player=player})
    local root=append(character,node("Part","HumanoidRootPart",{Position=Vector3.new(0,4,0)}))
    local humanoid=append(character,node("Humanoid","Humanoid",{Health=100,DamageTaken=0}))
    function humanoid:TakeDamage(damage) self.DamageTaken+=damage end
    local tool=append(character,node("Tool","Baton"));tool:SetAttribute("WeaponKind","Baton")
    player.Character=character
    return player,root,humanoid
end
local defenses={Perimeter=true,Frame=true,Roof=true,RoofFrame=true,DoorHeader=true,Laser=true,LaserBeam=true}
local function makePlot(id)
    local plot=node("Model","Plot_"..id,{Parent=true,Pivot=CFrame.new()})
    plot:SetAttribute("OwnerUserId",0)
    plot:SetAttribute("PlotHalf",80)
    local function part(name,transparency,collide)
        return append(plot,node("Part",name,{Transparency=transparency,CanCollide=collide,
            CanTouch=collide,CanQuery=true,Position=Vector3.zero}))
    end
    for i=1,5 do part("Perimeter",.30+i*.01,true) end
    part("Frame",.12,true);part("Roof",.72,true);part("RoofFrame",.18,true);part("DoorHeader",.21,true)
    part("Laser",.58,false)
    for _=1,5 do part("LaserBeam",.29,false) end
    -- Battery stays the invisible authoritative hitbox. Generator owns its skin.
    part("Battery",1,true)
    return plot
end
local function makeState(id,plot,built)
    local player,root,humanoid=makePlayer(id)
    local state={Player=player,Plot=plot,Ready=true,Runtime={},Energy=100,LastCombat=0,
        LastAttack=0,Profile={DefensesBuilt=built,BatteryLevel=1,WeaponLevel=0,Cash=10000}}
    if plot then plot:SetAttribute("OwnerUserId",id) end
    return state,root,humanoid
end
local config={PlotHalf=80,LegacyPlotHalf=80,
    PlotHalfFor=function(plot) return plot and plot:GetAttribute("PlotHalf") or 80 end,
    DefensesPrice=25,BatteryHP={200,450,900,1800},BatteryPrices={10,20,30},
    BreachTime=30,CombatLock=10,IsSafe=function(_p) return false end,
    Weapons={Baton={Damage=20,Range=8,Cooldown=.7,Energy=0}}}
local ctx={Config=config,States={},Services={},Remotes={FX={FireAllClients=function() end}},Syncs=0}
function ctx:Toast(_player,_message) end
function ctx:Sync(_state) self.Syncs+=1 end
function ctx:HasTransfer(_state) return self.TransferActive==true end
local Combat=(function()
-- Server-authoritative weapons, batteries, entry barriers and upgrades.
local Players = game:GetService("Players")
local Generator = require(game:GetService("ReplicatedStorage").EggTycoonV3.Shared.Generator)
local BaseShell = require(game:GetService("ReplicatedStorage").EggTycoonV3.Shared.BaseShell)
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
    Generator.Present(plot,owned,open)
   end
  end
 end
 plot:SetAttribute("DefensesBuilt",true)
 self.PlotPresentation[plot]={Owned=owned,Built=true,Open=open,Generation=generation}
end
function Combat:SetPlotVacant(plot)
 if not plot then return end
 if BaseShell.SetHalf(plot,self.C.PlotHalf)==false then return false end
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
   Generator.Update(s.Plot,r.BatteryHP,r.BatteryMax,open,math.max(0,(r.BreachUntil or 0)-now),r.ActiveBatteryLevel)
  end
  -- ApplyPlotDefenses restores authored transparency and query settings on each
  -- transition. Do not overwrite that presentation with hard-coded values here.
  local cf=s.Plot:GetPivot()
  local half=self.C.PlotHalfFor(s.Plot)
  local scale=half/80
  local insideHalf,front=half-1,-half+.5
  for _,visitor in pairs(self.ctx.States) do
   local root=rootOf(visitor.Player)
   if not root then continue end
   local lp=cf:PointToObjectSpace(root.Position)
   local previous=r.Positions[visitor.Player.UserId]
   r.Positions[visitor.Player.UserId]=lp
   if visitor==s or open then continue end
   -- Crossing inward through the entry is blocked. Crossing outward always works.
   local inside=math.abs(lp.X)<insideHalf and lp.Z>front and lp.Z<insideHalf and lp.Y<30*scale
   local wasInside=previous and math.abs(previous.X)<insideHalf and previous.Z>front and previous.Z<insideHalf and previous.Y<30*scale
   if inside and not wasInside then
    local safe=cf*CFrame.new(0,4,-87*scale)
    root.CFrame=CFrame.lookAt(safe.Position,safe.Position+cf.LookVector)
    root.AssemblyLinearVelocity=Vector3.zero
    r.Positions[visitor.Player.UserId]=Vector3.new(0,4,-87*scale)
    if now-(visitor.Runtime.LastLaserNotice or 0)>2 then
     visitor.Runtime.LastLaserNotice=now
     self.ctx:Toast(visitor.Player,"Destrua a bateria externa para abrir esta entrada.")
    end
   end
  end
 end
end
return Combat


end)()
local combat=Combat.new(ctx)
local plot=makePlot(1)
local original={}
for _,part in ipairs(plot:GetChildren()) do
    original[part]={Transparency=part.Transparency,CanCollide=part.CanCollide,
        CanTouch=part.CanTouch,CanQuery=part.CanQuery}
end
local function shell(laserHidden,message)
    for _,part in ipairs(plot:GetChildren()) do
        if defenses[part.Name] then
            local hidden=laserHidden and (part.Name=="Laser" or part.Name=="LaserBeam")
            local snapshot=original[part]
            expect(part.Transparency==(hidden and 1 or snapshot.Transparency),message.." transparency "..part.Name)
            expect(part.CanQuery==(not hidden and snapshot.CanQuery),message.." raycast "..part.Name)
            if part.Name~="Laser" and part.Name~="LaserBeam" then
                expect(part.CanCollide==(not hidden and snapshot.CanCollide),message.." collision "..part.Name)
            else
                expect(not part.CanCollide and not part.CanTouch,message.." nonphysical laser")
            end
        end
    end
end
combat:SetPlotVacant(plot)
shell(true,"Vacant")
expect(generatorPresentation[plot].Owned==false and generatorPresentation[plot].Open==true,
    "Vacant plot delegates hidden generator and unpowered entry presentation")
local owner=makeState(1,plot,false);ctx.States[1]=owner
combat:Reset(owner);combat:Step(.1)
shell(false,"Claim receives ready walls and roof")
expect(owner.Profile.DefensesBuilt==true,"Reset migrates optional-defense WIP profile to the ready shell")
expect(generatorPresentation[plot].Owned==true and generatorPresentation[plot].Open==false,
    "Claim delegates owned generator presentation")
expect(generatorUpdates[plot].HP==200 and generatorUpdates[plot].Maximum==200 and generatorUpdates[plot].Level==1,
    "Combat sends authoritative initial HP, maximum and active level")
expect(plot.Laser:GetAttribute("Open")==false,"Claim powers the ready laser")
expect(combat:BuildDefenses(owner)==true,"Legacy assembly request acknowledges ready shell")
local cash=owner.Profile.Cash
expect(cash==10000,"Ready walls never charge an assembly price")
expect(combat:BuildDefenses(owner)==true and owner.Profile.Cash==cash,"Repeated assembly does not charge")
combat:Step(.1)
shell(false,"Built defense after Step")
expect(plot.Laser:GetAttribute("Open")==false,"Built laser is closed")
local lobby,lobbyRoot,lobbyHum=makeState(2,nil,false);ctx.States[2]=lobby
workspace.Hit={Instance=lobbyRoot,Position=lobbyRoot.Position}
local payload={Weapon="Baton",Target=Vector3.new(0,4,6)}
combat:Attack(owner,payload)
expect(lobbyHum.DamageTaken==0,"Unclaimed player cannot be damaged outside the safe plaza")
expect(combat:BuildDefenses(lobby)==false,"Lobby player cannot assemble defense")
combat:Attack(lobby,payload);combat:Step(.1)
expect(lobby.Energy==100,"Unclaimed player is skipped by defense simulation")
local raiderPlot=makePlot(2);lobby.Plot=raiderPlot;raiderPlot:SetAttribute("OwnerUserId",2)
combat:Reset(lobby);now+=1;combat:Attack(owner,payload)
expect(lobbyHum.DamageTaken==20,"Owned, ready player can receive PvP damage")
lobby.Ready=false;now+=1;combat:Attack(owner,payload)
expect(lobbyHum.DamageTaken==20,"Unready victim cannot receive damage")
lobby.Ready=true;lobby.Leaving=true;now+=1;combat:Attack(owner,payload)
expect(lobbyHum.DamageTaken==20,"Leaving victim cannot receive damage")
lobby.Leaving=false;raiderPlot:SetAttribute("OwnerUserId",999);now+=1;combat:Attack(owner,payload)
expect(lobbyHum.DamageTaken==20,"Stale plot ownership cannot enable PvP")
raiderPlot:SetAttribute("OwnerUserId",2)
combat:DamageBattery(lobby,owner,200)
expect(owner.Runtime.BatteryHP==0 and owner.Runtime.BreachUntil==now+30,"Battery destruction opens a timed breach")
combat:Step(.1)
for _,part in ipairs(plot:GetChildren()) do
    if part.Name=="Laser" or part.Name=="LaserBeam" then
        expect(part.Transparency==1 and not part.CanQuery,"Breach hides laser and removes its raycast obstruction")
    elseif defenses[part.Name] then
        expect(part.Transparency==original[part].Transparency and part.CanCollide,"Breach preserves shell")
    end
end
expect(generatorUpdates[plot].HP==0 and generatorUpdates[plot].Maximum==200
    and generatorUpdates[plot].Open==true and generatorUpdates[plot].Remaining==30,
    "Breach sends zero HP and the authoritative reconstruction countdown")
combat:Upgrade(owner,"Battery")
combat:Step(.1)
expect(generatorUpdates[plot].Level==1 and generatorUpdates[plot].Maximum==200,
    "Deferred upgrade cannot advance the panel level or maximum before rebuild")
expect(owner.Profile.BatteryLevel==2 and owner.Runtime.ActiveBatteryLevel==1,"Battery upgrade is deferred during breach")
expect(owner.Runtime.BatteryHP==0,"Upgrade cannot repair an active breach")
now+=31;combat:Step(.1)
expect(owner.Runtime.BreachUntil==0 and owner.Runtime.BatteryHP==450,"Expired breach rebuilds upgraded battery")
expect(owner.Runtime.BatteryUpgradeDeferred==false,"Rebuild clears deferred upgrade")
expect(generatorUpdates[plot].HP==450 and generatorUpdates[plot].Maximum==450
    and generatorUpdates[plot].Open==false and generatorUpdates[plot].Level==2,
    "Rebuild sends the upgraded full HP and active level")
shell(false,"Rebuilt authored defense")
ctx.States[1]=nil;plot:SetAttribute("OwnerUserId",0);combat:SetPlotVacant(plot)
shell(true,"Released plot")
expect(generatorPresentation[plot].Owned==false,"Release delegates hidden generator presentation")
local nextOwner=makeState(3,plot,true);ctx.States[3]=nextOwner
combat:Reset(nextOwner);combat:Step(.1)
shell(false,"Reclaimed saved defenses")
expect(generatorPresentation[plot].Owned==true and generatorPresentation[plot].Open==false,
    "Reclaim delegates powered generator presentation")
expect(generatorUpdates[plot].HP==200 and generatorUpdates[plot].Maximum==200 and generatorUpdates[plot].Level==1,
    "Reclaim resets the authoritative presentation payload for its new owner")
nextOwner.Profile.DefensesBuilt=nil;combat:Reset(nextOwner);combat:Step(.1)
shell(false,"Legacy complete shell")
nextOwner.Profile.DefensesBuilt=false;combat:Reset(nextOwner)
ctx.TransferActive=true;cash=nextOwner.Profile.Cash
expect(combat:BuildDefenses(nextOwner)==true and nextOwner.Profile.Cash==cash,"Legacy request during transport leaves ready shell and cash unchanged")
ctx.TransferActive=false;nextOwner.LastCombat=now
expect(combat:BuildDefenses(nextOwner)==true,"Legacy request during combat cannot change ready shell")
nextOwner.LastCombat=0;nextOwner.Profile.Cash=0
expect(combat:BuildDefenses(nextOwner)==true,"Ready shell does not require cash")
nextOwner.Profile.Cash=10000
nextOwner.Runtime.BreachUntil=now+30
expect(combat:BuildDefenses(nextOwner)==true and plot.Laser:GetAttribute("Open")==true,"Legacy assembly cannot close an active breach")
expect(nextOwner.Profile.Cash==10000 and nextOwner.Profile.DefensesBuilt==true,"Compatibility request preserves cash and ready defenses")
local fresh=append(plot,node("Part","NewTrim",{Transparency=1,CanCollide=false,CanTouch=false,CanQuery=false}))
fresh:SetAttribute("BaseShellPart",true);fresh:SetAttribute("BaseShellRevision",1)
fresh:SetAttribute("BaseShellTransparency",.24);fresh:SetAttribute("BaseShellCanCollide",true)
fresh:SetAttribute("BaseShellCanTouch",true);fresh:SetAttribute("BaseShellCanQuery",true)
plot:SetAttribute("BaseShellGeneration",1)
combat:ApplyPlotDefenses(plot,true,true,true)
expect(fresh.Transparency==.24 and fresh.CanCollide and fresh.CanQuery,"Shell generation invalidates cached presentation and restores authored defaults")
combat:SetPlotVacant(plot)
expect(fresh.Transparency==.24 and fresh.CanCollide,"New shell decorations remain visible and solid while vacant")
local powered=plot:FindFirstChild("Laser")
powered:SetAttribute("BaseShellTransparency",.76);powered:SetAttribute("BaseShellRevision",1)
powered.Transparency=1
plot:SetAttribute("BaseShellGeneration",2)
combat:ApplyPlotDefenses(plot,true,true,false)
expect(powered.Transparency==.76,"Claim restores a laser created in a hidden vacant state")
print("PASS Combat offline: "..checks.." checks; Generator is a recording stub; no mesh, SurfaceGui, Studio, physics, or replication test performed")

return {Passed=true,Checks=checks,Host='Studio Edit lexical mocks; legacy-sized fixtures'}
