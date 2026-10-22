-- Pure placement/routing/production checks; no Instances, players, or DataStore IO.
local RS=game:GetService("ReplicatedStorage")
local Rules=require(RS:WaitForChild("EggTycoonV3").Shared.BuildRules)
local Production=require(script.Parent.Production)
local QA={}
local function copy(value)
 if type(value)~="table" then return value end
 local result={};for k,v in pairs(value) do result[k]=copy(v) end;return result
end
local function build(id,kind,x,z,r)
 return {Id=id,Kind=kind,X=x,Z=z,R=r or 0,Level=0}
end
local function starter()
 return {build("h","Habitat",0,16),build("b1","Belt",0,0),build("b2","Belt",0,-4),build("b3","Belt",0,-8),
  build("p","Processor",0,-16),build("b4","Belt",0,-24),build("b5","Belt",0,-28),build("s","Seller",0,-36),
  build("i","Incubator",-32,-40)}
end
function QA.Run(parentContext,expect)
 local checks=0
 local function check(value,label) expect(value,"Rules: "..label);checks+=1 end
 local C=parentContext.Config
 local ctx={Config=C,States={},Remotes={FX={FireAllClients=function() end}}}
 local production=Production.new(ctx)
 local function state(layout)
  local s={Player={UserId=-920001},Plot={},PlotId=1,Generation=1,Runtime={BuildVersion=1},
   Profile={Cash=0,Rebirths=0,ProcessorLevel=1,Builds=copy(layout),Creatures={{Id="producer",Species=1,HabitatId="h",Stored=0}},ResourceEscrow={}}}
  ctx.States={[-920001]=s};return s
 end
 local layout=starter()
 check(Rules.Validate(layout),"starter layout leaves a walkable entrance and valid footprints")
 local route=Rules.Trace(layout,"h")
 check(route and route.Processed and route.ProcessorCount==1 and route.SellerId=="s","starter graph reaches a seller through basic processing")
 local disconnected=copy(layout);disconnected[3].R=1
 check(not Rules.Trace(disconnected,"h"),"rotating one belt to an incompatible direction breaks the route")
 local wrongProcessor=copy(layout);wrongProcessor[5].R=2
 check(not Rules.Trace(wrongProcessor,"h"),"a reversed processor cannot accept a visually adjacent conveyor")
 local missingSeller=copy(layout);table.remove(missingSeller,8)
 local s=state(missingSeller)
 check(production:Income(s)==0 and not Rules.Trace(missingSeller,"h"),"processed material without a seller generates no income")
 local unprocessed={build("h","Habitat",0,16),build("b1","Belt",0,0),build("b2","Belt",0,-4),build("b3","Belt",0,-8),build("s","Seller",0,-16)}
 s=state(unprocessed);production:Step(s,4)
 check(not Rules.Trace(unprocessed,"h") and production:Income(s)==0 and s.Profile.Cash==0 and #s.Runtime.ResourcePackets==0,"a seller directly attached to raw resources cannot pay")
 local cycle={build("h","Habitat",0,16),build("a","Merge",0,0),build("b","Curve",0,-4,1),build("c","Curve",-4,-4,2),build("d","Curve",-4,0,3)}
 check(Rules.Validate(cycle),"a physically legal loop can be placed without overlapping machines")
 local loopRoute,loopReason=Rules.Trace(cycle,"h")
 check(not loopRoute and type(loopReason)=="string" and loopReason:find("fechado",1,true),"directed conveyor loop terminates with a closed-circuit error")
 s=state(cycle)
 for _=1,25 do production:Step(s,4) end
 check(s.Profile.Cash==0 and #s.Runtime.ResourcePackets==0 and production:Income(s)==0,"cycles cannot mint packets, money, or displayed income")
 check(s.Profile.Creatures[1].Stored==20,"disconnected habitat buffers at most twenty resources")
 production:Step(s,4)
 check(s.Profile.Creatures[1].Stored==20 and s.Profile.Cash==0,"a full disconnected habitat pauses further accumulation")
 s.Profile.Builds=starter();s.Runtime.BuildVersion+=1
 for _=1,20 do production:Step(s,0) end
 check(s.Profile.Creatures[1].Stored==0 and #s.Runtime.ResourcePackets==20 and s.Profile.Cash==0,"reconnection moves the twenty stored resources into unpaid transport exactly once")
 local ids={};local unique=true
 for _,packet in ipairs(s.Runtime.ResourcePackets) do if ids[packet.Id] then unique=false end;ids[packet.Id]=true end
 check(unique,"every queued resource has a unique server packet identifier")
 s.Profile.Builds=copy(s.Profile.Builds);s.Runtime.BuildVersion+=1
 production:Step(s,0);production:Step(s,0)
 check(#s.Runtime.ResourcePackets==20 and s.Profile.Creatures[1].Stored==0 and s.Profile.Cash==0,"rebuilding the same graph cannot duplicate outstanding resource packets")
 production:Step(s,3)
 local expected=20*C.Species[1].Rate*4
 check(s.Profile.Cash==expected and #s.Runtime.ResourcePackets==0,"all twenty reconnected resources pay their configured value once after transport")
 s.Profile.Builds=copy(s.Profile.Builds);s.Runtime.BuildVersion+=1;production:Step(s,0)
 check(s.Profile.Cash==expected and #s.Runtime.ResourcePackets==0,"another graph rebuild cannot replay already sold resources")
 local fresh=state(layout);production:Step(fresh,3)
 check(fresh.Profile.Cash==0 and fresh.Profile.Creatures[1].Stored==0 and #fresh.Runtime.ResourcePackets==0,"connected habitat creates no resource before the four-second production interval")
 production:Step(fresh,1)
 check(fresh.Profile.Cash==0 and #fresh.Runtime.ResourcePackets==1 and fresh.Runtime.ResourcePackets[1].Value==C.Species[1].Rate*4,"four seconds creates an unpaid basic-processing packet instead of direct money")
 local twice={build("h","Habitat",0,48),build("b1","Belt",0,32),build("b2","Belt",0,28),build("b3","Belt",0,24),
  build("p1","Processor",0,16),build("b4","Belt",0,8),build("b5","Belt",0,4),build("p2","Processor",0,-4),
  build("b6","Belt",0,-12),build("b7","Belt",0,-16),build("s","Seller",0,-24)}
 local twiceRoute=Rules.Trace(twice,"h")
 local twiceState=state(twice)
 check(Rules.Validate(twice) and twiceRoute and twiceRoute.ProcessorCount==2 and production:Income(twiceState)==C.Species[1].Rate,"adding duplicate basic processors cannot multiply the same resource value")

 local invalid=copy(layout);invalid[2].Id="h"
 check(not Rules.Validate(invalid),"duplicate construction identifiers are rejected")
 invalid=copy(layout);invalid[2].X=2
 check(not Rules.Validate(invalid),"off-grid construction coordinates are rejected")
 invalid=copy(layout);invalid[2].X=0/0
 check(not Rules.Validate(invalid),"NaN placement payloads are rejected")
 invalid=copy(layout);invalid[2].R=.5
 check(not Rules.Validate(invalid),"non-quarter-turn rotations are rejected")
 check(not Rules.Validate(layout,build("overlap","Incubator",0,16)),"overlapping machine footprints are rejected")
 check(not Rules.Validate(layout,build("outside","Habitat",72,32)),"footprints crossing the interior perimeter are rejected")
 check(not Rules.Validate({},build("entry","Processor",0,-64)),"the fixed entry and delivery area remains clear")
 local nine={}
 for row=0,2 do for column=0,2 do table.insert(nine,build("h"..#nine,"Habitat",-48+column*32,-20+row*32)) end end
 local nineOK,nineReason=Rules.Validate(nine)
 check(not nineOK and nineReason:find("oito",1,true),"a ninth otherwise separate habitat exceeds the capacity cap")
 table.remove(nine)
 check(Rules.Validate(nine),"eight separated habitats remain a legal expandable layout")
 local barrier={}
 for x=-60,60,24 do table.insert(barrier,build("wall"..x,"Habitat",x,-40)) end
 table.insert(barrier,build("blocked","Habitat",0,20))
 local barrierOK,barrierReason=Rules.Validate(barrier)
 check(not barrierOK and barrierReason:find("caminho",1,true),"a complete machine barrier cannot cut the entrance off from a habitat")
 table.remove(barrier,3)
 check(Rules.Validate(barrier),"opening a real passage through the barrier restores legal access")
 return {Checks=checks,RealDataStoreWrites=0,InstancesCreated=0}
end
return QA
