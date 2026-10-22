-- Data-only, opt-in regression cases. Every IO operation below uses a fake Store.
-- Called by StudioRegression; requiring this module does not run a test or write data.
local Persistence=require(script.Parent.Persistence)
local QA={}

local function copy(value)
 if type(value)~="table" then return value end
 local result={};for k,v in pairs(value) do result[k]=copy(v) end;return result
end
local function fakeStore()
 local store={Records={},Writes=0,Attempts=0,Reads=0}
 function store:GetAsync(key)
  self.Reads+=1
  if self.BeforeRead then self:BeforeRead(key) end
  return copy(self.Records[key])
 end
 function store:UpdateAsync(key,callback)
  self.Attempts+=1
  local before=copy(self.Records[key])
  if self.BeforeWrite then self:BeforeWrite(key,before) end
  local after=callback(copy(before))
  if after==nil then return nil end
  self.Records[key]=copy(after);self.Writes+=1
  if self.AfterWrite then self:AfterWrite(key,before,after) end
  return copy(after)
 end
 return store
end
local function isolatedPersistence(config,store,session)
 -- Do not call .new: this test never even obtains a real DataStore handle.
 local p=setmetatable({Ctx={Config=config,Toast=function() end},Session=session or "persistence-qa",
  Store=store,Meta={},Journals={},Active={},ActiveCreatures={},PendingReleases={}},Persistence)
 -- One attempt exposes lost acknowledgements to the actual fallback/recovery code.
 function p:Call(callback) return pcall(callback) end
 return p
end
local function profile(p,creatureId)
 local data=p:Default();data.StarterPlaced=true
 data.Builds={{Id="h1",Kind="Habitat",X=0,Z=16,R=0,Level=1},
  {Id="h2",Kind="Habitat",X=32,Z=16,R=0,Level=0},
  {Id="inc",Kind="Incubator",X=-32,Z=-40,R=0,Level=0}}
 if creatureId then data.Creatures={{Id=creatureId,Species=1,HabitatId="h1",Stored=3}} end
 return data
end
local function state(p,store,uid,data)
 local player={UserId=uid}
 store.Records["P:"..uid]={Profile=copy(data or profile(p)),Revision=0}
 local loaded,mode=p:Load(player)
 assert(loaded and mode=="Persistente","Fake profile failed to acquire its lease")
 return {Player=player,Profile=loaded,Pending={},Runtime={},Generation=1}
end
local function count(profileValue,id)
 local result=0
 for _,creature in ipairs(profileValue.Creatures) do if not id or creature.Id==id then result+=1 end end
 return result
end
local function journal(source,destination,id,target)
 return {Id=id,Status="Committed",Source=source,Destination=destination,DestinationHabitatId=target or "h1",
  Creature={Id="transferred",Species=1,HabitatId="h1",Stored=3}}
end

