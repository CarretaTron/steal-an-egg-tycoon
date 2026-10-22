-- Explicit Studio-only eight-player performance fixture. Never runs in a normal game.
local Run=game:GetService('RunService')
if not Run:IsStudio() then return end
local T=game:GetService('StudioTestService')
local ok,arg=pcall(function() return T:GetTestArgs() end)
if not ok or arg~='EggTycoonV3_Stress' then return end
local H=game:GetService('HttpService')
local ended=false
local ctx,original={},{}
local report={Suite='EightOccupiedPlots',Results={},PlayerCount=0,Creatures=0,Success=false}
local function copy(t) if type(t)~='table' then return t end local d={} for k,v in pairs(t) do d[k]=copy(v) end return d end
local function finish(err)
 if ended then return end ended=true workspace:SetAttribute('V3StressActive',false)
 if err then report.Error=tostring(err) end
 if ctx.States then for _,s in pairs(ctx.States) do
  if original[s.Player.UserId] then s.Profile=original[s.Player.UserId].Profile s.Pending=original[s.Player.UserId].Pending s.Generation+=1 ctx.Services.Building:Render(s) ctx.Services.Production:RenderCreatures(s) ctx:Sync(s) pcall(function() ctx.Services.Persistence:Save(s) end) end
 end end
 print('[EggTycoonV3 Stress] '..H:JSONEncode(report))
 pcall(function() T:EndTest(H:JSONEncode(report)) end)
end
task.delay(150,function() finish('Timeout') end)
local good,err=xpcall(function()
 local deadline=os.clock()+60
 repeat ctx=_G.EggTycoonV3 or {} task.wait(.1) until ctx.States or os.clock()>deadline
 assert(ctx.States,'Bootstrap unavailable')
 local states={}
 repeat
  states={} for _,s in pairs(ctx.States) do if s.Ready then table.insert(states,s) end end task.wait(.2)
 until #states>=8 or os.clock()>deadline
 assert(#states==8,'Eight ready players required')
 table.sort(states,function(a,b) return a.PlotId<b.PlotId end)
 local BuildRules=require(game:GetService('ReplicatedStorage').EggTycoonV3.Shared.BuildRules)
 report.PlayerCount=#states
 for _,s in ipairs(states) do
  original[s.Player.UserId]={Profile=copy(s.Profile),Pending=copy(s.Pending)}
  s.Profile=ctx.Services.Persistence:Default() s.Profile.Builds={} s.Profile.Inventory={} s.Pending={} s.Generation+=1
  local function build(kind,x,z)
   local b={Id=H:GenerateGUID(false),Kind=kind,X=x,Z=z,R=0} table.insert(s.Profile.Builds,b) return b
  end
  for row=1,2 do for lane=1,4 do
   local x=-48+(lane-1)*32 local z=row==1 and 52 or -16
   local habitat=build('Habitat',x,z)
   build('Belt',x,z-16) build('Belt',x,z-20)
   build('Processor',x,z-28)
   build('Belt',x,z-36) build('Belt',x,z-40)
   build('Seller',x,z-48)
   table.insert(s.Profile.Creatures,{Id=H:GenerateGUID(false),Species=((lane+(row-1)*4-1)%7)+1,HabitatId=habitat.Id,Stored=0})
  end end
  build('Incubator',0,-40)
  local valid,reason=BuildRules.Validate(s.Profile.Builds)
  assert(valid,'Invalid stress layout on plot '..s.PlotId..': '..tostring(reason))
  ctx.Services.Building:Render(s) ctx.Services.Production:RenderCreatures(s) ctx:Sync(s)
  report.Creatures+=#s.Profile.Creatures
 end
 local conn=ctx.Remotes.Command.OnServerEvent:Connect(function(player,action,payload)
  if action=='QAStressProbe' and type(payload)=='table' and ctx.States[player.UserId] then report.Results[tostring(player.UserId)]=payload end
 end)
 workspace:SetAttribute('V3StressActive',true)
 local timer=os.clock()+50
 repeat local n=0 for _ in pairs(report.Results) do n+=1 end if n>=8 then break end task.wait(.25) until os.clock()>timer
 conn:Disconnect()
 local count=0 local minFPS=math.huge
 for _,v in pairs(report.Results) do count+=1 minFPS=math.min(minFPS,v.AverageFPS or 0) end
 report.ClientReports=count report.MinimumAverageFPS=minFPS<math.huge and minFPS or 0
 report.Success=count==8 and report.Creatures==64
 finish()
end,debug.traceback)
if not good then finish(err) end
