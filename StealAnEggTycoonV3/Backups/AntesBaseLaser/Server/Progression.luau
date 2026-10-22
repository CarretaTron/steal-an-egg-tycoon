-- Persistent objectives count authoritative server events. Rewards are inventory pieces.
local Progression={}
Progression.__index=Progression
local supportedStats={Hatches=true,Sales=true,ResourcesSold=true,HabitatUpgrades=true,BatteriesBroken=true}

local function finite(value)
 return type(value)=="number" and value==value and math.abs(value)<math.huge
end
local function counter(value,cap)
 if not finite(value) then return 0 end
 return math.clamp(math.floor(value),0,cap)
end
local function ensure(profile)
 if type(profile.Progress)~="table" then profile.Progress={Stats={},Claimed={}} end
 local progress=profile.Progress
 if type(progress.Stats)~="table" then progress.Stats={} end
 if type(progress.Claimed)~="table" then progress.Claimed={} end
 return progress
end

function Progression.new(ctx)
 return setmetatable({ctx=ctx},Progression)
end

function Progression:Record(state,stat,amount)
 if not state or type(state.Profile)~="table" or not supportedStats[stat] then return false end
 amount=amount==nil and 1 or amount
 if not finite(amount) or amount<=0 or amount%1~=0 then return false end
 local cap=self.ctx.Config.ProgressStatCap or 1e9
 local progress=ensure(state.Profile)
 progress.Stats[stat]=math.min(cap,counter(progress.Stats[stat],cap)+amount)
 return true
end

function Progression:Current(state,stat)
 if not state or type(state.Profile)~="table" then return 0 end
 if stat=="Discoveries" then
  local discovered=state.Profile.Discovered
  if type(discovered)~="table" then return 0 end
  local total=0
  for i in ipairs(self.ctx.Config.Species) do
   if discovered[tostring(i)]==true or discovered[i]==true then total+=1 end
  end
  return total
 end
 if not supportedStats[stat] then return 0 end
 local progress=state.Profile.Progress
 local stats=type(progress)=="table" and progress.Stats
 return counter(type(stats)=="table" and stats[stat],self.ctx.Config.ProgressStatCap or 1e9)
end

function Progression:Snapshot(state)
 local result={}
 if not state or type(state.Profile)~="table" then return result end
 local progress=state.Profile.Progress
 local claimed=type(progress)=="table" and progress.Claimed
 for _,mission in ipairs(self.ctx.Config.Missions or {}) do
  local target=counter(mission.Target,self.ctx.Config.ProgressStatCap or 1e9)
  local current=self:Current(state,mission.Stat)
  table.insert(result,{Id=mission.Id,Current=math.min(current,target),Target=target,
   Complete=target>0 and current>=target,Claimed=type(claimed)=="table" and claimed[mission.Id]==true or false})
 end
 return result
end

function Progression:Claim(state,id)
 if not state or type(state.Profile)~="table" or not state.Ready or state.Leaving then return false,"Aguarde sua base carregar." end
 if state.OperationBusy or (state.Runtime and state.Runtime.TransferCommitting) then return false,"Aguarde a operação atual terminar." end
 if state.Carry then return false,"Entregue ou abandone o transporte antes de resgatar." end
 if (state.LastCombat or 0)>0 and os.clock()-state.LastCombat<self.ctx.Config.CombatLock then
  return false,"Aguarde o fim do combate para resgatar a recompensa."
 end
 if type(id)~="string" then return false,"Missão desconhecida." end
 local selected
 for _,mission in ipairs(self.ctx.Config.Missions or {}) do if mission.Id==id then selected=mission break end end
 if not selected then return false,"Missão desconhecida." end
 local progress=ensure(state.Profile)
 if progress.Claimed[id]==true then return false,"Essa recompensa já foi resgatada." end
 local target=counter(selected.Target,self.ctx.Config.ProgressStatCap or 1e9)
 if target<1 or self:Current(state,selected.Stat)<target then return false,"Conclua o objetivo antes de resgatar." end
 local inventory=state.Profile.Inventory
 if type(inventory)~="table" or type(selected.Rewards)~="table" then return false,"Recompensa indisponível." end
 local rewards={}
 for kind,amount in pairs(selected.Rewards) do
  if not self.ctx.Config.Items[kind] or not finite(amount) or amount<=0 or amount%1~=0 then return false,"Recompensa indisponível." end
  local current=inventory[kind] or 0
  if not finite(current) or current<0 or current%1~=0 then return false,"Inventário indisponível." end
  if current+amount>500 then return false,"Libere espaço no inventário antes de resgatar (limite de 500 por peça)." end
  if kind=="Habitat" then
   local total=current+amount
   for _,build in ipairs(state.Profile.Builds or {}) do if build.Kind=="Habitat" then total+=1 end end
   if total>self.ctx.Config.MaxHabitats then return false,"Você já possui o limite de habitats." end
  end
  rewards[kind]=amount
 end
 if next(rewards)==nil then return false,"Recompensa indisponível." end
 -- No yield between acknowledgement and all inventory grants: rapid requests cannot
 -- claim twice, and a capacity refusal above has changed neither side.
 progress.Claimed[id]=true
 for kind,amount in pairs(rewards) do inventory[kind]=(inventory[kind] or 0)+amount end
 return true,"Recompensa resgatada! As peças foram adicionadas ao inventário."
end

return Progression
