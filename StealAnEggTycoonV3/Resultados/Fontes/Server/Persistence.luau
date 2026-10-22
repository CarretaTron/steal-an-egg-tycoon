-- Durable profiles and recoverable ownership transfers. The journal is authoritative.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Persistence = {}
Persistence.__index = Persistence
local progressStats={Hatches=true,Sales=true,ResourcesSold=true,HabitatUpgrades=true,BatteriesBroken=true}

local function copy(value)
 if type(value) ~= "table" then return value end
 local result = {}
 for k,v in pairs(value) do result[k] = copy(v) end
 return result
end
local function number(value, fallback, minimum, maximum)
 if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return fallback end
 return math.clamp(value,minimum or 0,maximum or 1e18)
end
local function apiDisabled(message)
 local text = string.lower(tostring(message))
 return text:find("studio access",1,true) or text:find("api services",1,true)
  or text:find("apienabled",1,true) or text:find("studioaccesstoapisnotallowed",1,true)
  or text:find("403",1,true)
end
local function findCreature(profile, id)
 for i,c in ipairs(profile.Creatures) do if c.Id == id then return c,i end end
end
local function removeCreature(profile,id)
 local _,i = findCreature(profile,id)
 if i then table.remove(profile.Creatures,i) end
end

function Persistence.new(ctx)
 local self=setmetatable({},Persistence)
 self.Ctx=ctx
 self.Session=(game.JobId~="" and game.JobId or HttpService:GenerateGUID(false))..":"..HttpService:GenerateGUID(false)
 self.Meta={}
 self.Journals={}
 self.Active={}
 self.ActiveCreatures={}
 self.PendingReleases={}
 self.Store=DataStoreService:GetDataStore(RunService:IsStudio() and ctx.Config.DataStoreName or ctx.Config.DataStoreName:gsub("_DEV","_LIVE"))
 return self
end

function Persistence:Default()
 return {Version=3,StarterPlaced=true,DefensesBuilt=true,Cash=0,Rebirths=0,SpeedLevel=0,WeaponLevel=0,BatteryLevel=1,ProcessorLevel=1,
  Discovered={},Progress={Stats={},Claimed={}},Inventory=copy(self.Ctx.Config.StarterInventory),Builds={},StoredHabitats={},Creatures={},Incubations={},ResourceEscrow={},TransferRefs={}}
end

