-- One foreground Studio device-emulation client; eight fully populated server plots.
local Run=game:GetService("RunService")
if not Run:IsStudio() then return end
local T=game:GetService("StudioTestService")
local ok,arg=pcall(function() return T:GetTestArgs() end)
if not ok or arg~="EggTycoonV3_Mobile" then return end
local H=game:GetService("HttpService")
local RS=game:GetService("ReplicatedStorage")
local started=os.clock()
local ctx,real,original,connection
local ghosts={}
local ended,cleaning=false,false
local report={Suite="MobileForegroundEightPlots",Success=false,Players=1,GhostPlots=0,Creatures=0,Builds=0}
local function copy(t)
 if type(t)~="table" then return t end
 local result={};for k,v in pairs(t) do result[k]=copy(v) end;return result
end
local function removeGhosts()
 if not ctx then return end
 for uid,state in pairs(ghosts) do
  -- Remove the state before clearing its instances; shutdown cannot save a fixture.
  if ctx.States[uid]==state then ctx.States[uid]=nil end
  state.Ready=false;state.Leaving=true;state.OperationBusy=false
  for _,name in ipairs({"Structures","Creatures","Incubations"}) do
   local folder=state.Plot:FindFirstChild(name);if folder then folder:ClearAllChildren() end
  end
  state.Plot:SetAttribute("OwnerUserId",0)
  ghosts[uid]=nil
 end
end
local function cleanup()
 if cleaning then return end;cleaning=true
 workspace:SetAttribute("V3MobileActive",false)
 if connection then connection:Disconnect();connection=nil end
 removeGhosts()
 if ctx and real and original and ctx.States[real.Player.UserId]==real then
  real.Profile=original.Profile;real.Pending=original.Pending;real.Runtime=original.Runtime
  real.OperationBusy=original.OperationBusy;real.Generation+=1;real.LastCombat=original.LastCombat
  ctx.Services.Building:Render(real);ctx.Services.Production:RenderCreatures(real)
  ctx.Services.Combat:Reset(real);ctx:GrantTools(real);ctx:ApplySpeed(real);ctx:Sync(real)
  -- The fixture was never written. Restore the loaded profile under its original lease.
  local saved,saveResult=pcall(function() return ctx.Services.Persistence:Save(real) end)
  report.CleanupSaved=saved and saveResult==true
 end
end
local function finish(err)
 if ended then return end;ended=true
 if err then report.Error=tostring(err);report.Success=false end
 local cleaned,cleanError=pcall(cleanup)
 if not cleaned then report.CleanupError=tostring(cleanError);report.Success=false end
 report.Duration=math.floor((os.clock()-started)*100)/100
 print("[EggTycoonV3 Mobile] "..H:JSONEncode(report))
 pcall(function() T:EndTest(H:JSONEncode(report)) end)
end
-- Defensive shutdown cleanup; ghosts also have no persistence metadata and never autosave.
game:BindToClose(function() pcall(removeGhosts) end)
task.delay(110,function() finish("Overall timeout (110s)") end)

