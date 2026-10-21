local R=game:GetService('RunService') if not R:IsStudio() then return end
local P=game.Players.LocalPlayer local sent=false
local function run()
 if sent or not workspace:GetAttribute('V3StressActive') then return end sent=true
 local cf=require(game.ReplicatedStorage.EggTycoonV3.Shared.Config).PlotCFrame(1)
 pcall(function() P:RequestStreamAroundAsync(cf.Position,12) end)
 local camera=workspace.CurrentCamera
 camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=CFrame.lookAt((cf*CFrame.new(95,115,-145)).Position,cf.Position+Vector3.new(0,4,0))
 task.wait(3)
 local elapsed,frames,worst=0,0,0
 local conn=R.RenderStepped:Connect(function(dt) elapsed+=dt frames+=1 worst=math.max(worst,dt) end)
 task.wait(10) conn:Disconnect()
 local count=0 for _,v in ipairs(workspace:GetDescendants()) do if v:IsA('BasePart') then count+=1 end end
 game.ReplicatedStorage.EggTycoonV3.Remotes.Command:FireServer('QAStressProbe',{AverageFPS=math.floor(frames/math.max(elapsed,.001)*100)/100,WorstFrameMS=math.floor(worst*10000)/10,Frames=frames,Seconds=elapsed,Viewport=tostring(camera.ViewportSize),StreamedParts=count})
 camera.CameraType=Enum.CameraType.Custom
end
workspace:GetAttributeChangedSignal('V3StressActive'):Connect(function() task.spawn(run) end) task.spawn(run)