function Persistence:Normalize(raw)
 if type(raw)~="table" then return self:Default() end
 local p=self:Default()
 -- Existing profiles have already received their kit; an empty saved layout can be intentional.
 p.StarterPlaced=raw.StarterPlaced~=false
 -- Walls and roof are part of every claimed plot, including saves from the optional-defense WIP.
 p.DefensesBuilt=true
 p.Cash=number(raw.Cash,0)
 p.Rebirths=math.floor(number(raw.Rebirths,0,0,100000))
 p.SpeedLevel=math.floor(number(raw.SpeedLevel,0,0,5))
 p.WeaponLevel=math.floor(number(raw.WeaponLevel,0,0,2))
 p.BatteryLevel=math.floor(number(raw.BatteryLevel,1,1,4))
 p.ProcessorLevel=math.floor(number(raw.ProcessorLevel,1,1,5))
 p.Discovered=type(raw.Discovered)=="table" and copy(raw.Discovered) or {}
 local progress=type(raw.Progress)=="table" and raw.Progress or {}
 for stat in pairs(progressStats) do
  p.Progress.Stats[stat]=math.floor(number(type(progress.Stats)=="table" and progress.Stats[stat],0,0,self.Ctx.Config.ProgressStatCap or 1e9))
 end
 for _,mission in ipairs(self.Ctx.Config.Missions or {}) do
  if type(mission.Id)=="string" and type(progress.Claimed)=="table" and progress.Claimed[mission.Id]==true then
   p.Progress.Claimed[mission.Id]=true
  end
 end
 p.Inventory={}
 for kind in pairs(self.Ctx.Config.Items) do
  p.Inventory[kind]=math.floor(number(type(raw.Inventory)=="table" and raw.Inventory[kind],0,0,100000))
 end
 local ids={}
 for _,b in ipairs(type(raw.Builds)=="table" and raw.Builds or {}) do
  if type(b)=="table" and type(b.Id)=="string" and not ids[b.Id] and self.Ctx.Config.Items[b.Kind] then
   ids[b.Id]=true
   table.insert(p.Builds,{Id=b.Id,Kind=b.Kind,X=number(b.X,0,-80,80),Z=number(b.Z,0,-80,80),R=math.floor(number(b.R,0,0,3)),Level=math.floor(number(b.Level,0,0,3))})
  end
 end
 for _,habitat in ipairs(type(raw.StoredHabitats)=="table" and raw.StoredHabitats or {}) do
  if #p.StoredHabitats>=math.min(8,p.Inventory.Habitat or 0) then break end
  if type(habitat)=="table" and type(habitat.Id)=="string" and habitat.Id~="" and not ids[habitat.Id] then
   ids[habitat.Id]=true
   table.insert(p.StoredHabitats,{Id=habitat.Id,Level=math.floor(number(habitat.Level,0,0,3))})
  end
 end
 ids={}
 for _,c in ipairs(type(raw.Creatures)=="table" and raw.Creatures or {}) do
  if type(c)=="table" and type(c.Id)=="string" and not ids[c.Id] and type(c.HabitatId)=="string" then
   ids[c.Id]=true
   table.insert(p.Creatures,{Id=c.Id,Species=math.floor(number(c.Species,1,1,7)),HabitatId=c.HabitatId,Stored=math.floor(number(c.Stored,0,0,20))})
  end
 end
 local habitats,incubators,occupied={},{},{}
 for _,build in ipairs(p.Builds) do
  if build.Kind=="Habitat" then habitats[build.Id]=true elseif build.Kind=="Incubator" then incubators[build.Id]=true end
 end
 for _,creature in ipairs(p.Creatures) do occupied[creature.HabitatId]=true end
 for _,pending in ipairs(type(raw.Incubations)=="table" and raw.Incubations or {}) do
  if type(pending)=="table" and type(pending.Id)=="string" and not ids[pending.Id]
   and habitats[pending.HabitatId] and incubators[pending.IncubatorId] and not occupied[pending.HabitatId] then
   local species=math.floor(number(pending.Species,1,1,7))
   ids[pending.Id]=true;occupied[pending.HabitatId]=true
   table.insert(p.Incubations,{Id=pending.Id,Species=species,HabitatId=pending.HabitatId,IncubatorId=pending.IncubatorId,
    Remaining=number(pending.Remaining,self.Ctx.Config.Species[species].Hatch,0,self.Ctx.Config.Species[species].Hatch)})
  end
 end
 local packetIds={}
 for _,packet in ipairs(type(raw.ResourceEscrow)=="table" and raw.ResourceEscrow or {}) do
  if #p.ResourceEscrow>=256 then break end
  if type(packet)=="table" and type(packet.Id)=="string" and packet.Id~="" and not packetIds[packet.Id]
   and type(packet.CreatureId)=="string" then
   packetIds[packet.Id]=true
   local path={}
   for _,point in ipairs(type(packet.Path)=="table" and packet.Path or {}) do
    if #path>=self.Ctx.Config.MaxBuilds*2+2 then break end
    if type(point)=="table" then table.insert(path,{X=number(point.X,0,-80,80),Z=number(point.Z,0,-80,80)}) end
   end
   table.insert(p.ResourceEscrow,{Id=packet.Id,CreatureId=packet.CreatureId,Species=math.floor(number(packet.Species,1,1,7)),
    Value=number(packet.Value,0),Remaining=number(packet.Remaining,1,0,25),Path=path})
  end
 end
 p.TransferRefs=type(raw.TransferRefs)=="table" and copy(raw.TransferRefs) or {}
 return p
end

function Persistence:Snapshot(state)
 local p=copy(state.Profile)
 p.Version=3
 p.TransferRefs=p.TransferRefs or {}
 -- Lobby states deliberately have no Pending/ResourcePackets runtime queues.
 -- Keep their saved incubation/escrow intact until a plot has been claimed.
 -- Only active base time advances incubation. Snapshotting never grants an early hatch.
 if state.Pending then
  p.Incubations={}
  for habitat,pending in pairs(state.Pending) do
   if pending.Id and not findCreature(p,pending.Id) then
    table.insert(p.Incubations,{Id=pending.Id,Species=pending.Species,HabitatId=habitat,IncubatorId=pending.IncubatorId,
     Remaining=math.max(0,pending.EndsAt-os.clock())})
   end
  end
 end
 -- A packet leaves Stored before entering this queue. Preserve only the unpaid queue,
 -- including packets whose producer was later stolen/released. Never touch the live queue.
 if state.Runtime and state.Runtime.ResourcePackets then
  p.ResourceEscrow={}
  if state.Runtime.PacketGeneration==state.Generation then
   for _,packet in ipairs(state.Runtime.ResourcePackets) do
    table.insert(p.ResourceEscrow,{Id=packet.Id,CreatureId=packet.CreatureId,Species=packet.Species,
     Value=packet.Value,Remaining=math.max(0,packet.Remaining),Path=copy(packet.Path or {})})
   end
  end
 end
 return p
