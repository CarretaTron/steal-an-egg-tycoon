"""Editable offline checks for the claim/setup guide and preview safety contract.

This harness stubs rendering and networking. It does not certify Studio visuals.
Run from any directory:
python PATH/StealAnEggTycoonV3/Tests/client_preview_guide_offline.py --luau PATH_TO_LUAU

Prints static preview-contract checks separately from the 13 functional offline
guide tests. Rendering, streaming and physical input still require Studio QA.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

PROJECT=Path(__file__).resolve().parents[1]

def source(relative: str) -> str:
    return (PROJECT/relative).read_text(encoding='utf-8')

def static_checks() -> None:
    client=source('Client/Client.client.luau')
    art=source('Shared/Art.luau')
    count=0
    def check(condition: bool, message: str) -> None:
        nonlocal count
        assert condition,message
        count+=1
    preview=client.split('function hud:CreateBuildPreview',1)[1].split('beginBuild=function',1)[0]
    for invariant in (
        "candidate:Clone()", "Art.UseReplicatedAssets()", "Art.Structure(kind,CFrame.identity,root)",
        "object.Anchored=true", "object.CanCollide=false", "object.CanTouch=false",
        "object.CanQuery=false", "object.CastShadow=false", "math.max(.45,object.Transparency)",
        "object.LocalTransparencyModifier=0", "object:IsA('LuaSourceContainer')",
        "object:IsA('ProximityPrompt')", "object:IsA('ClickDetector')",
        "object:IsA('LayerCollector')", "model:PivotTo(initial)", "root.Parent=workspace",
    ):
        check(invariant in preview,invariant)
    cancel=client.split('cancelBuild=function()',1)[1].split('function hud:CreateBuildPreview',1)[0]
    check('hud.PreviewRoot:Destroy()' in cancel,'Preview destroyed on cancellation')
    check("gui.Destroying:Connect(function() cancelBuild() end)" in cancel,'Preview destroyed with GUI')
    check("pcall(function() hud:CreateBuildPreview(kind,existing) end)" in client,'Preview construction error contained')
    check("if state.NeedsClaim or not state.PlotId then\n  cancelBuild()" in client,'Unclaimed snapshot cancels preview')
    check('hud.PreviewModel:PivotTo(itemCF)' in client,'Preview follows snapped transform')
    check('hud.PreviewHighlight.OutlineColor=ghostPart.Color' in client,'Validity outline follows validation')
    binder=art.split('function A.UseReplicatedAssets()',1)[1].split('local function meshModel',1)[0]
    for forbidden in ('CreateEditableMesh','CreateMeshPartAsync','CreateDataModelContentAsync',':Destroy()',':ClearAllChildren()'):
        check(forbidden not in binder,forbidden)
    check("mesh:IsA('MeshPart')" in binder,'Replicated template type checked')
    print(f'STATIC PREVIEW CONTRACT CHECKS {count} PASSED',flush=True)

prefix=r'''
local V={}
V.__add=function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},V) end
V.__sub=function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},V) end
V.__mul=function(a,b) return setmetatable({X=a.X*b,Y=a.Y*b,Z=a.Z*b},V) end
V.__index=function(a,k)
 if k=='Magnitude' then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
 if k=='Unit' then return a*(1/a.Magnitude) end
end
local Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},V) end}
local CF={}
CF.__mul=function(a,b) return setmetatable({Position=a.Position+b.Position},CF) end
local CFrame={new=function(x,y,z) return setmetatable({Position=Vector3.new(x,y,z)},CF) end}
local Vector2={new=function(x,y) return {X=x,Y=y} end}
local UDim2={fromOffset=function(x,y) return {X=x,Y=y} end}
local Enum={RaycastFilterType={Exclude=1}}
local RaycastParams={new=function() return {} end}
local rootPart={Position=Vector3.new(0,3,0)}
local character={FindFirstChild=function() return rootPart end}
local players={LocalPlayer={UserId=1,Character=character}}
local inset={GetGuiInset=function() return {X=0,Y=58} end}
local game={GetService=function(_,name) return name=='Players' and players or inset end}
local plots={}
local camera={ViewportSize={X=750,Y=381},WorldToViewportPoint=function() return Vector3.new(375,180,1),true end}
local workspace={CurrentCamera=camera}
workspace.FindFirstChild=function(_,name)
 if name~='EggTycoonV3' then return nil end
 return {FindFirstChild=function(_,folder) if folder=='Plots' then return {GetChildren=function() return plots end} end end}
end
local rules={Graph=function() return {} end,Trace=function(_,id) return id=='connected' and {} or nil end}
local script={Parent={BuildRules={}}}
local require=function() return rules end
'''
tests=r'''
local passed=0
local function check(value,message) assert(value,message) passed+=1 print('PASS',message) end
local cf=CFrame.new(100,0,0)
local config={PlotCFrame=function() return cf end,ItemCFrame=function(base,build) return base*CFrame.new(build.X or 0,0,build.Z or 0) end,Species={{Hatch=10}}}
local function newGuide()
 local marker={Visible=false,SetAttribute=function(self,key,value) self[key]=value end}
 return setmetatable({Config=config,Active=false,WasOpen=false,Marker=marker,Chevrons={},World={},Arrow={},Caption={},Gui={IgnoreGuiInset=false,FindFirstChild=function() return nil end}},Guide)
end
local function plot(owner,defended,x)
 return {GetAttribute=function(_,key) if key=='OwnerUserId' then return owner end if key=='DefensesBuilt' then return defended end end,
  FindFirstChild=function(_,name) if name=='ClaimPad' or name=='Battery' then return {Position=Vector3.new(x,0,0),IsA=function() return true end} end end}
end
plots={plot(0,false,180),plot(5,false,10),plot(0,false,120)}
local g=newGuide()
local lobby={NeedsClaim=true,Builds={},Creatures={}}
local target,caption=g:AutomaticGoal(lobby,rootPart.Position)
check(target and target.X==120 and caption=='Escolha esta tycoon','Lobby selects nearest free plot and ignores occupied plot')
g:Update(lobby,false)
check(g.Marker.Visible and not g.Active,'Claim guidance appears without opening the mission menu or enabling mission preference')
local fresh={NeedsClaim=false,PlotId=1,PlotCFrame=cf,Builds={},Creatures={}}
target,caption=g:AutomaticGoal(fresh,rootPart.Position)
check(target and caption=='Monte a incubadora 🔨','Empty claimed kit automatically guides first placement')
fresh.Builds={{Id='inc',Kind='Incubator',X=-32,Z=-40}}
target,caption=g:AutomaticGoal(fresh,rootPart.Position)
check(caption=='Monte o habitat 🔨','Automatic setup remains active after placing first machine')
g:TrackMission('engineer')
check(g:AutomaticGoal(fresh,rootPart.Position)==nil,'Explicitly selected mission takes priority over setup hint')
local explicit,explicitCaption=g:Resolve(fresh,rootPart.Position)
check(explicitCaption=='Sua tycoon','Resolve does not unconditionally override a selected mission with setup hint')
g.Selected=nil;g.Active=false
fresh.Builds={
 {Id='connected',Kind='Habitat',X=0,Z=16}, {Id='inc',Kind='Incubator',X=-32,Z=-40},
 {Id='p',Kind='Processor',X=0,Z=-16}, {Id='s',Kind='Seller',X=0,Z=-36},
}
check(g:AutomaticGoal(fresh,rootPart.Position)==nil and g.AutomaticSetup==false and g.Active==false,'Complete production line ends only automatic setup and keeps mission preference unchanged')
fresh.Rebirths=1;fresh.Builds={};fresh.Creatures={}
target,caption=g:AutomaticGoal(fresh,rootPart.Position)
check(target and caption=='Monte a incubadora 🔨' and g.Active==false,'Rebirth reactivates manual kit setup without enabling the mission preference')
local returning=newGuide()
local existing={NeedsClaim=false,PlotId=1,PlotCFrame=cf,Builds={{Id='old',Kind='Habitat',X=0,Z=16}},Creatures={}}
check(returning:AutomaticGoal(existing,rootPart.Position)==nil and returning.AutomaticSetup==false,'Existing partial layout keeps opt-in mission behavior')
returning:Update(existing,false)
check(not returning.Marker.Visible,'Returning player with guide off receives no unsolicited setup marker')
local carrier=newGuide()
carrier.AutomaticSetup=true
carrier.BuildGoal=function() return Vector3.new(150,0,0),'Incubadora' end
local carrying={NeedsClaim=false,PlotId=1,Builds={},Creatures={},Carrying=true,Carry='Ovo de Pintinho'}
target,caption=carrier:AutomaticGoal(carrying,rootPart.Position)
check(target and caption=='Incubadora','Carried egg delivery has priority over automatic construction hints')
local defender=newGuide()
defender.Selected='defender'
plots={plot(5,false,10),plot(1,true,20),plot(0,true,30),plot(6,true,100)}
local enemy,enemyCaption=defender:Resolve({PlotId=1,Builds={},Creatures={},Missions={}},rootPart.Position)
check(enemy and enemy.X==100 and enemyCaption=='Bateria rival','Defender mission ignores open, own and vacant batteries')
plots={plot(5,true,10)}
check(defender:ClaimGoal(rootPart.Position)==nil,'All plots occupied leaves no invalid claim target')
print('FUNCTIONAL GUIDE OFFLINE TESTS',passed,'PASSED')
'''

def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau',default=os.environ.get('LUAU_BIN'))
    args=parser.parse_args()
    bundled=PROJECT.parents[1]/'luau-cli'/('luau.exe' if os.name=='nt' else 'luau')
    executable=args.luau or shutil.which('luau') or (str(bundled) if bundled.exists() else None)
    if not executable:
        parser.error('Provide --luau PATH or set LUAU_BIN to an official Luau CLI executable.')
    static_checks()
    program=prefix+'\nlocal Guide=(function()\n'+source('Shared/HudGuide.luau')+'\nend)()\n'+tests
    scratch=PROJECT.parent/'work'
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='egg-client-guide-offline-',dir=scratch) as temporary:
        path=Path(temporary)/'client_preview_guide.luau'
        path.write_text(program,encoding='utf-8')
        return subprocess.run([executable,str(path)],check=False).returncode

if __name__=='__main__':
    raise SystemExit(main())
