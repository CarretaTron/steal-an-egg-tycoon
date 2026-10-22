"""Run the actual Combat module with deterministic Luau mocks; never opens Studio.

Usage: python Tests/combat_offline.py --luau /path/to/luau
The temporary harness embeds Server/Combat.luau unchanged inside a lexical mock
environment. Generator is an explicit recording stub: this checks only that Combat
passes visibility and authoritative HP/state to its presentation dependency.
It does not execute Generator, render meshes/SurfaceGui, or test Roblox physics
or replication. The historical pre-Blender shell harness was retired; actual
map rows check the current static shell contract independently.
"""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


PRELUDE = r'''
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
local generatorModule={}
local replicatedStorage={EggTycoonV3={Shared={Generator=generatorModule}}}
local game={GetService=function(_self,name)
    if name=="Players" then return Players end
    assert(name=="ReplicatedStorage","Unexpected service: "..tostring(name))
    return replicatedStorage
end}
local function require(module)
    assert(module==generatorModule,"Unexpected module dependency")
    return Generator
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
local config={DefensesPrice=25,BatteryHP={200,450,900,1800},BatteryPrices={10,20,30},
    BreachTime=30,CombatLock=10,IsSafe=function(_p) return false end,
    Weapons={Baton={Damage=20,Range=8,Cooldown=.7,Energy=0}}}
local ctx={Config=config,States={},Services={},Remotes={FX={FireAllClients=function() end}},Syncs=0}
function ctx:Toast(_player,_message) end
function ctx:Sync(_state) self.Syncs+=1 end
function ctx:HasTransfer(_state) return self.TransferActive==true end
local Combat=(function()
'''

TESTS = r'''
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
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", type=Path, help="Path to the standalone Luau interpreter")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    default_cli = project.parent.parent / "luau-cli" / ("luau.exe" if os.name == "nt" else "luau")
    cli = args.luau or os.environ.get("LUAU_BIN") or shutil.which("luau") or (default_cli if default_cli.is_file() else None)
    if cli is None:
        parser.error("Standalone Luau was not found; pass --luau /path/to/luau")
    # Check the preserved map's actual hierarchy, independently from the mocks.
    rows = json.loads((project / "Map" / "scene.json").read_text(encoding="utf-8-sig"))
    def name(row):
        return row.get("Properties", {}).get("Name", {}).get("Value")
    world = next(row for row in rows if name(row) == "EggTycoonV3" and not row.get("Parent"))
    plots_folder = next(row for row in rows if name(row) == "Plots" and row.get("Parent") == world["Id"])
    for plot_id in range(1, 9):
        plot = next(row for row in rows if name(row) == f"Plot_{plot_id:02d}" and row.get("Parent") == plots_folder["Id"])
        children = [row for row in rows if row.get("Parent") == plot["Id"]]
        assert sum(name(row) == "Perimeter" and row["Class"] == "Part" for row in children) >= 3
        for required, cls in (("Floor", "Part"), ("Roof", "MeshPart"),
                              ("RoofCollision", "Part"), ("Laser", "Part"), ("Battery", "Part")):
            assert any(name(row) == required and row["Class"] == cls for row in children), (plot_id, required)
        roof = next(row for row in children if name(row) == "Roof")
        collision = next(row for row in children if name(row) == "RoofCollision")
        assert roof["Properties"]["Transparency"]["Value"] == 0, (plot_id, "Opaque roof")
        assert collision["Properties"]["CanCollide"]["Value"] is True, (plot_id, "Solid roof collider")
    print("PASS authored map defense contract: 8 preserved plots", flush=True)
    source = (project / "Server" / "Combat.luau").read_text(encoding="utf-8-sig")
    with tempfile.TemporaryDirectory(prefix="egg-tycoon-combat-") as temporary:
        script = Path(temporary) / "combat.luau"
        script.write_text(PRELUDE + source + "\n" + TESTS, encoding="utf-8")
        result = subprocess.run([str(cli), str(script)], check=False)
        if result.returncode:
            raise SystemExit(result.returncode)
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    main()