end

function Persistence:RestoreIncubations(state)
 state.Pending=state.Pending or {}
 for _,pending in ipairs(state.Profile.Incubations or {}) do
  state.Pending[pending.HabitatId]={Id=pending.Id,Species=pending.Species,IncubatorId=pending.IncubatorId,
   EndsAt=os.clock()+pending.Remaining}
 end
 state.Profile.Incubations={}
end

function Persistence:Call(callback)
 local last
 for attempt=1,3 do
  local ok,result=pcall(callback)
  if ok then return true,result end
  last=result
  if apiDisabled(result) then break end
  if attempt<3 then task.wait(attempt) end
 end
 return false,tostring(last)
end

function Persistence:ReadJournal(id, session)
 if session then return true,self.Journals[id] end
 return self:Call(function() return self.Store:GetAsync("T:"..id) end)
end

function Persistence:Recover(profile, userId, session)
 for id,application in pairs(profile.TransferRefs or {}) do
  -- The per-profile acknowledgement belongs to the same atomic profile snapshot as
  -- the ownership change. Later release/rebirth must not replay an old arrival.
  if application=="Applied" then continue end
  local ok,journal=self:ReadJournal(id,session)
  if not ok then return false,"Não foi possível conferir uma transferência. Seu progresso foi preservado." end
  if journal and journal.Status=="Committed" then
   if journal.Source==userId then removeCreature(profile,journal.Creature.Id) end
   if journal.Destination==userId and not findCreature(profile,journal.Creature.Id) then
    local creature=copy(journal.Creature)
    creature.HabitatId=journal.DestinationHabitatId
    local occupied={}
    for _,owned in ipairs(profile.Creatures) do occupied[owned.HabitatId]=true end
    for _,pending in ipairs(profile.Incubations or {}) do occupied[pending.HabitatId]=true end
    local valid=false
    for _,build in ipairs(profile.Builds) do
     if build.Id==creature.HabitatId and build.Kind=="Habitat" and not occupied[build.Id] then valid=true end
    end
    if not valid then
     for _,build in ipairs(profile.Builds) do
      if build.Kind=="Habitat" and not occupied[build.Id] then creature.HabitatId=build.Id valid=true break end
     end
    end
    if not valid then return false,"Transferência preservada: nenhum habitat disponível para recuperação." end
    table.insert(profile.Creatures,creature)
   end
  elseif journal and journal.Status=="Pending" then
   -- Reconnecting invalidates an unfinished carry. Source retains ownership.
   if journal.Source==userId and not findCreature(profile,journal.Creature.Id) then table.insert(profile.Creatures,copy(journal.Creature)) end
   if journal.Destination==userId then removeCreature(profile,journal.Creature.Id) end
   local cancelled=self:CancelTransfer({TransferId=id})
   if not cancelled then return false,"Não foi possível resolver um transporte interrompido. Reconecte para tentar novamente; seus dados foram preservados." end
  end
  profile.TransferRefs[id]="Applied"
 end
 return true
end

function Persistence:Load(player)
 local uid=player.UserId
 if self.Meta[uid] then return nil,"Perfil já carregado." end
 local leased=false
 local refusal
 local ok,result=self:Call(function()
  leased=false refusal=nil
  return self.Store:UpdateAsync("P:"..uid,function(record)
   record=type(record)=="table" and record or {}
   local lease=record.Lease
   if lease and lease.Owner~=self.Session and number(lease.Expires,0)>os.time() then
    refusal="Seu perfil ainda está aberto em outro servidor. Aguarde alguns segundos."
    return nil
   end
   record.Profile=self:Normalize(record.Profile or (record.Version and record))
   record.Lease={Owner=self.Session,Expires=os.time()+self.Ctx.Config.ProfileLease}
   record.Revision=(record.Revision or 0)+1
   record.Schema=3
   leased=true
   return record
  end)
 end)
 if not ok then
  if RunService:IsStudio() and apiDisabled(result) then
   self.Meta[uid]={Session=true}
   warn("[EggTycoonV3] STUDIO SEM APIS: progresso apenas nesta sessão; nenhum dado publicado foi alterado. "..tostring(result))
   return self:Default(),"Sessão • APIs do Studio desativadas"
  end
  warn("[EggTycoonV3] Load recusado, sem sobrescrever dados: "..tostring(result))
  return nil,"Falha ao carregar progresso. Reconecte; os dados existentes foram preservados."
 end
 if not leased or not result then return nil,refusal or "Não foi possível reservar seu perfil." end
 self.Meta[uid]={Session=false}
 local profile=self:Normalize(result.Profile)
 local recovered,message=self:Recover(profile,uid,false)
 if not recovered then
  self:Release({Player=player,Profile=profile,Pending={}} ,true)
  return nil,message
 end
 return profile,"Persistente"
