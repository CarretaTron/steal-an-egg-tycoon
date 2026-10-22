-- Original garden pavilion: timber pens inspired by the local reference maps.
-- Geometry stays on the existing security boundary; no player contents are moved.
local Shell={Revision=2}
local originals={Perimeter=true,Frame=true,Roof=true,RoofFrame=true,DoorHeader=true,Laser=true,LaserBeam=true}
local P={Stone=Color3.fromRGB(231,207,153),Cream=Color3.fromRGB(255,242,206),
 Wood=Color3.fromRGB(177,105,48),Dark=Color3.fromRGB(91,54,34),
 Trim=Color3.fromRGB(53,212,186),Glass=Color3.fromRGB(168,237,227),
 Gold=Color3.fromRGB(255,194,62),Egg=Color3.fromRGB(255,229,127),Laser=Color3.fromRGB(255,49,73)}

local function defaults(p,alpha,collide,query)
 p:SetAttribute('BaseShellPart',true)
 p:SetAttribute('BaseShellRevision',Shell.Revision)
 p:SetAttribute('BaseShellTransparency',alpha)
 p:SetAttribute('BaseShellCanCollide',collide)
 p:SetAttribute('BaseShellCanTouch',collide)
 p:SetAttribute('BaseShellCanQuery',query)
end

local function part(plot,cf,name,size,offset,color,material,alpha,collide,studs,query)
 local p=Instance.new('Part')
 p.Name=name;p.Size=size;p.CFrame=cf*CFrame.new(unpack(offset))
 p.Anchored=true;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.Transparency=alpha or 0;p.CanCollide=collide~=false;p.CanTouch=p.CanCollide
 p.CanQuery=query~=false;p.CastShadow=p.Transparency<.8
 p.TopSurface=studs and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
 p.BottomSurface=Enum.SurfaceType.Smooth
 defaults(p,p.Transparency,p.CanCollide,p.CanQuery)
 p.Parent=plot
 return p
end

local function ownerSign(plot,cf)
 local board=plot:FindFirstChild('OwnerSign')
 if not board then board=part(plot,cf,'OwnerSign',Vector3.new(46,7.5,.8),{0,24,-83},P.Dark,nil,0,true,false) end
 assert(board:IsA('BasePart'),'OwnerSign must remain a BasePart')
 -- These exact instances are updated by the claim/owner interface.
 board.Size=Vector3.new(46,7.5,.8);board.CFrame=cf*CFrame.new(0,24,-83)
 board.Color=P.Dark;board.Material=Enum.Material.SmoothPlastic
 board.TopSurface=Enum.SurfaceType.Studs
 for _,face in ipairs({'FrontSurface','BackSurface','LeftSurface','RightSurface','BottomSurface'}) do board[face]=Enum.SurfaceType.Smooth end
 board.Transparency=0;board.CanCollide=true;board.CanTouch=true;board.CanQuery=true;board.CastShadow=true
 defaults(board,0,true,true)
 local gui=board:FindFirstChildWhichIsA('SurfaceGui')
 if not gui then gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.PixelsPerStud=40;gui.Parent=board end
 local title=gui:FindFirstChild('Title')
 if not title then title=Instance.new('TextLabel');title.Name='Title';title.Text='TYCOON '..tostring(plot:GetAttribute('PlotId') or '');title.Parent=gui end
 local subtitle=gui:FindFirstChild('Subtitle')
 if not subtitle then subtitle=Instance.new('TextLabel');subtitle.Name='Subtitle';subtitle.Text='BASE DISPONÍVEL';subtitle.Parent=gui end
 if title:IsA('TextLabel') then
  title.Size=UDim2.fromScale(.92,.56);title.Position=UDim2.fromScale(.04,.07)
  title.BackgroundTransparency=1;title.TextColor3=P.Cream;title.Font=Enum.Font.GothamBlack;title.TextScaled=true
 end
 if subtitle:IsA('TextLabel') then
  subtitle.Size=UDim2.fromScale(.92,.25);subtitle.Position=UDim2.fromScale(.04,.69)
  subtitle.BackgroundTransparency=1;subtitle.TextColor3=P.Trim;subtitle.Font=Enum.Font.GothamBold;subtitle.TextScaled=true
 end
end

