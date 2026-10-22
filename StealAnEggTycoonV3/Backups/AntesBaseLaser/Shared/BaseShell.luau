-- Fixed building envelope. Floor, plot pivot, machines and battery identity stay authored.
local Shell={Revision=1}
local originals={Perimeter=true,Frame=true,Roof=true,RoofFrame=true,DoorHeader=true,Laser=true,LaserBeam=true}
local palette={Wall=Color3.fromRGB(65,67,75),Pillar=Color3.fromRGB(49,51,59),
 Trim=Color3.fromRGB(232,230,226),Roof=Color3.fromRGB(153,155,164),Glass=Color3.fromRGB(172,197,206),
 Sign=Color3.fromRGB(142,82,55),Letter=Color3.fromRGB(255,244,224),Laser=Color3.fromRGB(255,48,64)}

local function defaults(part,alpha,collide)
 part:SetAttribute('BaseShellPart',true)
 part:SetAttribute('BaseShellRevision',Shell.Revision)
 part:SetAttribute('BaseShellTransparency',alpha)
 part:SetAttribute('BaseShellCanCollide',collide)
 part:SetAttribute('BaseShellCanTouch',collide)
 part:SetAttribute('BaseShellCanQuery',true)
end

local function part(plot,cf,name,size,offset,color,material,alpha,collide,studs)
 local p=Instance.new('Part')
 p.Name=name;p.Size=size;p.CFrame=cf*CFrame.new(offset[1],offset[2],offset[3])
 p.Anchored=true;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.Transparency=alpha or 0;p.CanCollide=collide~=false;p.CanTouch=p.CanCollide;p.CanQuery=true
 p.TopSurface=studs and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
 for _,face in ipairs({'FrontSurface','BackSurface','LeftSurface','RightSurface'}) do p[face]=studs and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth end
 p.BottomSurface=Enum.SurfaceType.Smooth
 defaults(p,p.Transparency,p.CanCollide)
 p.Parent=plot
 return p
end

local function ownerSign(plot,cf)
 local board=plot:FindFirstChild('OwnerSign')
 if not board then
  board=part(plot,cf,'OwnerSign',Vector3.new(46,7.5,.8),{0,23,-82},palette.Sign,nil,0,true,true)
 end
 if not board:IsA('BasePart') then return end
 -- Preserve the sign and Title/Subtitle instances used by claim and owner UI.
 board.Size=Vector3.new(46,7.5,.8);board.CFrame=cf*CFrame.new(0,23,-82)
 board.Color=palette.Sign;board.Material=Enum.Material.SmoothPlastic;board.TopSurface=Enum.SurfaceType.Studs
 for _,face in ipairs({'FrontSurface','BackSurface','LeftSurface','RightSurface'}) do board[face]=Enum.SurfaceType.Studs end
 board.Transparency=0;board.CanCollide=true;board.CanTouch=true;board.CanQuery=true
 defaults(board,0,true)
 local gui=board:FindFirstChildWhichIsA('SurfaceGui')
 if not gui then gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.PixelsPerStud=40;gui.Parent=board end
 local title=gui:FindFirstChild('Title')
 if not title then title=Instance.new('TextLabel');title.Name='Title';title.Text='TYCOON '..tostring(plot:GetAttribute('PlotId') or '');title.Parent=gui end
 local subtitle=gui:FindFirstChild('Subtitle')
 if not subtitle then subtitle=Instance.new('TextLabel');subtitle.Name='Subtitle';subtitle.Text='BASE DISPONÍVEL';subtitle.Parent=gui end
 if title:IsA('TextLabel') then
  title.Size=UDim2.fromScale(.94,.58);title.Position=UDim2.fromScale(.03,.05)
  title.BackgroundTransparency=1;title.TextColor3=palette.Letter;title.Font=Enum.Font.GothamBlack;title.TextScaled=true
 end
 if subtitle:IsA('TextLabel') then
  subtitle.Size=UDim2.fromScale(.94,.27);subtitle.Position=UDim2.fromScale(.03,.68)
  subtitle.BackgroundTransparency=1;subtitle.TextColor3=palette.Letter;subtitle.Font=Enum.Font.GothamBold;subtitle.TextScaled=true
 end
end

local function prepareBattery(plot)
 local battery=plot:FindFirstChild('Battery')
 if not battery or not battery:IsA('BasePart') then return end
 -- Numeric/boolean defaults survive map export, including the vacant presentation.
 if battery:GetAttribute('BaseShellTransparency')==nil then battery:SetAttribute('BaseShellTransparency',battery.Transparency) end
 for _,key in ipairs({'CanCollide','CanTouch','CanQuery'}) do
  if battery:GetAttribute('BaseShell'..key)==nil then battery:SetAttribute('BaseShell'..key,battery[key]) end
 end
 local vacant=(plot:GetAttribute('OwnerUserId') or 0)==0
 if vacant then battery.Transparency=1;battery.CanCollide=false;battery.CanTouch=false;battery.CanQuery=false end
 for _,label in ipairs(battery:GetDescendants()) do
  if label:IsA('BillboardGui') or label:IsA('SurfaceGui') then
   if label:GetAttribute('BaseShellEnabled')==nil then label:SetAttribute('BaseShellEnabled',label.Enabled) end
   if vacant then label.Enabled=false end
  end
 end