end

function Persistence:Save(state)
 local uid=state.Player.UserId
 local meta=self.Meta[uid]
 if not meta or meta.Released then return false end
 if meta.Session then return true end
 if meta.Saving then
  -- Serialize saves so an older snapshot cannot overwrite a newer one.
  local deadline=os.clock()+12
  repeat task.wait(.1) until not meta.Saving or os.clock()>deadline
  if meta.Saving then return false end
 end
 meta.Saving=true
 local snapshot=self:Snapshot(state)
 local wrote=false
 local ok,err=self:Call(function()
  wrote=false
  return self.Store:UpdateAsync("P:"..uid,function(record)
   if type(record)~="table" or not record.Lease or record.Lease.Owner~=self.Session then return nil end
   record.Profile=snapshot
   record.Lease.Expires=os.time()+self.Ctx.Config.ProfileLease
   record.Revision=(record.Revision or 0)+1
   wrote=true
   return record
  end)
 end)
 meta.Saving=false
 if not ok or not wrote then
  warn("[EggTycoonV3] Save preservado para nova tentativa: "..tostring(err))
  self.Ctx:Toast(state.Player,"Conexão de salvamento instável. Tentando novamente; mantenha-se conectado.")
  return false
 end
 return true
end

function Persistence:QueueRelease(state, withoutSave)
 local uid=state.Player.UserId
 if self.PendingReleases[uid] then
  if withoutSave then self.PendingReleases[uid].WithoutSave=true end
  return
 end
 -- Keep the data even after Bootstrap frees the physical plot. No live timers or
 -- packet queues are attached to this frozen snapshot, so retries cannot consume twice.
 self.PendingReleases[uid]={State={Player=state.Player,Profile=self:Snapshot(state)},WithoutSave=withoutSave==true}
end

function Persistence:Release(state, withoutSave)
 local uid=state.Player.UserId
 local meta=self.Meta[uid]
 if not meta then return end
 if meta.Session then self.Meta[uid]=nil;self.PendingReleases[uid]=nil return true end
 local saved=withoutSave or self:Save(state)
 if not saved then self:QueueRelease(state,withoutSave) return false end
 local released=false
 local ok=self:Call(function()
  released=false
  return self.Store:UpdateAsync("P:"..uid,function(record)
   if record and record.Lease and record.Lease.Owner==self.Session then record.Lease=nil;released=true;return record end
   -- A response may be lost after a successful release. Never overwrite a new owner.
   if record and (not record.Lease or record.Lease.Owner~=self.Session) then released=true end
   return nil
  end)
 end)
 if ok and released then
  meta.Released=true;self.Meta[uid]=nil;self.PendingReleases[uid]=nil
  return true
 end
 -- The snapshot already succeeded. Retry only lease release, including the case
 -- where the release write succeeded but its acknowledgement was lost.
 self:QueueRelease(state,true)
 return false
end

function Persistence:RetryPending()
 if self.RetryBusy then return false end
 self.RetryBusy=true
 local complete=true
 for uid,entry in pairs(self.PendingReleases) do
  if not self.Meta[uid] then self.PendingReleases[uid]=nil else
   local ok,released=pcall(function() return self:Release(entry.State,entry.WithoutSave) end)
   if not ok or not released then complete=false end
  end
 end
 self.RetryBusy=false
 return complete
end