function QA.Run(ctx,expect)
 assert(game:GetService("RunService"):IsStudio(),"Persistence QA is Studio-only")
 local checks=0
 local function check(value,label)
  expect(value,"Persistence: "..label);checks+=1
 end

 -- A lost Pending write acknowledgement cannot remove source ownership or strand a lock.
 do
  local store=fakeStore();local p=isolatedPersistence(ctx.Config,store,"qa-begin")
  local source=state(p,store,-951001,profile(p,"begin-creature"))
  local destination=state(p,store,-951002,profile(p))
  local lost=false
  function store:AfterWrite(key,_,after)
   if key=="T:begin-lost" and after.Status=="Pending" and not lost then lost=true;error("Injected acknowledgement loss after Pending journal write") end
  end
  local begun=p:BeginTransfer(source,destination,source.Profile.Creatures[1],"begin-lost")
  check(begun==false and store.Records["T:begin-lost"].Status=="Pending","lost begin acknowledgement refuses pickup after its durable journal write")
  check(count(source.Profile,"begin-creature")==1 and count(destination.Profile)==0 and not p.ActiveCreatures["begin-creature"],"failed begin keeps original creature once and releases active creature lock")
  check(p:CancelTransfer({TransferId="begin-lost"})==true and store.Records["T:begin-lost"].Status=="Cancelled","unacknowledged begin can be safely cancelled")
 end

 -- Commit is decided by the journal even if acknowledgement and both profile writes fail.
 do
  local store=fakeStore();local p=isolatedPersistence(ctx.Config,store,"qa-commit")
  local source=state(p,store,-952001,profile(p,"commit-creature"))
  local destination=state(p,store,-952002,profile(p))
  check(p:BeginTransfer(source,destination,source.Profile.Creatures[1],"commit-lost"),"begin durably records transfer references in both profiles")
  local lost=false
  function store:AfterWrite(key,_,after)
   if key=="T:commit-lost" and after.Status=="Committed" and not lost then lost=true;error("Injected acknowledgement loss after committed decision") end
  end
  function store:BeforeWrite(key)
   if string.sub(key,1,2)=="P:" then error("Injected profile-save interruption after journal commit") end
  end
  local committed=p:CommitTransfer(source,destination,{TransferId="commit-lost",DestinationHabitatId="h1"})
  check(committed==true and lost and store.Reads>0,"commit lost acknowledgement reads its authoritative decision")
  check(count(source.Profile,"commit-creature")==0 and count(destination.Profile,"commit-creature")==1,"commit changes in-memory ownership exactly once despite interrupted saves")
  local cancelled,status=p:CancelTransfer({TransferId="commit-lost"})
  check(cancelled==false and status=="Committed" and store.Records["T:commit-lost"].Status=="Committed","late cancellation cannot undo a committed transfer")
  local recoveredSource=p:Normalize(store.Records["P:-952001"].Profile)
  local recoveredDestination=p:Normalize(store.Records["P:-952002"].Profile)
  local recovery=isolatedPersistence(ctx.Config,store,"qa-recover")
  check(recovery:Recover(recoveredSource,-952001,false) and recovery:Recover(recoveredDestination,-952002,false),"recovery completes both profiles from their pre-commit references")
  check(count(recoveredSource,"commit-creature")==0 and count(recoveredDestination,"commit-creature")==1,"recovered ownership exists in exactly one profile")
  local reads=store.Reads
  check(recovery:Recover(recoveredSource,-952001,false) and recovery:Recover(recoveredDestination,-952002,false)
   and count(recoveredDestination,"commit-creature")==1 and store.Reads==reads,"per-profile Applied acknowledgement makes recovery idempotent")
  recoveredDestination.Rebirths+=1;recoveredDestination.Creatures={}
  check(recovery:Recover(recoveredDestination,-952002,false) and count(recoveredDestination)==0,"rebirth retaining Applied references never resurrects an old arrival")
 end

 -- A committed arrival never overwrites a current creature or an incubating egg.
 do
  local store=fakeStore();local p=isolatedPersistence(ctx.Config,store,"qa-space")
  store.Records["T:space"]=journal(-953001,-953002,"space","h1")
  local occupied=profile(p,"existing");occupied.TransferRefs.space=true
  check(p:Recover(occupied,-953002,false) and count(occupied,"existing")==1 and count(occupied,"transferred")==1
   and occupied.Creatures[2].HabitatId=="h2","occupied recorded destination selects another free habitat without replacing its creature")
  local pending=profile(p);pending.TransferRefs.space=true
  pending.Incubations={{Id="existing-egg",Species=1,HabitatId="h1",IncubatorId="inc",Remaining=7}}
  check(p:Recover(pending,-953002,false) and pending.Creatures[1].HabitatId=="h2"
   and pending.Incubations[1].Id=="existing-egg","pending incubation reserves its habitat during committed recovery")
  local full=profile(p,"existing");full.TransferRefs.space=true
  full.Incubations={{Id="other-egg",Species=1,HabitatId="h2",IncubatorId="inc",Remaining=7}}
  local writes=store.Writes
  local ok=p:Recover(full,-953002,false)
  check(ok==false and count(full)==1 and full.Creatures[1].Id=="existing" and full.Incubations[1].Id=="other-egg"
   and full.TransferRefs.space==true and store.Writes==writes,"full destination fails without deleting content, acknowledging arrival, or overwriting durable data")
 end

 -- An unfinished carry resolves back to the source, once, on either player's rejoin.
 do
  local store=fakeStore();local p=isolatedPersistence(ctx.Config,store,"qa-pending")
  store.Records["T:pending"]={Id="pending",Status="Pending",Source=-954001,Destination=-954002,
   Creature={Id="pending-creature",Species=1,HabitatId="h1",Stored=2}}
  local source=profile(p);source.TransferRefs.pending=true
  local destination=profile(p);destination.TransferRefs.pending=true
  check(p:Recover(source,-954001,false) and p:Recover(destination,-954002,false),"interrupted carry cancellation permits both profile recoveries")
  check(count(source,"pending-creature")==1 and count(destination,"pending-creature")==0
   and store.Records["T:pending"].Status=="Cancelled","interrupted carry belongs only to original owner after recovery")
  local laterArrival=profile(p,"pending-creature")
  laterArrival.TransferRefs.pending=true;laterArrival.TransferRefs["later-committed"]="Applied"
  check(p:Recover(laterArrival,-954002,false) and count(laterArrival,"pending-creature")==1,
   "an old cancelled attempt cannot delete ownership received by a later committed theft")
 end

 -- Failed loading must never turn an existing profile into a default new profile.
 do
  local store=fakeStore();local p=isolatedPersistence(ctx.Config,store,"qa-load")
  local original=profile(p,"load-creature");original.Cash=4321
  store.Records["P:-955001"]={Profile=copy(original),Revision=9}
  function store:BeforeWrite() error("Injected datastore transport failure") end
  local loaded=p:Load({UserId=-955001})
  check(loaded==nil and store.Writes==0 and store.Records["P:-955001"].Profile.Cash==4321
   and count(store.Records["P:-955001"].Profile,"load-creature")==1,"failed profile acquisition preserves existing progress and performs no replacement write")
  store.BeforeWrite=nil
  store.Records["P:-955001"].Lease={Owner="another-live-server",Expires=os.time()+60}
  loaded=p:Load({UserId=-955001})
  check(loaded==nil and store.Writes==0 and store.Records["P:-955001"].Lease.Owner=="another-live-server","foreign live lease refuses load without stealing lease or replacing progress")
  store.Records["P:-955001"].Lease=nil
  store.Records["P:-955001"].Profile.TransferRefs["unreadable-journal"]=true
  function store:BeforeRead() error("Injected journal read failure") end
  loaded=p:Load({UserId=-955001})
  local record=store.Records["P:-955001"]
  check(loaded==nil and not record.Lease and record.Profile.Cash==4321 and count(record.Profile,"load-creature")==1
   and record.Profile.TransferRefs["unreadable-journal"]==true,"failed recovery releases lease without saving a partially recovered/default profile")
 end

 -- Failed final save survives removal of all references to the live state.
 do
  local store=fakeStore();local p=isolatedPersistence(ctx.Config,store,"qa-release")
  local leaving=state(p,store,-956001,profile(p,"leave-creature"))
  leaving.Profile.Cash=9876
  leaving.Pending.h2={Id="leave-egg",Species=2,IncubatorId="inc",EndsAt=os.clock()+13}
  leaving.Runtime={PacketGeneration=1,ResourcePackets={{Id="leave-packet",CreatureId="leave-creature",Species=1,
   Value=32,Remaining=2,Lifetime=0,Path={{X=0,Z=0},{X=0,Z=-4}}}}}
  local fail=true
  function store:BeforeWrite(key)
   if key=="P:-956001" and fail then fail=false;error("Injected final-save failure") end
  end
  check(p:Release(leaving)==false and p.PendingReleases[-956001]~=nil,"failed disconnect save retains a frozen retry snapshot")
  leaving.Profile.Cash=0;leaving.Profile.Creatures={};leaving.Pending={};leaving.Runtime={}
  check(p:Load(leaving.Player)==nil,"same-server rejoin cannot bypass a pending final save")
  check(p:RetryPending()==true and not p.Meta[-956001] and not p.PendingReleases[-956001],"retry completes final save and releases its old lease")
  local saved=store.Records["P:-956001"].Profile
  check(saved.Cash==9876 and count(saved,"leave-creature")==1 and #saved.Incubations==1
   and saved.Incubations[1].Remaining>12 and #saved.ResourceEscrow==1,"retry preserves creature, incomplete incubation and unpaid packet after live state is cleared")
  local writes=store.Writes
  check(p:RetryPending()==true and store.Writes==writes,"repeated final-save retry cannot replay snapshot or payment")
  local restored={Profile=p:Normalize(saved),Pending={}}
  p:RestoreIncubations(restored)
  check(restored.Pending.h2 and restored.Pending.h2.EndsAt-os.clock()>12 and count(restored.Profile)==1,
   "interrupted-save incubation resumes connected seconds without early hatch")
 end

 -- A successful release with lost acknowledgement must not write over a new owner.
 do
  local store=fakeStore();local p=isolatedPersistence(ctx.Config,store,"qa-release-ack")
  local leaving=state(p,store,-957001,profile(p,"ack-creature"))
  local lost=false
  function store:AfterWrite(key,before,after)
   if key=="P:-957001" and before and before.Lease and not after.Lease and not lost then
    lost=true;error("Injected acknowledgement loss after lease release")
   end
  end
  check(p:Release(leaving)==false and p.PendingReleases[-957001].WithoutSave==true,
   "lost lease-release acknowledgement retries release without resaving snapshot")
  store.Records["P:-957001"].Lease={Owner="new-server",Expires=os.time()+60}
  store.Records["P:-957001"].Profile.Cash=5555
  local writes=store.Writes
  check(p:RetryPending()==true and not p.Meta[-957001] and not p.PendingReleases[-957001]
   and store.Writes==writes and store.Records["P:-957001"].Profile.Cash==5555
   and store.Records["P:-957001"].Lease.Owner=="new-server","lost-ack retry retires old metadata without writing over a new lease owner")
 end

 -- Saved uncredited packet IDs are unique and every persisted numeric value is finite.
 do
  local store=fakeStore();local p=isolatedPersistence(ctx.Config,store,"qa-escrow")
  local raw=profile(p)
  raw.ResourceEscrow={{Id="one",CreatureId="c",Species=1,Value=32,Remaining=2},
   {Id="one",CreatureId="c",Species=1,Value=999,Remaining=2},
   {Id="invalid",CreatureId="c",Species=99,Value=0/0,Remaining=math.huge},
   {Id="negative",CreatureId="c",Species=1,Value=-50,Remaining=-2}}
  local clean=p:Normalize(raw)
  check(#clean.ResourceEscrow==3 and clean.ResourceEscrow[1].Value==32,"duplicate escrow IDs normalize to one unpaid packet")
  local valid=true
  for _,packet in ipairs(clean.ResourceEscrow) do
   if packet.Value~=packet.Value or packet.Value<0 or packet.Value==math.huge or packet.Remaining<0
    or packet.Remaining==math.huge or packet.Species<1 or packet.Species>7 then valid=false end
  end
  check(valid,"escrow normalization rejects nonfinite values and clamps malformed fields")
  raw.ResourceEscrow={}
  for i=1,270 do table.insert(raw.ResourceEscrow,{Id="bounded-"..i,CreatureId="c",Species=1,Value=32,Remaining=2}) end
  check(#p:Normalize(raw).ResourceEscrow==256,"uncredited packet persistence is bounded to runtime queue capacity")
 end
 return {Checks=checks,RealDataStoreWrites=0}
end

return QA