end

function Shell.Apply(plot,force)
 assert(plot and plot:IsA('Model'),'BaseShell.Apply expects a plot Model')
 local existing=0
 for _,p in ipairs(plot:GetChildren()) do if p:IsA('BasePart') and p:GetAttribute('BaseShellPart') then existing+=1 end end
 if not force and plot:GetAttribute('BaseShellRevision')==Shell.Revision and existing==(plot:GetAttribute('BaseShellPartCount') or -1)
  and plot:FindFirstChild('Roof') and plot:FindFirstChild('Laser') and plot:FindFirstChild('OwnerSign') then return plot end
 local cf=plot:GetPivot()
 for _,p in ipairs(plot:GetChildren()) do
  if p:IsA('BasePart') and p.Name~='OwnerSign' and (originals[p.Name] or p:GetAttribute('BaseShellPart')) then p:Destroy() end
 end
 local function block(name,size,offset,color,glass)
  return part(plot,cf,name,size,offset,color,glass and Enum.Material.Glass or nil,glass and .42 or 0,true,not glass)
 end
 -- Side windows are sealed by collidable glass from Y6 to Y23.
 for _,side in ipairs({-1,1}) do
  block('Perimeter',Vector3.new(2,6,160),{side*80,3,0},palette.Wall)
  block('Perimeter',Vector3.new(2,5,160),{side*80,25.5,0},palette.Wall)
  block('Perimeter',Vector3.new(2,17,152),{side*80,14.5,0},palette.Glass,true)
  for _,y in ipairs({6,23}) do block('Frame',Vector3.new(2.8,2,156),{side*80,y,0},palette.Trim) end
  for _,z in ipairs({-76,-38,0,38,76}) do block('Frame',Vector3.new(2.8,19,2.4),{side*80,14.5,z},palette.Trim) end
 end
 -- Rear wall uses the same broad, white framed window language.
 block('Perimeter',Vector3.new(160,6,2),{0,3,80},palette.Wall)
 block('Perimeter',Vector3.new(160,5,2),{0,25.5,80},palette.Wall)
 block('Perimeter',Vector3.new(152,17,2),{0,14.5,80},palette.Glass,true)
 for _,y in ipairs({6,23}) do block('Frame',Vector3.new(156,2,2.8),{0,y,80},palette.Trim) end
 for _,x in ipairs({-76,-38,0,38,76}) do block('Frame',Vector3.new(2.4,19,2.8),{x,14.5,80},palette.Trim) end
 -- The central front opening stays exactly sixteen studs wide at local Z=-80.
 for _,side in ipairs({-1,1}) do
  block('Perimeter',Vector3.new(72,6,2),{side*44,3,-80},palette.Wall)
  block('Perimeter',Vector3.new(72,5,2),{side*44,25.5,-80},palette.Wall)
  block('Perimeter',Vector3.new(64,17,2),{side*44,14.5,-80},palette.Glass,true)
  for _,y in ipairs({6,23}) do block('Frame',Vector3.new(68,2,2.8),{side*44,y,-80},palette.Trim) end
  for _,x in ipairs({12,44,76}) do block('Frame',Vector3.new(2.4,19,2.8),{side*x,14.5,-80},palette.Trim) end
  block('Frame',Vector3.new(3,28,3),{side*9.5,14,-80},palette.Trim)
 end
 for _,x in ipairs({-79,79}) do for _,z in ipairs({-79,79}) do
  block('Frame',Vector3.new(4,28,4),{x,14,z},palette.Pillar)
 end end
 block('DoorHeader',Vector3.new(16,10,2),{0,23,-80},palette.Wall)
 block('Roof',Vector3.new(162,1,162),{0,28,0},palette.Roof)
 for _,side in ipairs({-1,1}) do
  block('RoofFrame',Vector3.new(162,1.5,2),{0,27.6,side*80},palette.Pillar)
  block('RoofFrame',Vector3.new(2,1.5,158),{side*80,27.6,0},palette.Pillar)
 end
 local owned=(plot:GetAttribute('OwnerUserId') or 0)~=0
 local laser=part(plot,cf,'Laser',Vector3.new(16,18,.5),{0,9,-80},palette.Laser,Enum.Material.Neon,.76,false,false)
 laser:SetAttribute('Open',not owned)
 if not owned then laser.Transparency=1;laser.CanQuery=false end
 for x=-6,6,3 do
  local beam=part(plot,cf,'LaserBeam',Vector3.new(.3,18,.3),{x,9,-80},palette.Laser,Enum.Material.Neon,0,false,false)
  if not owned then beam.Transparency=1;beam.CanQuery=false end
 end
 ownerSign(plot,cf)
 prepareBattery(plot)
 local count=0
 for _,p in ipairs(plot:GetChildren()) do if p:IsA('BasePart') and p:GetAttribute('BaseShellPart') then count+=1 end end
 plot:SetAttribute('BaseShellRevision',Shell.Revision)
 plot:SetAttribute('BaseShellGeneration',(plot:GetAttribute('BaseShellGeneration') or 0)+1)
 plot:SetAttribute('BaseShellPartCount',count)
 plot:SetAttribute('DefensesBuilt',true)
 return plot
end

return Shell