function Persistence:BeginTransfer(source,destination,creature,id)
 if source==destination or type(id)~="string" or id=="" then return false end
 if self.ActiveCreatures[creature.Id] then return false end
 local srcMeta,dstMeta=self.Meta[source.Player.UserId],self.Meta[destination.Player.UserId]
 if not srcMeta or not dstMeta or srcMeta.Session~=dstMeta.Session then return false end
 local journal={Id=id,Status="Pending",Source=source.Player.UserId,Destination=destination.Player.UserId,
  Creature=copy(creature),CreatedAt=os.time(),Session=self.Session}
 self.ActiveCreatures[creature.Id]=id
 self.Active[id]=journal
 local created=true
 if srcMeta.Session then self.Journals[id]=journal else
  local ok,stored=self:Call(function()
   return self.Store:UpdateAsync("T:"..id,function(old)
    if old then return nil end
    return journal
   end)
  end)
  created=ok and stored~=nil
 end
 if not created then self.Active[id]=nil self.ActiveCreatures[creature.Id]=nil return false end
 source.Profile.TransferRefs=source.Profile.TransferRefs or {}
 destination.Profile.TransferRefs=destination.Profile.TransferRefs or {}
 source.Profile.TransferRefs[id]=true destination.Profile.TransferRefs[id]=true
 local savedSource=self:Save(source)
 local savedDestination=self:Save(destination)
 if not savedSource or not savedDestination then self:CancelTransfer({TransferId=id}) return false end
 if self.Active[id]~=journal or journal.Status~="Pending" then return false end
 return true
end

function Persistence:CommitTransfer(source,destination,carry)
 local id=carry.TransferId
 local journal=self.Active[id]
 if not journal then
  local meta=self.Meta[source.Player.UserId]
  local ok,stored=self:ReadJournal(id,meta and meta.Session)
  if not ok or not stored then return false end
  journal=stored
 end
 if journal.Source~=source.Player.UserId or journal.Destination~=destination.Player.UserId then return false end
 if journal.Status=="Cancelled" then return false end
 local target=carry.DestinationHabitatId
 if type(target)~="string" then return false end
 if (destination.Profile.TransferRefs or {})[id]~="Applied" then
  for _,creature in ipairs(destination.Profile.Creatures) do
   if creature.HabitatId==target and creature.Id~=journal.Creature.Id then return false end
  end
 end
 local committed=copy(journal)
 committed.Status="Committed"
 committed.DestinationHabitatId=target
 committed.CommittedAt=os.time()
 local meta=self.Meta[source.Player.UserId]
 if not meta then return false end
 journal.Status="Committing"
 if meta.Session then self.Journals[id]=committed else
  local ok,stored=self:Call(function()
   return self.Store:UpdateAsync("T:"..id,function(old)
    if not old or old.Status=="Cancelled" then return nil end
    if old.Status=="Committed" then return old end
    return committed
   end)
  end)
  if not ok or not stored or stored.Status~="Committed" then
   -- A failed response can follow a successful write. Read the authority before reporting failure.
   local readOk,authority=self:ReadJournal(id,false)
   if not readOk or not authority or authority.Status~="Committed" then journal.Status="Uncertain" return false end
   stored=authority
  end
  committed=stored
 end
 -- No yield between ownership removal and insertion.
 source.Profile.TransferRefs=source.Profile.TransferRefs or {}
 destination.Profile.TransferRefs=destination.Profile.TransferRefs or {}
 if source.Profile.TransferRefs[id]~="Applied" then
  removeCreature(source.Profile,committed.Creature.Id)
  source.Profile.TransferRefs[id]="Applied"
 end
 if destination.Profile.TransferRefs[id]~="Applied" then
  if not findCreature(destination.Profile,committed.Creature.Id) then
   local creature=copy(committed.Creature)
   creature.HabitatId=committed.DestinationHabitatId
   table.insert(destination.Profile.Creatures,creature)
  end
  destination.Profile.TransferRefs[id]="Applied"
 end
 self.Active[id]=nil self.ActiveCreatures[committed.Creature.Id]=nil
 -- Both profiles already contain the durable journal reference. Recovery completes either failed write.
 self:Save(source)
 self:Save(destination)
 return true
end

function Persistence:CancelTransfer(carry)
 local id=carry and carry.TransferId
 if not id then return end
 local journal=self.Active[id] or self.Journals[id]
 if journal and (journal.Status=="Committed" or journal.Status=="Committing") then return false,journal.Status end
 if self.Journals[id] then
  self.Journals[id].Status="Cancelled"
 else
  local ok,stored=self:Call(function()
   return self.Store:UpdateAsync("T:"..id,function(old)
    if old and old.Status=="Committed" then return old end
    old=old or {Id=id}
    old.Status="Cancelled" old.CancelledAt=os.time()
    return old
   end)
  end)
  if not ok or not stored or stored.Status~="Cancelled" then return false,stored and stored.Status or "Uncertain" end
 end
 if journal then self.ActiveCreatures[journal.Creature.Id]=nil end
 self.Active[id]=nil
 return true
end

function Persistence:HasTransfer(state)
 for _,journal in pairs(self.Active) do
  if journal.Source==state.Player.UserId or journal.Destination==state.Player.UserId then return true end
 end
 return false
end

return Persistence
