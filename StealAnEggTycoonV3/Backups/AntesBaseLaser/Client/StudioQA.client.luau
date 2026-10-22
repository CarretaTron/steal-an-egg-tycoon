-- Client replication probe; inert outside an explicitly activated Studio QA run.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local sent=false
local function countParts(model)
 local parts,meshes=0,0
 if model then for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") and part.Size.Magnitude>0 then parts+=1;if part:IsA("MeshPart") then meshes+=1 end end
 end end
 return parts,meshes
end
local function probe()
 if sent or workspace:GetAttribute("V3QAActive")~=true then return end
 sent=true
 local streamOK,streamError=pcall(function() player:RequestStreamAroundAsync(Vector3.new(-42,6,738),12) end)
 local deadline=os.clock()+12
 local eggParts,guardParts,meshes=0,0,0
 repeat
  local world=workspace:FindFirstChild("EggTycoonV3")
  local nests=world and world:FindFirstChild("Nests")
  local guards=world and world:FindFirstChild("Guardians")
  local nest=nests and nests:FindFirstChild("Nest_B1_1")
  local egg=nest and nest:FindFirstChild("Egg")
  local guard=guards and guards:FindFirstChild("Guardian_B1_1")
  local eggMeshes,guardMeshes
  eggParts,eggMeshes=countParts(egg);guardParts,guardMeshes=countParts(guard);meshes=eggMeshes+guardMeshes
  if eggParts>0 and guardParts>0 and meshes>0 then break end
  task.wait(.1)
 until os.clock()>=deadline or workspace:GetAttribute("V3QAActive")~=true
 local package=ReplicatedStorage:WaitForChild("EggTycoonV3",10)
 local remotes=package and package:WaitForChild("Remotes",10)
 local command=remotes and remotes:FindFirstChild("Command")
 if command and workspace:GetAttribute("V3QAActive")==true then
  command:FireServer("QAClientProbe",{EggParts=eggParts,GuardParts=guardParts,MeshParts=meshes,StreamRequest=streamOK,Issue=not streamOK and tostring(streamError) or nil})
 end
end
workspace:GetAttributeChangedSignal("V3QAActive"):Connect(function() task.spawn(probe) end)
task.spawn(probe)