local function prepareBattery(plot)
 local battery=plot:FindFirstChild('Battery')
 if not battery or not battery:IsA('BasePart') then return end
 if battery:GetAttribute('BaseShellTransparency')==nil then battery:SetAttribute('BaseShellTransparency',battery.Transparency) end
 for _,key in ipairs({'CanCollide','CanTouch','CanQuery'}) do
  if battery:GetAttribute('BaseShell'..key)==nil then battery:SetAttribute('BaseShell'..key,battery[key]) end
 end
 local vacant=(plot:GetAttribute('OwnerUserId') or 0)==0
 if vacant then battery.Transparency=1;battery.CanCollide=false;battery.CanTouch=false;battery.CanQuery=false end
 for _,gui in ipairs(battery:GetDescendants()) do
  if gui:IsA('BillboardGui') or gui:IsA('SurfaceGui') then
   if gui:GetAttribute('BaseShellEnabled')==nil then gui:SetAttribute('BaseShellEnabled',gui.Enabled) end
   if vacant then gui.Enabled=false end
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
 local function block(name,size,offset,color,material,alpha,collide,studs,query)
  return part(plot,cf,name,Vector3.new(unpack(size)),offset,color,material,alpha,collide,studs,query)
 end
 -- Five continuous sealed glass panels. Rails are only the visible garden fence.
 local panels={
  {0,80,160,true},{-80,0,160,false},{80,0,160,false},
  {-44,-80,72,true},{44,-80,72,true},
 }
 for _,v in ipairs(panels) do
  local x,z,length,horizontal=unpack(v)
  local function span(width,height) return horizontal and {length,height,width} or {width,height,length} end
  block('Perimeter',span(1.8,28),{x,14,z},P.Glass,Enum.Material.Glass,.9,true,false)
  block('GardenPlinth',span(3.6,2.2),{x,1.1,z},P.Stone,nil,0,true,true)
  for _,y in ipairs({3.8,8.2}) do block('GardenRail',span(1.8,1.3),{x,y,z},P.Wood,nil,0,true,true) end
  block('RoofFrame',span(3.8,2.2),{x,26.9,z},P.Dark,nil,0,true,true)
  block('GardenRoofTrim',span(4,.55),{x,28.3,z},P.Trim,Enum.Material.SmoothPlastic,0,false,false,false)
 end
 -- Repeated square columns give the pavilion a simple, readable silhouette.
 local posts={}
 for _,x in ipairs({-80,80}) do for _,z in ipairs({-78,-39,0,39,78}) do table.insert(posts,{x,z,false}) end end
 for _,x in ipairs({-39,0,39}) do table.insert(posts,{x,80,false}) end
 for _,x in ipairs({-44,44}) do table.insert(posts,{x,-80,false}) end
 for _,x in ipairs({-10.5,10.5}) do table.insert(posts,{x,-80,true}) end
 for _,v in ipairs(posts) do
  local x,z,door=unpack(v);local w=door and 5 or 3.8
  block('GardenColumn',{w,28,w},{x,14,z},P.Cream,nil,0,true,true)
  local foot=door and w or w+1
  block('GardenColumnFoot',{foot,2.4,foot},{x,1.2,z},P.Stone,nil,0,true,true)
  block('GardenColumnCap',{w+1.2,1.4,w+1.2},{x,27.3,z},P.Stone,nil,0,true,true)
 end
 -- Cross braces quote the wooden pen references; no braces cross the doorway.
 local function brace(a,b)
  local delta=b-a
  local p=block('GardenBrace',{delta.Magnitude,.8,.9},{0,0,0},P.Wood,nil,0,false,false,false)
  local direction=delta.Unit;local right=direction;local up=Vector3.yAxis
  if math.abs(right:Dot(up))>.99 then up=Vector3.zAxis end
  local back=right:Cross(up).Unit;up=back:Cross(right).Unit
  p.CFrame=cf*CFrame.fromMatrix((a+b)/2,right,up,back)
 end
 local marks={-78,-39,0,39,78}
 for _,side in ipairs({-1,1}) do
  for i=1,#marks-1 do
   local a,b=marks[i]+2,marks[i+1]-2
   brace(Vector3.new(side*80,3.8,a),Vector3.new(side*80,8.2,b))
   brace(Vector3.new(side*80,8.2,a),Vector3.new(side*80,3.8,b))
  end
 end
 for i=1,#marks-1 do
  local a,b=marks[i]+2,marks[i+1]-2
  brace(Vector3.new(a,3.8,80),Vector3.new(b,8.2,80))
  brace(Vector3.new(a,8.2,80),Vector3.new(b,3.8,80))
 end
 for _,side in ipairs({-1,1}) do
  local a,b=side*15,side*76
  brace(Vector3.new(a,3.8,-80),Vector3.new(b,8.2,-80))
  brace(Vector3.new(a,8.2,-80),Vector3.new(b,3.8,-80))
 end
 -- The thin transparent roof still blocks jumping in. Only the rim is opaque.
 block('Roof',{162,1,162},{0,28,0},P.Glass,Enum.Material.Glass,.94,true,false)
 block('PavilionRoofBeam',{1.6,1,158},{0,28,0},P.Cream,nil,0,true,true)
 block('PavilionRoofBeam',{158,1,1.6},{0,28,0},P.Cream,nil,0,true,true)
 block('DoorHeader',{16,10,3.8},{0,23,-80},P.Dark,nil,0,true,true)
 -- Golden picture frame around the preserved owner board.
 for _,y in ipairs({19.85,28.15}) do block('PortalSignTrim',{48,.65,1.1},{0,y,-83.15},P.Gold,nil,0,false,false,false) end
 for _,x in ipairs({-23.65,23.65}) do block('PortalSignTrim',{.65,8.3,1.1},{x,24,-83.15},P.Gold,nil,0,false,false,false) end
 for _,side in ipairs({-1,1}) do
  block('PortalEmitter',{.65,17,.55},{side*8.25,9,-82.1},P.Trim,Enum.Material.Neon,0,false,false,false)
  block('PortalFoot',{5,.6,5},{side*10.5,.3,-80},P.Gold,nil,0,true,true)
 end
 block('EggCrestBase',{10,1.5,3.5},{0,29.5,-81.7},P.Dark,nil,0,false,false,false)
 local egg=block('EggCrest',{5.7,7.4,3.4},{0,33.2,-81.7},P.Egg,nil,0,false,false,false);egg.Shape=Enum.PartType.Ball
 local spot=block('EggCrestSpot',{1.4,1.7,.25},{1,33.4,-83.33},P.Gold,nil,0,false,false,false);spot.Shape=Enum.PartType.Ball
 -- Combat controls these original hook names when the battery or owner changes.
 local owned=(plot:GetAttribute('OwnerUserId') or 0)~=0
 local laser=block('Laser',{16,18,.5},{0,9,-80},P.Laser,Enum.Material.Neon,.9,false,false)
 laser:SetAttribute('Open',not owned)
 if not owned then laser.Transparency=1;laser.CanQuery=false end
 for x=-6,6,2 do
  local beam=block('LaserBeam',{.24,18,.24},{x,9,-80},P.Laser,Enum.Material.Neon,0,false,false)
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
