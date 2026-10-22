"""Offline lifecycle regression using the current Luau sources and engine mocks.

Run: python StealAnEggTycoonV3/Tests/claim_lifecycle_offline.py --luau PATH_TO_LUAU
The harness reads the real modules and claim/rebirth functions on every run.
It does not use Studio, a network connection, or any DataStore.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

PROJECT = Path(__file__).resolve().parents[1]


def source(relative: str) -> str:
    return (PROJECT / relative).read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    """Isolate real local functions so their engine adapters can be mocked."""
    return text.split(start, 1)[1].split(end, 1)[0]


PREFIX = r'''
local passed=0
local function check(value,label)
 assert(value,label)
 passed+=1
 print("PASS",label)
end
local function deep(value)
 if type(value)~="table" then return value end
 local out={};for k,v in pairs(value) do out[k]=deep(v) end;return out
end
local copy=deep
local now=100
local os={clock=function() return now end,time=function() return 100000 end}
local task={wait=function() end,spawn=function(callback,...) callback(...) end}
local warn=function() end
local VectorMT={}
VectorMT.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},VectorMT) end
VectorMT.__index=function(v,k) if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end end
local Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},VectorMT) end}
local Color3={fromRGB=function(...) return {...} end}
local Players={}
local guid=0
local Http={GenerateGUID=function() guid+=1;return "generated-"..guid end}
local RS={}
local services={Players=Players,ReplicatedStorage=RS,HttpService=Http,RunService={IsStudio=function() return true end},DataStoreService={GetDataStore=function() return {} end}}
local game={JobId=""}
function game:GetService(name) return assert(services[name],name) end
local TEST_RULES={Graph=function() return {} end,Trace=function() return nil end}
'''

TESTS = r'''
local ctx={Config=Config,States={},Services={},Remotes={FX={FireAllClients=function() end}}}
function ctx:Toast() end
function ctx:Sync() end
function ctx:Near(player) return player.Near~=false end
function ctx:GrantTools() end
function ctx:ApplySpeed() end
function ctx:HasTransfer() return false end
local persistence=Persistence.new(ctx)
ctx.Services.Persistence=persistence
local building=Building.new(ctx)
local production=Production.new(ctx)
local fresh=persistence:Default()
check(fresh.DefensesBuilt==true and #fresh.Builds==0,"New profile includes ready walls and roof with no machines positioned")
for kind,count in pairs(Config.StarterInventory) do check(fresh.Inventory[kind]==count,"Free kit inventory: "..kind) end
local starter={Profile=fresh,Generation=0,Runtime={}}
building:Starter(starter);building:Starter(starter)
check(#fresh.Builds==0 and fresh.Inventory.Habitat==Config.StarterInventory.Habitat,"Repeated Starter never positions or consumes the kit")
local old={Version=3,Cash=125,Inventory={Habitat=2,Belt=9},Builds={
 {Id="h1",Kind="Habitat",X=0,Z=16,R=0,Level=2},
 {Id="h2",Kind="Habitat",X=32,Z=16,R=0},
 {Id="i1",Kind="Incubator",X=-32,Z=-40,R=1}},
 Creatures={{Id="old-creature",Species=2,HabitatId="h1",Stored=4}},
 Incubations={{Id="saved-egg",Species=1,HabitatId="h2",IncubatorId="i1",Remaining=7}},
 ResourceEscrow={{Id="saved-packet",Species=1,CreatureId="old-producer",Value=32,Remaining=2,Path={{X=0,Z=0},{X=0,Z=-4}}}}}
local migrated=persistence:Normalize(old)
check(migrated.DefensesBuilt==true,"An old save without the defense field preserves existing protection")
old.DefensesBuilt=false
local fromOptionalDefense=persistence:Normalize(old)
check(fromOptionalDefense.DefensesBuilt==true,"An optional-defense WIP save receives ready walls and roof")
check(#fromOptionalDefense.Builds==3 and fromOptionalDefense.Creatures[1].Id=="old-creature" and fromOptionalDefense.Incubations[1].Remaining==7,"Defense migration preserves machines, creatures and remaining incubation")
check(#migrated.Builds==3 and migrated.Builds[1].Level==2 and migrated.Inventory.Belt==9,"Migration preserves saved layout, upgrades and kit balances")
local lobby={Player={UserId=1,Parent=Players,Near=true},Profile=migrated,Runtime={},Generation=0,Ready=true,LastCombat=0,Energy=100}
local before=persistence:Snapshot(lobby)
now+=500
production:Step(lobby,500)
production:RenderCreatures(lobby)
local after=persistence:Snapshot(lobby)
check(production:Income(lobby)==0 and lobby.Profile.Cash==125,"An unclaimed lobby profile earns no money")
check(lobby.Pending==nil and lobby.Runtime.ResourcePackets==nil,"Lobby processing creates no active timers or packet queues")
check(after.Incubations[1].Remaining==before.Incubations[1].Remaining and after.Incubations[1].Remaining==7,"Lobby snapshots keep incubation time paused")
check(after.ResourceEscrow[1].Id=="saved-packet" and after.ResourceEscrow[1].Remaining==2,"Lobby snapshots preserve unpaid escrow without consuming it")
persistence:QueueRelease(lobby)
check(persistence.PendingReleases[1].State.Profile.Incubations[1].Remaining==7 and persistence.PendingReleases[1].State.Profile.ResourceEscrow[1].Value==32,"Disconnect retry snapshot preserves an unclaimed profile")
check(not building:FreeHabitat(lobby),"Lobby cannot reserve a habitat")
check(building:Render(lobby)==false and building:Command(lobby,"Place",{Kind="Belt",X=0,Z=0})==false,"Lobby cannot render or place constructions")

local function folder() return {ClearAllChildren=function(self) self.Cleared=true end} end
local function plot(id)
 local label={Name="ClaimLabel",Enabled=true}
 local prompt={Name="ClaimPlot",Enabled=true,MaxActivationDistance=12}
 local pad={Position=Vector3.new(id*100,0,0),FindFirstChild=function(_,name) return name=="ClaimPlot" and prompt or nil end}
 local p={Id=id,OwnerUserId=0,Children={ClaimPad=pad,ClaimLabel=label,Structures=folder(),Creatures=folder(),Incubations=folder()}}
 function p:FindFirstChild(name) return self.Children[name] end
 function p:GetAttribute(name) return self[name] end
 function p:SetAttribute(name,value) self[name]=value end
 function p:GetPivot() return {Position=Vector3.new(id*100,0,0),PointToWorldSpace=function(_,v) return v end} end
 label.Parent=p
 return p
end
local plots={[1]=plot(1),[2]=plot(2),[3]=plot(3)}
local World={Plots={FindFirstChild=function(_,name) return plots[tonumber(name:match("(%d+)$"))] end}}
local function ownerSign(p,player) p.SignOwner=player and player.UserId or 0 end
local function makeDeliveryPad(s) s.DeliveryCreated=true end
local function renderPending(s,id,pending) s.PendingDrawn=id end
ctx.Services.Building={Render=function(_,s)
 building:Starter(s)
 if s.YieldRender then coroutine.yield("render") end
 if s.FailRender then error("Injected renderer failure") end
end}
ctx.Services.Production={RenderCreatures=function() end}
ctx.Services.Combat={Reset=function(_,s) s.Runtime.BatteryHP=200;s.Runtime.DefenseAtReset=s.Profile.DefensesBuilt end,SetPlotVacant=function(_,p) p.DefenseVacant=true end}
-- No storage call is needed when testing rebirth's state transition.
persistence.Save=function() return true end
'''

CLAIM_TESTS = r'''
local function playerState(uid,profile)
 return {Player={UserId=uid,Parent=Players,Near=true},Profile=profile or persistence:Default(),Runtime={},Generation=0,Ready=true,LastCombat=0,Energy=100}
end
local claimant=playerState(2)
claimant.Profile.DefensesBuilt=false -- Simulate an already loaded optional-defense WIP profile.
claimant.Player.Near=false
check(not claimPlot(claimant,1) and not claimant.Plot,"A distant player cannot claim a plot")
claimant.Player.Near=true
check(not claimPlot(claimant,0/0) and not claimPlot(claimant,9),"Invalid claim identifiers are rejected")
claimant.YieldRender=true
local claim=coroutine.create(function() return claimPlot(claimant,1) end)
local resumed,status=coroutine.resume(claim)
check(resumed and status=="render" and plots[1].OwnerUserId==2 and claimant.OperationBusy,"Claim reserves player and plot before rendering can yield")
local competitor=playerState(3)
check(not claimPlot(competitor,1) and not competitor.Plot,"Concurrent contender cannot acquire an already reserved plot")
claimant.YieldRender=false
local resumedAgain,claimed=coroutine.resume(claim)
check(resumedAgain and claimed and claimant.Plot==plots[1] and claimant.PlotId==1,"The reserved claim finishes with one owner")
check(claimant.Profile.DefensesBuilt==true and claimant.Runtime.DefenseAtReset==true,"Claim activates ready protection before Combat.Reset even for a WIP profile")
check(not claimPlot(claimant,2) and plots[2].OwnerUserId==0,"One player cannot acquire a second plot")
check(#claimant.Profile.Builds==0 and claimant.Profile.Inventory.Belt==Config.StarterInventory.Belt,"Claiming a fresh profile leaves the full kit unplaced")
check(plots[1].Children.ClaimLabel.Enabled==false and plots[1].Children.ClaimLabel.Parent==plots[1].Children.ClaimPad,"Claim hides a legacy plot-parented free-base label")

local returning=playerState(4,persistence:Normalize(after))
returning.FailRender=true
local oldCash=returning.Profile.Cash
check(not claimPlot(returning,2),"An injected claim renderer failure is reported")
check(returning.Plot==nil and returning.PlotId==nil and returning.Pending==nil and not returning.OperationBusy,"Failed claim returns the player to the unclaimed lobby")
check(plots[2].OwnerUserId==0 and plots[2].Children.ClaimPad:FindFirstChild("ClaimPlot").Enabled and plots[2].Children.ClaimLabel.Enabled,"Failed claim reopens the plot and its free-base label")
check(returning.Profile.Cash==oldCash and returning.Profile.Incubations[1].Remaining==7 and returning.Profile.ResourceEscrow[1].Id=="saved-packet","Claim rollback preserves money, pending egg and unpaid escrow")
returning.FailRender=false
now+=250
check(claimPlot(returning,2),"A rolled-back claim can be retried successfully")
check(returning.Pending.h2.EndsAt-now==7 and #returning.Profile.Incubations==0,"Only a successful claim activates the saved incubation timer")
check(#returning.Profile.Builds==3 and returning.Profile.Builds[1].Level==2 and returning.Profile.Creatures[1].Id=="old-creature","Claim restores an existing layout and creature without replacing the base")
check(#returning.Profile.ResourceEscrow==1,"Claim itself does not consume saved resource packets")
local packetState=playerState(5,persistence:Normalize(after))
packetState.Profile.Creatures={};packetState.Plot=plots[3];packetState.PlotId=3;packetState.Pending={}
production:Step(packetState,.1)
check(#packetState.Runtime.ResourcePackets==1 and #packetState.Profile.ResourceEscrow==0 and packetState.Profile.Cash==125,"First active production step restores escrow once without early payment")
production:Step(packetState,2)
check(packetState.Profile.Cash==157 and #packetState.Runtime.ResourcePackets==0,"The saved packet pays exactly once after its active remaining time")
production:Step(packetState,2)
check(packetState.Profile.Cash==157,"Repeated processing cannot duplicate the restored payout")
local noPlot=playerState(6);noPlot.Profile.Cash=Config.RebirthCost
rebirth(noPlot)
check(noPlot.Profile.Rebirths==0 and noPlot.Profile.Cash==Config.RebirthCost,"An unclaimed profile cannot rebirth")
claimant.Profile.Cash=Config.RebirthCost;claimant.Profile.DefensesBuilt=false
claimant.Profile.Discovered={['1']=true}
rebirth(claimant)
check(claimant.Profile.Rebirths==1 and claimant.Profile.Cash==0 and claimant.Profile.DefensesBuilt==true and claimant.Runtime.DefenseAtReset==true,"Rebirth resets cash while keeping ready walls and roof")
check(claimant.Plot==plots[1] and #claimant.Profile.Builds==0 and claimant.Profile.Inventory.Habitat==Config.StarterInventory.Habitat,"Rebirth keeps the chosen plot and restores an unplaced kit")
check(claimant.Profile.Discovered['1']==true,"Rebirth keeps discoveries")
print("CLAIM LIFECYCLE TESTS",passed,"PASSED")
'''


def program() -> str:
    bootstrap = source("Server/Bootstrap.server.luau")
    rules_import = 'local Rules = require(ReplicatedStorage:WaitForChild("EggTycoonV3").Shared.BuildRules)'
    modules = []
    for name, path in (("Config", "Shared/Config.luau"), ("Persistence", "Server/Persistence.luau"),
                       ("Building", "Server/Building.luau"), ("Production", "Server/Production.luau")):
        body = source(path).replace(rules_import, "local Rules=TEST_RULES")
        modules.append(f"local {name}=(function()\n{body}\nend)()\n")
    claim_helpers = "local function claimLabel" + section(bootstrap, "local function claimLabel", "for id=1,8 do")
    claim = "local claimPlot\nclaimPlot=function(state,id)" + section(bootstrap, "claimPlot=function(state,id)", "local function spawnCharacter")
    rebirth = "local function rebirth(state)" + section(bootstrap, "local function rebirth(state)", "-- Prompt hold time")
    return PREFIX + "\n" + "\n".join(modules) + TESTS + claim_helpers + claim + rebirth + CLAIM_TESTS


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", default=os.environ.get("LUAU_BIN"))
    args = parser.parse_args()
    bundled = PROJECT.parents[1] / "luau-cli" / ("luau.exe" if os.name == "nt" else "luau")
    executable = args.luau or shutil.which("luau") or (str(bundled) if bundled.exists() else None)
    if not executable:
        parser.error("Provide --luau PATH or set LUAU_BIN to an official Luau CLI executable.")
    scratch = PROJECT.parent / "work"
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="egg-claim-offline-", dir=scratch) as temporary:
        path = Path(temporary) / "claim_lifecycle.luau"
        path.write_text(program(), encoding="utf-8")
        return subprocess.run([executable, str(path)], check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
