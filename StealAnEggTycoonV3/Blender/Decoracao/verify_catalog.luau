-- Run in Edit after FBXCatalog.Adopt and Showroom.Build. Does not start Play.
assert(not game:GetService('RunService'):IsRunning())
local definitions=require(game.ServerStorage.DecoracaoToolkit.Definitions).Models
local library=game.ServerStorage.BibliotecaDecoracao
local display=workspace.CatalogoDecoracao.Modelos_Para_Copiar
local report={Models=0,Meshes=0,PermanentMeshIds=0,Anchored=0,ExpectedParts=0,Failures={},ExistingMapParts=0,ExistingScripts=0,Mode='Edit'}
local function check(condition,description)if not condition then table.insert(report.Failures,description)end end
for _,d in ipairs(definitions)do
 local m=assert(library:FindFirstChild(d.Id));local shown=assert(display:FindFirstChild(d.Id))
 report.Models+=1;check(m:GetPivot()==CFrame.identity,d.Id..'/Pivot')
 for _,pd in ipairs(d.Parts)do
  local p=assert(m:FindFirstChild(pd.Name,true));local sp=assert(shown:FindFirstChild(pd.Name,true))
  local lo=Vector3.new(unpack(pd.Bounds.Min));local hi=Vector3.new(unpack(pd.Bounds.Max))
  local expectedCF=CFrame.new((lo+hi)/2)*CFrame.Angles(0,math.pi,0)
  report.ExpectedParts+=1;report.Meshes+=1
  check((p.Size-(hi-lo)).Magnitude<.001,d.Id..'/Size')
  check((p.CFrame.Position-expectedCF.Position).Magnitude<.001 and p.CFrame.RightVector:Dot(expectedCF.RightVector)>.9999,d.Id..'/CFrame')
  check(math.abs(p.Color.R-pd.Color[1])<.001 and math.abs(p.Color.G-pd.Color[2])<.001 and math.abs(p.Color.B-pd.Color[3])<.001,d.Id..'/Color')
  check(sp.MeshId==p.MeshId and sp.Size==p.Size,d.Id..'/DisplayedCopy')
  check(not p.CanCollide and not p.CanTouch,d.Id..'/FoliagePhysics')
  check(p.Material==(pd.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic),d.Id..'/Material')
  if p.MeshId:match('^rbxassetid://%d+$')then report.PermanentMeshIds+=1 end
  if p.Anchored then report.Anchored+=1 end
 end
 for _,o in ipairs(m:GetDescendants())do check(not o:IsA('LuaSourceContainer'),d.Id..'/UnexpectedCode')end
end
local baseline=_G.DecorationTaskBaseline
if baseline then
 for p,old in pairs(baseline.Parts)do
  check(p.Parent and p.CFrame==old.CF and p.Size==old.Size and p.Color==old.Color and p.Transparency==old.Transparency,'ExistingMap/'..p.Name)
  report.ExistingMapParts+=1
 end
 for s,source in pairs(baseline.Scripts)do
  check(s.Parent and s.Source==source,'ExistingScript/'..s.Name);report.ExistingScripts+=1
 end
end
report.Passed=#report.Failures==0 and report.Models==20 and report.Meshes==97 and report.PermanentMeshIds==97
_G.DecorationValidation=report
return report