local good,err=xpcall(function()
 local deadline=os.clock()+55
 repeat ctx=_G.EggTycoonV3;task.wait(.1) until (ctx and ctx.States) or os.clock()>deadline
 assert(ctx and ctx.States,"Bootstrap unavailable")
 repeat
  for _,state in pairs(ctx.States) do if state.Ready and typeof(state.Player)=="Instance" then real=state;break end end
  if not real then task.wait(.1) end
 until real or os.clock()>deadline
 assert(real,"One ready real player required")
 assert(not real.Carry and not ctx:HasTransfer(real),"Mobile fixture requires no active transfer")
 original={Profile=copy(real.Profile),Pending=copy(real.Pending),Runtime=real.Runtime,OperationBusy=real.OperationBusy,LastCombat=real.LastCombat}
 real.OperationBusy=true
 real.Runtime={Saving=true}
 local Rules=require(RS.EggTycoonV3.Shared.BuildRules)
 local states={real}
 for plotId=1,8 do
  if plotId~=real.PlotId then
   local plot=ctx.World.Plots:FindFirstChild(string.format("Plot_%02d",plotId))
   assert(plot and (plot:GetAttribute("OwnerUserId") or 0)==0,"Expected vacant fixture plot "..plotId)
   local uid=-1000-plotId
   assert(not ctx.States[uid],"Ghost id already occupied")
   local fakePlayer={UserId=uid,DisplayName="Benchmark "..plotId,Name="Benchmark"..plotId,Character=nil,Parent=nil}
   local s={Player=fakePlayer,Plot=plot,PlotId=plotId,Profile=ctx.Services.Persistence:Default(),Carry=nil,
    LastCombat=0,Energy=100,LastAttack=0,Generation=1,Pending={},Runtime={Saving=true},SaveMode="Benchmark fixture",Ready=false,OperationBusy=true}
   ghosts[uid]=s;ctx.States[uid]=s;plot:SetAttribute("OwnerUserId",uid);table.insert(states,s)
  end
 end
 table.sort(states,function(a,b) return a.PlotId<b.PlotId end)
 for _,s in ipairs(states) do
  s.Profile=ctx.Services.Persistence:Default();s.Profile.Inventory={};s.Profile.Builds={};s.Pending={};s.Generation+=1
  s.LastCombat=0;s.Carry=nil
  ctx.Services.Combat:Reset(s)
  s.Runtime.Saving=true;s.OperationBusy=true
  local function build(kind,x,z)
   local b={Id=H:GenerateGUID(false),Kind=kind,X=x,Z=z,R=0};table.insert(s.Profile.Builds,b);return b
  end
  for row=1,2 do for lane=1,4 do
   local x=-48+(lane-1)*32;local z=row==1 and 52 or -16
   local habitat=build("Habitat",x,z)
   build("Belt",x,z-16);build("Belt",x,z-20);build("Processor",x,z-28)
   build("Belt",x,z-36);build("Belt",x,z-40);build("Seller",x,z-48)
   table.insert(s.Profile.Creatures,{Id=H:GenerateGUID(false),Species=((lane+(row-1)*4-1)%7)+1,HabitatId=habitat.Id,Stored=0})
  end end
  build("Incubator",0,-40)
  local valid,reason=Rules.Validate(s.Profile.Builds)
  assert(valid,"Invalid mobile fixture on plot "..s.PlotId..": "..tostring(reason))
  ctx.Services.Building:Render(s);ctx.Services.Production:RenderCreatures(s)
  s.Ready=true;ctx:Sync(s)
  report.Creatures+=#s.Profile.Creatures;report.Builds+=#s.Profile.Builds
  if s~=real then report.GhostPlots+=1 end
  task.wait()
 end
 report.RealPlotId=real.PlotId
 connection=ctx.Remotes.Command.OnServerEvent:Connect(function(player,action,payload)
  if player~=real.Player or action~="QADeviceProbe" or not workspace:GetAttribute("V3MobileActive") or type(payload)~="table" then return end
  if type(payload.AverageFPS)~="number" or payload.AverageFPS<0 or payload.AverageFPS>1000 or type(payload.Frames)~="number" or payload.Frames<1 then return end
  report.Client=payload
 end)
 workspace:SetAttribute("V3MobilePlotId",real.PlotId)
 workspace:SetAttribute("V3MobileActive",true)
 local measurementDeadline=os.clock()+32
 repeat if report.Client then break end;task.wait(.1) until os.clock()>measurementDeadline
 assert(report.Client,"Foreground client did not return QADeviceProbe within 32 seconds")
 report.MobileViewport=report.Client.ViewportX<=600 or report.Client.ViewportY<=450
 report.FPSAtLeast30=report.Client.AverageFPS>=30
 report.UIWithinViewport=report.Client.OverflowCount==0
 report.Success=report.GhostPlots==7 and report.Creatures==64 and report.Builds==456 and report.MobileViewport and report.Client.GUIExists==true and report.FPSAtLeast30 and report.UIWithinViewport
 finish()
end,debug.traceback)
if not good then finish(err) end
