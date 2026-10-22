-- Inert outside the server's exact EggTycoonV3_Mobile Studio test activation.
local Run=game:GetService("RunService")
if not Run:IsStudio() then return end
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local sent=false
local function active() return workspace:GetAttribute("V3MobileActive")==true end
local function isVisible(object,gui)
 local current=object
 while current and current~=gui do
  if current:IsA("GuiObject") and not current.Visible then return false end
  current=current.Parent
 end
 return gui.Enabled
end
local function run()
 if sent or not active() then return end;sent=true
 local package=RS:WaitForChild("EggTycoonV3",10);if not package then return end
 local C=require(package.Shared.Config)
 local plotId=workspace:GetAttribute("V3MobilePlotId") or 1
 local cf=C.PlotCFrame(plotId)
 local streamOK,streamErr=pcall(function() player:RequestStreamAroundAsync(cf.Position,12) end)
 local camera=workspace.CurrentCamera
 if not camera then return end
 local originalType,originalCF=camera.CameraType,camera.CFrame
 camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=CFrame.lookAt((cf*CFrame.new(95,115,-145)).Position,cf.Position+Vector3.new(0,4,0))
 task.wait(3)
 local elapsed,frames,worst=0,0,0
 local times={}
 local conn=Run.RenderStepped:Connect(function(dt)
  elapsed+=dt;frames+=1;worst=math.max(worst,dt);table.insert(times,dt)
 end)
 task.wait(10);conn:Disconnect()
 table.sort(times)
 local view=camera.ViewportSize
 local gui=player:FindFirstChildOfClass("PlayerGui") and player.PlayerGui:FindFirstChild("EggTycoonV3UI")
 local bounds,overflows={},{}
 local visibleWidgets=0
 if gui then
  for _,object in ipairs(gui:GetDescendants()) do
   if object:IsA("GuiObject") and isVisible(object,gui) then
    visibleWidgets+=1
    local p,size=object.AbsolutePosition,object.AbsoluteSize
    if object.Parent==gui then table.insert(bounds,{Name=object.Name,X=p.X,Y=p.Y,Width=size.X,Height=size.Y}) end
    if size.X>0 and size.Y>0 and (p.X<-.5 or p.Y<-.5 or p.X+size.X>view.X+.5 or p.Y+size.Y>view.Y+.5) then
     if #overflows<30 then table.insert(overflows,{Name=object.Name,Class=object.ClassName,X=p.X,Y=p.Y,Width=size.X,Height=size.Y}) end
    end
   end
  end
 end
 local world=workspace:FindFirstChild("EggTycoonV3")
 local parts,meshes,creatures,plots,builds=0,0,0,0,0
 if world then
  for _,object in ipairs(world:GetDescendants()) do
   if object:IsA("BasePart") then parts+=1;if object:IsA("MeshPart") then meshes+=1 end end
   if object:IsA("Model") and object:GetAttribute("CreatureId") then creatures+=1 end
   if object:IsA("Model") and object:GetAttribute("BuildId") then builds+=1 end
  end
  local plotFolder=world:FindFirstChild("Plots")
  if plotFolder then for _,plot in ipairs(plotFolder:GetChildren()) do if (plot:GetAttribute("OwnerUserId") or 0)~=0 then plots+=1 end end end
 end
 local payload={AverageFPS=math.floor(frames/math.max(elapsed,.001)*100)/100,WorstFrameMS=math.floor(worst*10000)/10,
  P95FrameMS=math.floor((times[math.max(1,math.ceil(#times*.95))] or 0)*10000)/10,Frames=frames,Seconds=elapsed,
  ViewportX=view.X,ViewportY=view.Y,Viewport=tostring(view),TouchEnabled=UIS.TouchEnabled,KeyboardEnabled=UIS.KeyboardEnabled,
  GUIExists=gui~=nil,VisibleWidgets=visibleWidgets,TopLevelBounds=bounds,OverflowCount=#overflows,Overflows=overflows,
  StreamedParts=parts,MeshParts=meshes,ReplicatedCreatures=creatures,ReplicatedBuilds=builds,OccupiedPlots=plots,
  StreamRequest=streamOK,StreamIssue=not streamOK and tostring(streamErr) or nil}
 local remotes=package:FindFirstChild("Remotes");local command=remotes and remotes:FindFirstChild("Command")
 if command and active() then command:FireServer("QADeviceProbe",payload) end
 camera.CameraType=originalType;camera.CFrame=originalCF
end
workspace:GetAttributeChangedSignal("V3MobileActive"):Connect(function() task.spawn(run) end)
task.spawn(run)
