-- Portuguese desktop/touch interface. All economic, placement and combat authority remains on server.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local GuiService=game:GetService("GuiService")
local player=Players.LocalPlayer
local package=ReplicatedStorage:WaitForChild("EggTycoonV3")
local C=require(package.Shared:WaitForChild("Config"))
local Rules=require(package.Shared:WaitForChild("BuildRules"))
local Art=require(package.Shared:WaitForChild("Art"))
local remotes=package:WaitForChild("Remotes")
local command=remotes:WaitForChild("Command")
local stateRemote=remotes:WaitForChild("State")
local toastRemote=remotes:WaitForChild("Toast")
local fxRemote=remotes:WaitForChild("FX")
local mouse=player:GetMouse()

local colors={Background=Color3.fromRGB(20,20,25),Panel=Color3.fromRGB(42,42,51),Card=Color3.fromRGB(56,56,66),
 Text=Color3.fromRGB(255,255,255),Muted=Color3.fromRGB(218,223,230),Green=Color3.fromRGB(111,255,0),
 Blue=Color3.fromRGB(0,207,255),Gold=Color3.fromRGB(255,215,0),Red=Color3.fromRGB(255,44,47),Purple=Color3.fromRGB(196,77,255)}
local state={Cash=0,Income=0,Builds={},Creatures={},Inventory={},Pending={},Energy=100,Rebirths=0}
local hud={Inside=false,Timer=0,Guide=nil}
function hud:Studs(object,columns,rows)
 local canvas=Instance.new('Frame');canvas.Name='StudsPattern';canvas.BackgroundTransparency=1;canvas.Size=UDim2.fromScale(1,1);canvas.ClipsDescendants=true;canvas.Active=false;canvas.Parent=object
 for row=0,rows-1 do for column=0,columns-1 do
  local dot=Instance.new('Frame');dot.Name='Stud';dot.Size=UDim2.new(0,7,0,6);dot.Position=UDim2.new(column/columns,6,row/rows,4)
  dot.BorderSizePixel=0;dot.BackgroundColor3=Color3.new(1,1,1);dot.BackgroundTransparency=.9;dot.Active=false;dot.Parent=canvas
  local edge=Instance.new('UIStroke');edge.Color=Color3.new();edge.Transparency=.88;edge.Thickness=1;edge.Parent=dot
 end end
end
function hud:InsidePlot()
 local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart')
 local cf=state.PlotCFrame or (state.PlotId and C.PlotCFrame(state.PlotId))
 if not root or not cf or not state.PlotId or state.NeedsClaim then return false end
 local at=cf:PointToObjectSpace(root.Position)
 local half=state.PlotHalf or C.PlotHalf
 return math.abs(at.X)<half-1 and at.Z>-half+1 and at.Z<half-1 and at.Y>=-4 and at.Y<28*half/(C.LegacyPlotHalf or 80)
end
local gui=Instance.new("ScreenGui")
gui.Name="EggTycoonV3UI"
gui.ResetOnSpawn=false
gui.DisplayOrder=20
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=player:WaitForChild("PlayerGui")
local old=gui.Parent:FindFirstChild("EggTycoonV3UI")
if old and old~=gui then old:Destroy() end

local function create(class,props,parent)
 local object=Instance.new(class)
 for key,value in pairs(props or {}) do object[key]=value end
 object.Parent=parent
 return object
end
local function round(object,radius)
 create("UICorner",{CornerRadius=UDim.new(0,radius or 4)},object)
end
local function stroke(object,color,thickness,transparency)
 return create("UIStroke",{Color=color or Color3.new(),Thickness=thickness or 3,Transparency=transparency or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},object)
end
local function frame(parent,props)
 props=props or {}
 props.BorderSizePixel=0
 props.BackgroundColor3=props.BackgroundColor3 or colors.Panel
 local result=create("Frame",props,parent)
 round(result,props.Name=="Shade" and 0 or 4)
 return result
end
local function label(parent,text,props)
 props=props or {}
 props.Text=text
 props.BackgroundTransparency=1
 props.BorderSizePixel=0
 props.Font=props.Font or Enum.Font.FredokaOne
 props.TextStrokeColor3=Color3.new()
 props.TextStrokeTransparency=props.TextStrokeTransparency or .12
 props.TextColor3=props.TextColor3 or colors.Text
 props.TextSize=props.TextSize or 14
 props.TextXAlignment=props.TextXAlignment or Enum.TextXAlignment.Left
 props.TextYAlignment=props.TextYAlignment or Enum.TextYAlignment.Center
 local result=create("TextLabel",props,parent)
 if props.TextSize>=20 then create('UIStroke',{Color=Color3.new(),Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual},result) end
 return result
end
local function button(parent,text,color,callback,props)
 props=props or {}
 if not props.Name then
  local base="Button_"..text:gsub("[^%w_]","_"):gsub("_+","_"):sub(1,45)
  local name,serial=base,1
  while parent:FindFirstChild(name) do serial+=1 name=base.."_"..serial end
  props.Name=name
 end
 if UserInputService.TouchEnabled and props.Size then
  local size=props.Size
  props.Size=UDim2.new(size.X.Scale,size.X.Scale==0 and math.max(44,size.X.Offset) or size.X.Offset,
   size.Y.Scale,size.Y.Scale==0 and math.max(44,size.Y.Offset) or size.Y.Offset)
 end
 props.Text=text
 props.AutoButtonColor=true
 props.BackgroundColor3=color or colors.Card
 props.BorderSizePixel=0
 props.Font=Enum.Font.FredokaOne
 props.TextStrokeColor3=Color3.new()
 props.TextStrokeTransparency=0
 props.TextColor3=props.TextColor3 or colors.Text
 props.TextSize=props.TextSize or 13
 local result=create("TextButton",props,parent)
 round(result,4)
 stroke(result,Color3.new(),3,0)
 create('UIGradient',{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(192,192,192)),Rotation=90},result)
 hud:Studs(result,6,2)
 result.Activated:Connect(function() if callback then callback() end end)
 return result
end
local function send(action,payload)
 command:FireServer(action,payload or {})
end
local function money(n)
 n=tonumber(n) or 0
 if n>=1e12 then return string.format('$%.1fT',n/1e12) end
 if n>=1e9 then return string.format('$%.1fB',n/1e9) end
 if n>=1e6 then return string.format('$%.1fM',n/1e6) end
 if n>=1e3 then return string.format('$%.1fK',n/1e3) end
 return '$'..tostring(math.floor(n))
end
local function sizeButton(btn,enabled)
 btn.AutoButtonColor=enabled
 btn.BackgroundTransparency=enabled and 0 or .55
 btn.TextTransparency=enabled and 0 or .3
end

local cashBox=frame(gui,{Name='Economia',AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,18,1,-22),Size=UDim2.fromOffset(460,83),BackgroundTransparency=1})
hud.EconomyRow=frame(cashBox,{Name='EconomyRow',Size=UDim2.new(1,0,0,58),BackgroundTransparency=1})
create('UIListLayout',{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,10)},hud.EconomyRow)
local cashText=label(hud.EconomyRow,'💵 $0',{LayoutOrder=1,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,58),TextSize=46,TextScaled=false,TextWrapped=false,TextColor3=colors.Green,Font=Enum.Font.FredokaOne,TextStrokeTransparency=0})
local rebirthText=label(hud.EconomyRow,'♻️ 0',{LayoutOrder=2,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,48),TextSize=31,TextScaled=false,TextWrapped=false,TextColor3=colors.Purple,TextStrokeTransparency=0})
function hud:FitEconomy()
 local width=self.EconomyWidth or 460
 local cashSize,rebirthSize=self.EconomyCompact and 31 or 46,self.EconomyCompact and 24 or 31
 local key=cashText.Text..'|'..rebirthText.Text..'|'..width..'|'..cashSize
 if self.EconomyFitKey==key then return end
 self.EconomyFitKey=key
 self.TextService=self.TextService or game:GetService('TextService')
 local measure=Vector2.new(1000000,1000000)
 local used=self.TextService:GetTextSize(cashText.Text,cashSize,cashText.Font,measure).X+self.TextService:GetTextSize(rebirthText.Text,rebirthSize,rebirthText.Font,measure).X+18
 local scale=math.min(1,math.max(1,width-8)/math.max(1,used))
 cashText.TextSize=math.max(14,math.floor(cashSize*scale))
 rebirthText.TextSize=math.max(14,math.floor(rebirthSize*scale))
end
local incomeText=label(cashBox,'+$0 /s',{Position=UDim2.fromOffset(5,57),Size=UDim2.fromOffset(292,23),TextSize=17,TextColor3=colors.Text,TextStrokeTransparency=0})

local nav=frame(gui,{Name='Navegacao',AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,18,.48,0),Size=UDim2.fromOffset(176,256),BackgroundTransparency=1})
local navButtons={}

local panelName=nil
local panel=frame(gui,{Name='Painel',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.55,.49),Size=UDim2.fromOffset(680,530),BackgroundColor3=colors.Panel,Visible=false})
hud:Studs(panel,18,14)
local panelHeader=frame(panel,{Name='Cabecalho',Size=UDim2.new(1,0,0,64),BackgroundColor3=colors.Blue})
hud:Studs(panelHeader,18,3)
stroke(panel,Color3.new(),4,0)
stroke(panelHeader,Color3.new(),3,0)
local panelTitle=label(panelHeader,"CONSTRUIR",{Position=UDim2.fromOffset(16,4),Size=UDim2.new(1,-80,1,-8),Font=Enum.Font.FredokaOne,TextSize=32,TextStrokeTransparency=0})
local closePanel=button(panelHeader,"X",colors.Red,function() panel.Visible=false panelName=nil end,{Name="Panel_Close",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-10,0,9),Size=UDim2.fromOffset(46,46),TextSize=35})
local tabs=frame(panel,{Position=UDim2.fromOffset(12,76),Size=UDim2.new(1,-24,0,42),BackgroundTransparency=1})
local scroll=create("ScrollingFrame",{Name="Lista",Position=UDim2.fromOffset(12,129),Size=UDim2.new(1,-24,1,-141),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=colors.Blue,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},panel)
create("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
create("UIPadding",{PaddingBottom=UDim.new(0,12),PaddingRight=UDim.new(0,5)},scroll)
local shopTab="Máquinas"
local collectionUI={Tab="Livro",Previews={},Generation=0}
local lastPanelSignature=""
local panelRefresh
local beginBuild
local cancelBuild
local modal

local toasts=frame(gui,{Name="Avisos",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-18,0,117),Size=UDim2.fromOffset(320,64),BackgroundTransparency=1,Visible=false,ClipsDescendants=true})
create("UIListLayout",{Padding=UDim.new(0,8),HorizontalAlignment=Enum.HorizontalAlignment.Right,SortOrder=Enum.SortOrder.LayoutOrder},toasts)
local toastCount=0
local function shortTouchLayout()
 local camera=workspace.CurrentCamera
 if not camera or not UserInputService.TouchEnabled then return false end
 local insetTop,insetBottom=GuiService:GetGuiInset()
 return camera.ViewportSize.Y-insetTop.Y-insetBottom.Y<520
end
local function fitToasts()
 local cards={}
 for _,child in ipairs(toasts:GetChildren()) do if child:IsA("Frame") then table.insert(cards,child) end end
 table.sort(cards,function(a,b) return a.LayoutOrder<b.LayoutOrder end)
 local limit=shortTouchLayout() and 1 or math.max(1,math.min(3,math.floor((toasts.Size.Y.Offset+8)/72)))
 while #cards>limit do cards[1]:Destroy() table.remove(cards,1) end
 toasts.Visible=#cards>0
end
local function toast(message)
 if type(message)=='table' then message=message.Message or message.Text or 'Atualizado' end
 if tostring(message):find('Roube um ovo no corredor',1,true) or tostring(message):find('nasceu! Conecte habitat',1,true) then return end
 toastCount+=1
 local card=frame(toasts,{Size=UDim2.new(1,0,0,64),BackgroundColor3=colors.Background,LayoutOrder=toastCount})
 stroke(card,colors.Gold,1,.4)
 local text=label(card,tostring(message),{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),TextWrapped=true,TextSize=12})
 task.delay(5,function()
  if card.Parent then
   TweenService:Create(card,TweenInfo.new(.3),{BackgroundTransparency=1}):Play()
   TweenService:Create(text,TweenInfo.new(.3),{TextTransparency=1}):Play()
   task.delay(.35,function() if card.Parent then card:Destroy() end fitToasts() end)
  end
 end)
 fitToasts()
end

local build=nil
local selectedId=nil
local touchPoint=nil
local ghostPart=nil
local ghostArrow=nil
local lastCandidateKey=nil
hud.Guide=require(package.Shared:WaitForChild("HudGuide")).new({Gui=gui,Config=C})
hud.GuideToggle=button(gui,'OCULTAR SETA',colors.Card,function()
 hud.Guide:SetHidden(not hud.Guide:IsHidden())
 hud.GuideToggle.Text=hud.Guide:IsHidden() and 'MOSTRAR SETA' or 'OCULTAR SETA'
 hud.GuideToggle.BackgroundColor3=hud.Guide:IsHidden() and colors.Card or Color3.fromRGB(68,86,98)
end,{Name='GuideVisibility',Position=UDim2.fromOffset(18,420),Size=UDim2.fromOffset(176,44),TextSize=14,ZIndex=20})
local highlight=Instance.new("Highlight")
highlight.FillTransparency=.88
highlight.OutlineColor=colors.Blue
highlight.DepthMode=Enum.HighlightDepthMode.Occluded
highlight.Parent=gui

local buildBar=frame(gui,{Name="Construcao",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-102),Size=UDim2.fromOffset(540,100),Visible=false})
stroke(buildBar,Color3.new(),3,0)
local buildTitle=label(buildBar,"CONSTRUIR",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,20),TextSize=13,Font=Enum.Font.FredokaOne})
local buildHint=label(buildBar,"Escolha uma posição dentro da base.",{Position=UDim2.fromOffset(12,31),Size=UDim2.new(1,-24,0,20),TextSize=11,TextColor3=colors.Muted})
local function placeCurrent()
 if build and build.Valid and build.Candidate then
  local b=build.Candidate
  if build.Id then
   send("Move",{BuildId=build.Id,X=b.X,Z=b.Z,R=b.R})
   cancelBuild()
  else
   send("Place",{Kind=b.Kind,X=b.X,Z=b.Z,R=b.R})
   lastCandidateKey=nil
  end
 else toast(build and build.Reason or "Escolha uma posição válida.") end
end
local placeButton=button(buildBar,"COLOCAR",colors.Green,placeCurrent,{Position=UDim2.fromOffset(12,59),Size=UDim2.fromOffset(164,30),TextColor3=colors.Text})
local rotateBuild=button(buildBar,"GIRAR  [R]",colors.Card,function() if build then build.R=(build.R+1)%4 lastCandidateKey=nil end end,{Position=UDim2.fromOffset(184,59),Size=UDim2.fromOffset(164,30)})
local cancelButton=button(buildBar,"CANCELAR",colors.Card,function() cancelBuild() end,{Position=UDim2.fromOffset(356,59),Size=UDim2.fromOffset(172,30)})

local selection=frame(gui,{Name="Selecao",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-102),Size=UDim2.fromOffset(542,92),Visible=false})
stroke(selection,Color3.new(),3,0)
local selectionTitle=label(selection,"HABITAT",{Position=UDim2.fromOffset(12,9),Size=UDim2.new(1,-24,0,23),TextSize=14,Font=Enum.Font.FredokaOne})
local function selectedBuild()
 for _,b in ipairs(state.Builds or {}) do if b.Id==selectedId then return b end end
end
local function selectedCreature()
 for _,c in ipairs(state.Creatures or {}) do if c.HabitatId==selectedId then return c end end
end
local function confirm(title,message,action)
 if modal then modal:Destroy() end
 modal=frame(gui,{Name="Shade",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(),BackgroundTransparency=.3,ZIndex=30,Active=true})
 local box=frame(modal,{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(1,-24,0,210),ZIndex=31})
 hud:Studs(box,10,8)
 create("UISizeConstraint",{MaxSize=Vector2.new(350,210)},box)
 stroke(box,Color3.new(),3,0)
 label(box,title,{Position=UDim2.fromOffset(18,17),Size=UDim2.new(1,-36,0,27),TextSize=18,Font=Enum.Font.FredokaOne,ZIndex=32})
 label(box,message,{Position=UDim2.fromOffset(18,50),Size=UDim2.new(1,-36,0,88),TextSize=13,TextWrapped=true,ZIndex=32})
 button(box,"CANCELAR",colors.Card,function() modal:Destroy() modal=nil end,{Position=UDim2.fromOffset(18,157),Size=UDim2.new(.5,-27,0,35),ZIndex=32})
 button(box,"CONFIRMAR",colors.Gold,function() modal:Destroy() modal=nil action() end,{Position=UDim2.new(.5,9,0,157),Size=UDim2.new(.5,-27,0,35),TextColor3=colors.Text,ZIndex=32})
end
local moveButton=button(selection,"MOVER",colors.Card,function() local b=selectedBuild() if b then beginBuild(b.Kind,b) end end,{Position=UDim2.fromOffset(12,45),Size=UDim2.fromOffset(102,33)})
local rotateSelection=button(selection,"GIRAR",colors.Card,function() local b=selectedBuild() if b then send("Move",{BuildId=b.Id,X=b.X,Z=b.Z,R=(b.R+1)%4}) end end,{Position=UDim2.fromOffset(120,45),Size=UDim2.fromOffset(102,33)})
local storeButton=button(selection,"GUARDAR",colors.Card,function() local b=selectedBuild() if b then send("Store",{BuildId=b.Id}) end end,{Position=UDim2.fromOffset(228,45),Size=UDim2.fromOffset(102,33)})
local releaseButton=button(selection,"LIBERAR",colors.Red,function()
 local creature=selectedCreature()
 if creature then
  confirm("Liberar criatura?",C.Species[creature.Species].Name.." deixará seu tycoon. O habitat ficará disponível para outro ovo.",function() send("ReleaseCreature",{CreatureId=creature.Id}) end)
 else toast("Selecione um habitat ocupado para liberar uma criatura.") end
end,{Position=UDim2.fromOffset(336,45),Size=UDim2.fromOffset(102,33)})
button(selection,"×",colors.Card,function() selectedId=nil selection.Visible=false highlight.Adornee=nil end,{Position=UDim2.fromOffset(444,45),Size=UDim2.fromOffset(85,33),TextSize=21})
local habitatUpgrade=button(selection,"MELHORAR HABITAT",colors.Gold,function()
 local b=selectedBuild()
 if b and b.Kind=="Habitat" and (b.Level or 0)<#C.HabitatPrices then send("UpgradeHabitat",{Id=b.Id}) end
end,{Name="Upgrade_Habitat",Position=UDim2.fromOffset(12,89),Size=UDim2.new(1,-24,0,33),TextSize=11,TextColor3=colors.Text,Visible=false})

local carryBox=frame(gui,{Name="Transporte",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-101),Size=UDim2.fromOffset(460,52),Visible=false})
stroke(carryBox,Color3.new(),3,0)
local carryText=label(carryBox,"OVO",{Position=UDim2.fromOffset(13,7),Size=UDim2.new(1,-116,1,-14),TextWrapped=true,TextSize=12,Font=Enum.Font.FredokaOne})
button(carryBox,"SOLTAR [G]",colors.Card,function() send("Drop") end,{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-9,.5,0),Size=UDim2.fromOffset(100,32),TextSize=10})

cancelBuild=function()
 build=nil buildBar.Visible=false
 if hud.PreviewRoot then hud.PreviewRoot:Destroy();hud.PreviewRoot=nil end
 hud.PreviewModel=nil;hud.PreviewHighlight=nil;hud.PreviewArrowHeads=nil
 ghostPart=nil;ghostArrow=nil
 lastCandidateKey=nil
end
gui.Destroying:Connect(function()
 cancelBuild()
end)
function hud:CreateBuildPreview(kind,existing)
 local root=Instance.new('Folder');root.Name='LocalBuildPreview';self.PreviewRoot=root
 local model
 if existing then
  local world=workspace:FindFirstChild('EggTycoonV3');local plots=world and world:FindFirstChild('Plots')
  local own=plots and state.PlotId and plots:FindFirstChild(string.format('Plot_%02d',state.PlotId))
  local structures=own and own:FindFirstChild('Structures')
  if structures then for _,candidate in ipairs(structures:GetChildren()) do
   if candidate:IsA('Model') and candidate:GetAttribute('BuildId')==existing.Id then model=candidate:Clone();break end
  end end
 end
 if not model then
  local bound,reason=Art.UseReplicatedAssets()
  assert(bound,reason or 'As malhas ainda estão sendo carregadas.')
  model=Art.Structure(kind,CFrame.identity,root)
 end
 model.Name='Ghost_'..kind;model.Parent=root
 for _,object in ipairs(model:GetDescendants()) do
  if object:IsA('LuaSourceContainer') or object:IsA('ProximityPrompt') or object:IsA('ClickDetector') or object:IsA('DragDetector') or object:IsA('LayerCollector') or object:IsA('GuiObject') then
   object:Destroy()
  elseif object:IsA('BasePart') then
   object.Anchored=true;object.CanCollide=false;object.CanTouch=false;object.CanQuery=false;object.CastShadow=false
   object.Transparency=math.max(.45,object.Transparency);object.LocalTransparencyModifier=0
  elseif object:IsA('ParticleEmitter') or object:IsA('Trail') or object:IsA('Beam') then object.Enabled=false
  elseif object:IsA('Sound') then object:Stop() end
 end
 assert(model:FindFirstChildWhichIsA('BasePart',true),'Modelo de prévia vazio.')
 self.PreviewModel=model
 self.PreviewHighlight=create('Highlight',{Name='PreviewValidity',Adornee=model,FillTransparency=.96,OutlineTransparency=0,FillColor=colors.Green,OutlineColor=colors.Green,DepthMode=Enum.HighlightDepthMode.Occluded},root)
 ghostPart=create('Part',{Name='PreviewFootprint',Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false,Material=Enum.Material.Neon,Transparency=.85,Size=Vector3.new(C.Items[kind].W+.3,.08,C.Items[kind].D+.3),Color=colors.Green},root)
 ghostArrow=create('Part',{Name='PreviewDirection',Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,CastShadow=false,Material=Enum.Material.Neon,Transparency=.15,Size=Vector3.new(.22,.12,3),Color=colors.Text},root)
 self.PreviewArrowHeads={}
 for _,side in ipairs({-1,1}) do
  local part=ghostArrow:Clone();part.Name='PreviewDirectionHead';part.Size=Vector3.new(.22,.12,1.05);part.Parent=root
  table.insert(self.PreviewArrowHeads,{Part=part,Side=side})
 end
 local cf=state.PlotCFrame or C.PlotCFrame(state.PlotId)
 local initial=existing and C.ItemCFrame(cf,existing) or cf
 model:PivotTo(initial)
 ghostPart.CFrame=initial*CFrame.new(0,.04,0)
 ghostArrow.CFrame=initial*CFrame.new(0,1,-C.Items[kind].D/2-1.5)
 for _,head in ipairs(self.PreviewArrowHeads) do head.Part.CFrame=ghostArrow.CFrame*CFrame.new(head.Side*.3,0,-1)*CFrame.Angles(0,head.Side*.65,0) end
 root.Parent=workspace
end
beginBuild=function(kind,existing)
 if not hud:InsidePlot() then toast("Entre na sua tycoon para construir.") return end
 if state.Carrying then toast("Entregue ou solte o que está carregando para construir.") return end
 if (state.LastCombatRemaining or 0)>0 then toast("Sua base está sob ataque. Aguarde para editar.") return end
 if not existing and (state.Inventory[kind] or 0)<1 then toast("Compre uma unidade antes de construir.") return end
 cancelBuild()
 local ready,reason=pcall(function() hud:CreateBuildPreview(kind,existing) end)
 if not ready then cancelBuild();toast('Não foi possível preparar a prévia. Aguarde as malhas carregarem e tente novamente.');warn('[EggTycoonV3] Build preview:',reason);return end
 build={Kind=kind,R=existing and existing.R or 0,Id=existing and existing.Id or nil}
 selection.Visible=false selectedId=nil highlight.Adornee=nil
 buildBar.Visible=true
 if UserInputService.TouchEnabled then panel.Visible=false end
 touchPoint=nil
 buildTitle.Text=(existing and "MOVER  •  " or "COLOCAR  •  ")..string.upper(C.Items[kind].Name)
 toast(UserInputService.TouchEnabled and "Toque no chão da sua base para posicionar. Use COLOCAR para confirmar." or "Aponte para o chão da sua base. Clique para colocar; R gira; Esc cancela.")
end

local function clearList()
 collectionUI.Generation+=1
 collectionUI.Previews={}
 for _,child in ipairs(scroll:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
end
local function card(height,name)
 local box=frame(scroll,{Name=name or 'Card_'..tostring(#scroll:GetChildren()),Size=UDim2.new(1,0,0,height or 105),BackgroundColor3=colors.Card})
 stroke(box,Color3.new(),2,0)
 hud:Studs(box,12,3)
 return box
end
local function itemCard(kind)
 local item=C.Items[kind]
 local box=card(UserInputService.TouchEnabled and 120 or 106,"Item_"..kind)
 frame(box,{Position=UDim2.fromOffset(10,12),Size=UDim2.fromOffset(5,32),BackgroundColor3=item.Color})
 label(box,item.Name,{Position=UDim2.fromOffset(24,10),Size=UDim2.new(1,-33,0,25),TextSize=18,Font=Enum.Font.FredokaOne})
 local amount=state.Inventory[kind] or 0
 label(box,string.format("%d guardado(s)  •  %d × %d studs",amount,item.W,item.D),{Position=UDim2.fromOffset(24,37),Size=UDim2.new(1,-33,0,21),TextSize=13,TextColor3=colors.Muted})
 local buy=button(box,"COMPRAR  "..money(item.Price),colors.Green,function() send("BuyItem",{Kind=kind,Count=1}) end,{Name="Buy_"..kind,Position=UDim2.fromOffset(10,66),Size=UDim2.new(.55,-15,0,30),TextSize=13})
 stroke(buy,item.Color,1,.5)
 local place=button(box,"COLOCAR  ("..amount..")",amount>0 and item.Color or colors.Panel,function() beginBuild(kind) end,{Name="Place_"..kind,Position=UDim2.new(.55,0,0,66),Size=UDim2.new(.45,-10,0,30),TextSize=13,TextColor3=amount>0 and colors.Text or colors.Muted})
 sizeButton(place,amount>0)
end
local function upgradeCard(kind,title,description,level,maxLevel,price,color)
 local box=card(UserInputService.TouchEnabled and 156 or 143,"Upgrade_"..kind)
 label(box,title.."  •  "..level.."/"..maxLevel,{Position=UDim2.fromOffset(12,9),Size=UDim2.new(1,-24,0,29),TextSize=18,Font=Enum.Font.FredokaOne,TextColor3=color})
 label(box,description,{Position=UDim2.fromOffset(12,40),Size=UDim2.new(1,-24,0,42),TextSize=13,TextWrapped=true,TextColor3=colors.Muted})
 local buy=button(box,level>=maxLevel and "NÍVEL MÁXIMO" or "MELHORAR  "..money(price),color,function() if level<maxLevel then send("Upgrade",{Kind=kind}) end end,{Position=UDim2.fromOffset(12,94),Size=UDim2.new(1,-24,0,35),TextSize=16,TextColor3=colors.Text})
 sizeButton(buy,level<maxLevel)
end
function collectionUI:Discovered(index)
 return (state.Discovered or {})[tostring(index)]==true or (state.Discovered or {})[index]==true
end
function collectionUI:Count()
 local count=0
 for index in ipairs(C.Species) do if self:Discovered(index) then count+=1 end end
 return count
end
function collectionUI:MissionState(id)
 for _,mission in ipairs(state.Missions or {}) do if mission.Id==id then return mission end end
 return nil
end
function collectionUI:ReadyMissions()
 local ready=0
 for _,mission in ipairs(state.Missions or {}) do if mission.Complete and not mission.Claimed then ready+=1 end end
 return ready
end
function collectionUI:Signature()
 local signature=self.Tab
 if self.Tab=="Livro" then
  for index in ipairs(C.Species) do signature..=self:Discovered(index) and ":1" or ":0" end
 elseif self.Tab=="Missões" then
  for _,mission in ipairs(state.Missions or {}) do signature..=":"..mission.Id..":"..tostring(mission.Current)..":"..tostring(mission.Target)..":"..tostring(mission.Complete)..":"..tostring(mission.Claimed) end
 end
 return signature
end
function collectionUI:BuildPreview(record)
 -- Reuse the server-created, replicated static templates. A book preview allocates
 -- no EditableMesh and never initializes the art pipeline on a client.
 local viewport=record.Viewport
 if not self.Geometry then self.Geometry=require(package.Shared:WaitForChild("GeometryData")) end
 if not viewport.Parent then return false end
 local geometry=self.Geometry
 local definitions=geometry.Models["Species_"..record.Species]
 local assets=package:FindFirstChild("Assets")
 if not definitions or not assets then return false end
 for _,definition in ipairs(definitions) do
  local template=assets:FindFirstChild(definition.Mesh)
  if not template or not template:IsA("MeshPart") then return false end
 end
 local world=create("WorldModel",{Name="PreviewWorld"},viewport)
 local model=create("Model",{Name="SpeciesPreview"},world)
 for _,definition in ipairs(definitions) do
  local piece=assets:FindFirstChild(definition.Mesh):Clone()
  local size=geometry.Meshes[definition.Mesh].Size
  piece.Name=definition.Name
  piece.Size=Vector3.new(math.abs(size[1]*definition.Scale[1]),math.abs(size[2]*definition.Scale[2]),math.abs(size[3]*definition.Scale[3]))
  piece.CFrame=CFrame.new(table.unpack(definition.CF))
  piece.Color=record.Locked and Color3.fromRGB(18,18,22) or Color3.new(table.unpack(definition.Color))
  piece.Material=not record.Locked and definition.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
  piece.Anchored=true;piece.CanCollide=false;piece.CanTouch=false;piece.CanQuery=false
  piece.Parent=model
 end
 local center,size=model:GetBoundingBox()
 local camera=create("Camera",{Name="PreviewCamera",FieldOfView=32},viewport)
 local aspect=viewport.AbsoluteSize.X/math.max(1,viewport.AbsoluteSize.Y)
 local halfFov=math.atan(math.tan(math.rad(camera.FieldOfView*.5))*math.min(1,aspect))
 local distance=math.max(2,size.Magnitude*.5/math.sin(halfFov)*1.08)
 camera.CFrame=CFrame.lookAt(center.Position+Vector3.new(.8,.35,-1).Unit*distance,center.Position)
 viewport.CurrentCamera=camera
 viewport:SetAttribute("PreviewLoaded",true)
 record.Hint.Visible=false
 return true
end
function collectionUI:LoadVisiblePreviews()
 if not panel.Visible or panelName~="Criaturas" or self.Tab~="Livro" then return end
 local top,bottom=scroll.AbsolutePosition.Y,scroll.AbsolutePosition.Y+scroll.AbsoluteSize.Y
 if bottom<=top then return end
 for _,record in ipairs(self.Previews) do
  local viewport=record.Viewport
  if viewport.Parent and not record.Loaded and not record.Loading and not record.Failed
   and viewport.AbsolutePosition.Y<bottom and viewport.AbsolutePosition.Y+viewport.AbsoluteSize.Y>top then
   record.Loading=true
   local generation=self.Generation
   task.defer(function()
    if generation~=self.Generation or not viewport.Parent or not panel.Visible or self.Tab~="Livro" then record.Loading=false;return end
    local ok,result=pcall(function() return self:BuildPreview(record) end)
    record.Loading=false;record.Loaded=ok and result==true
    if not ok then
     record.Failed=true
     record.Hint.Text="Prévia indisponível"
     local world=viewport:FindFirstChild("PreviewWorld");if world then world:Destroy() end
    end
   end)
  end
 end
end
function collectionUI:Book()
 local found=self:Count()
 local summary=card(52,'Book_Summary')
 label(summary,'DESCOBERTAS: '..found..' / '..#C.Species..'  •  7 BIOMAS',{Position=UDim2.fromOffset(12,6),Size=UDim2.new(1,-24,0,38),TextSize=20,Font=Enum.Font.FredokaOne,TextColor3=colors.Text})
 self.Selected=math.clamp(self.Selected or 1,1,#C.Species)
 local width=math.max(245,scroll.AbsoluteSize.X-5)
 local sideBySide=width>=520
 local gridWidth=sideBySide and math.floor(width*.62) or width
 local tile=math.floor((gridWidth-28)/3)
 local gridHeight=tile*3+34
 local book=card(sideBySide and math.max(gridHeight,386) or gridHeight+282,'Book_Index')
 local grid=frame(book,{Name='SpeciesGrid',Position=UDim2.fromOffset(6,6),Size=UDim2.fromOffset(gridWidth-12,gridHeight-12),BackgroundTransparency=1})
 for index,species in ipairs(C.Species) do
  local discovered=self:Discovered(index)
  local column=(index-1)%3;local row=math.floor((index-1)/3)
  local box=button(grid,'',discovered and species.Color or species.Color:Lerp(Color3.fromRGB(85,85,92),.6),function()
   self.Selected=index;panelRefresh()
  end,{Name='Book_Species_'..index,Position=UDim2.fromOffset(column*(tile+8),row*(tile+8)),Size=UDim2.fromOffset(tile,tile),TextSize=14})
  box:SetAttribute("Discovered",discovered)
  if self.Selected==index then stroke(box,colors.Text,3,0) end
  local viewport=create('ViewportFrame',{Name='CreaturePreview',Position=UDim2.fromOffset(4,24),Size=UDim2.new(1,-8,1,-48),BackgroundTransparency=1,BorderSizePixel=0,
   Ambient=Color3.fromRGB(190,190,210),LightColor=Color3.fromRGB(255,247,226),LightDirection=Vector3.new(-1,-1,-1)},box)
  local hint=label(viewport,discovered and '...' or '?',{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,TextSize=34})
  table.insert(self.Previews,{Viewport=viewport,Hint=hint,Species=index,Locked=not discovered})
  label(box,discovered and species.Name or '???',{Position=UDim2.fromOffset(3,1),Size=UDim2.new(1,-6,0,26),TextSize=math.clamp(tile/8,11,17),TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.FredokaOne})
  label(box,species.Biome,{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,3,1,-2),Size=UDim2.new(1,-6,0,20),TextSize=11,TextXAlignment=Enum.TextXAlignment.Center})
 end
 local selected=C.Species[self.Selected];local discovered=self:Discovered(self.Selected)
 local detail=frame(book,{Name='Book_Details',Position=UDim2.fromOffset(sideBySide and gridWidth+4 or 6,sideBySide and 6 or gridHeight+4),Size=sideBySide and UDim2.new(1,-gridWidth-10,1,-12) or UDim2.new(1,-12,0,266),BackgroundColor3=colors.Background})
 stroke(detail,selected.Color,3,0);hud:Studs(detail,6,8)
 label(detail,discovered and selected.Name or '???',{Position=UDim2.fromOffset(8,6),Size=UDim2.new(1,-16,0,32),TextSize=23,TextXAlignment=Enum.TextXAlignment.Center,TextColor3=selected.Color})
 label(detail,selected.Biome,{Position=UDim2.fromOffset(8,40),Size=UDim2.new(1,-16,0,23),TextSize=17,TextXAlignment=Enum.TextXAlignment.Center})
 if discovered then
  label(detail,'RENDA BÁSICA\n'..money(selected.Rate)..' /s',{Position=UDim2.fromOffset(9,77),Size=UDim2.new(1,-18,0,58),TextSize=23,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Center,TextColor3=colors.Green})
  label(detail,'Recurso: '..selected.Resource..'\nIncubação: '..selected.Hatch..'s\nProduz a cada 4s\nGuardião: '..selected.Speed..' velocidade\nDano: '..selected.Damage,{Position=UDim2.fromOffset(12,151),Size=UDim2.new(1,-24,0,109),TextSize=sideBySide and 13 or 14,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top})
 else
  label(detail,'CRIATURA\nDESCONHECIDA',{Position=UDim2.fromOffset(10,79),Size=UDim2.new(1,-20,0,66),TextSize=25,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Center,TextColor3=colors.Muted})
  label(detail,'Roube um ovo no bioma '..selected.Biome..' e incube na sua base para revelar esta espécie.',{Position=UDim2.fromOffset(12,166),Size=UDim2.new(1,-24,0,88),TextSize=14,TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top})
 end
 local footer=card(46,'Book_Progress')
 label(footer,'📖  Coleção: '..found..' / '..#C.Species..'  •  Mantida ao renascer',{Position=UDim2.fromOffset(10,4),Size=UDim2.new(1,-20,1,-8),TextSize=17,TextXAlignment=Enum.TextXAlignment.Center})
end
function collectionUI:Missions()
 local ready=self:ReadyMissions()
 local summary=card(88,"Missions_Summary")
 label(summary,ready>0 and ready.." RECOMPENSA(S) DISPONÍVEL(IS)" or "SUA PRÓXIMA CONQUISTA",{Position=UDim2.fromOffset(12,6),Size=UDim2.new(1,-24,0,31),TextSize=17,Font=Enum.Font.FredokaOne,TextColor3=ready>0 and colors.Gold or colors.Blue})
 label(summary,"Complete objetivos e receba peças para expandir sua base. Progresso e recompensas permanecem registrados.",{Position=UDim2.fromOffset(12,39),Size=UDim2.new(1,-24,0,40),TextSize=13,TextWrapped=true,TextColor3=colors.Muted})
 for _,definition in ipairs(C.Missions or {}) do
  local mission=self:MissionState(definition.Id) or {Current=0,Target=definition.Target,Complete=false,Claimed=false}
  local target=math.max(1,tonumber(mission.Target) or definition.Target or 1)
  local current=math.clamp(tonumber(mission.Current) or 0,0,target)
  local claimed,complete=mission.Claimed==true,mission.Complete==true
  local tint=claimed and colors.Green or complete and colors.Gold or colors.Blue
  local box=card(234,"Mission_"..definition.Id)
  box:SetAttribute("Complete",complete);box:SetAttribute("Claimed",claimed)
  stroke(box,tint,1,.55)
  label(box,definition.Name,{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,29),TextSize=20,Font=Enum.Font.FredokaOne,TextColor3=tint})
  label(box,definition.Description,{Position=UDim2.fromOffset(12,42),Size=UDim2.new(1,-24,0,41),TextSize=15,TextWrapped=true,TextColor3=colors.Muted})
  label(box,(claimed and "RECEBIDA" or complete and "CONCLUÍDA" or "EM ANDAMENTO").."   "..current.." / "..target,{Position=UDim2.fromOffset(12,88),Size=UDim2.new(1,-24,0,20),TextSize=13,TextColor3=tint,Font=Enum.Font.FredokaOne})
  local track=frame(box,{Position=UDim2.fromOffset(12,115),Size=UDim2.new(1,-24,0,7),BackgroundColor3=colors.Background})
  frame(track,{Size=UDim2.fromScale(current/target,1),BackgroundColor3=tint})
  local rewards={}
  for kind,amount in pairs(definition.Rewards or {}) do table.insert(rewards,tostring(amount).." × "..(C.Items[kind] and C.Items[kind].Name or kind)) end
  table.sort(rewards)
  label(box,"Recompensa: "..table.concat(rewards,"  •  "),{Position=UDim2.fromOffset(12,130),Size=UDim2.new(1,-24,0,34),TextSize=14,TextWrapped=true,TextColor3=colors.Text})
  local claim=button(box,claimed and "RECOMPENSA RECEBIDA" or complete and "RECEBER RECOMPENSA" or "COMPLETE O OBJETIVO",complete and not claimed and colors.Gold or colors.Panel,function()
   if complete and not claimed then send("ClaimMission",{Id=definition.Id}) end
  end,{Name="Claim_"..definition.Id,Position=UDim2.fromOffset(12,178),Size=UDim2.new(1,-24,0,44),TextSize=16,TextColor3=colors.Text})
  sizeButton(claim,complete and not claimed)
 end
end
scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function() collectionUI:LoadVisiblePreviews() end)
panelRefresh=function()
 if not panelName then return end
 clearList()
 for _,child in ipairs(tabs:GetChildren()) do child:Destroy() end
 panelHeader.BackgroundColor3=panelName=='Construir' and colors.Green or panelName=='Rebirth' and colors.Purple or panelName=='Missoes' and colors.Gold or colors.Blue
 if panelName=="Construir" then
  panelTitle.Text="OFICINA DO TYCOON"
  for index,name in ipairs({"Máquinas","Esteiras","Melhorias"}) do
   button(tabs,name,shopTab==name and colors.Blue or colors.Card,function() shopTab=name panelRefresh() end,{Name=index==1 and "Tab_Machines" or index==2 and "Tab_Belts" or "Tab_Upgrades",Position=UDim2.new((index-1)/3,0,0,0),Size=UDim2.new(1/3,-5,1,0),TextSize=16,TextColor3=colors.Text})
  end
  if shopTab=='Melhorias' then
   local battery,weapon,speed,processor=state.BatteryLevel or 1,state.WeaponLevel or 0,state.SpeedLevel or 0,state.ProcessorLevel or 1
   upgradeCard('Battery','🔋 Bateria','Mais resistência para defender sua entrada.',battery,4,C.BatteryPrices[battery] or 0,colors.Blue)
   upgradeCard('Weapon','🔫 Armas','Blasters com energia recarregável.',weapon,2,C.WeaponPrices[weapon+1] or 0,colors.Red)
   upgradeCard('Speed','👟 Velocidade','Corra mais para escapar dos guardiões.',speed,5,C.SpeedPrices[speed+1] or 0,colors.Green)
   upgradeCard('Processor','⚙️ Processamento','Mais valor em cada recurso processado.',processor,3,C.ProcessorPrices[processor] or 0,colors.Gold)
  else
   for _,kind in ipairs(shopTab=='Máquinas' and {'Habitat','Incubator','Processor','Seller'} or {'Belt','Curve','Merge'}) do itemCard(kind) end
  end
  local hint=card(78)
  label(hint,"SAÍDA → ESTEIRAS → PROCESSADOR → VENDEDOR\nToque numa máquina da sua base para movê-la, girá-la ou guardá-la.",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),TextSize=10,TextWrapped=true,TextColor3=colors.Muted})
 elseif panelName=="Criaturas" then
  panelTitle.Text="📖 Livro de criaturas"
  for index,tab in ipairs({{"Livro","Tab_Book"},{"Habitats","Tab_Habitats"}}) do
   local name=tab[1]
   button(tabs,name,collectionUI.Tab==name and colors.Green or colors.Card,function() collectionUI.Tab=name;scroll.CanvasPosition=Vector2.zero;panelRefresh() end,{Name=tab[2],Position=UDim2.new((index-1)/2,0,0,0),Size=UDim2.new(1/2,-5,1,0),TextSize=16,TextColor3=colors.Text})
  end
  if collectionUI.Tab=="Livro" then collectionUI:Book()
  elseif collectionUI.Tab=="Missões" then collectionUI:Missions()
  else
  local occupancy=card(48,"Habitats_Summary")
  label(occupancy,tostring(#(state.Creatures or {})).." / "..C.MaxHabitats.." HABITATS OCUPADOS",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),TextSize=12,TextColor3=colors.Green,Font=Enum.Font.FredokaOne})
  if #(state.Creatures or {})==0 then
   local empty=card(115)
   label(empty,"Seu primeiro companheiro está esperando!\nRoube um ovo no Campo e leve à incubadora.",{Position=UDim2.fromOffset(16,12),Size=UDim2.new(1,-32,1,-24),TextWrapped=true,TextSize=13})
  end
  for _,creature in ipairs(state.Creatures or {}) do
   local species=C.Species[creature.Species]
   local box=card(UserInputService.TouchEnabled and 120 or 106,"Creature_"..creature.Id)
   label(box,species.Name,{Position=UDim2.fromOffset(12,10),Size=UDim2.new(1,-24,0,22),TextSize=15,Font=Enum.Font.FredokaOne,TextColor3=species.Color})
   label(box,species.Resource.."  •  estoque "..tostring(creature.Stored or 0).."/20",{Position=UDim2.fromOffset(12,37),Size=UDim2.new(1,-24,0,17),TextSize=10,TextColor3=colors.Muted})
   button(box,"SELECIONAR HABITAT",colors.Card,function()
    if not hud:InsidePlot() then toast('Entre na sua tycoon para editar o habitat.');return end
    selectedId=creature.HabitatId
    selection.Visible=true
    panel.Visible=false panelName=nil
   end,{Position=UDim2.fromOffset(12,65),Size=UDim2.new(1,-24,0,30),TextSize=11})
  end
  local collection=card(52)
  local found=collectionUI:Count()
  label(collection,"COLEÇÃO DESCOBERTA   "..found.." / 7",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),TextSize=12,TextColor3=colors.Gold,Font=Enum.Font.FredokaOne})
  end
 elseif panelName=='Missoes' then
  panelTitle.Text='📜 Missões'
  label(tabs,'Complete objetivos e desbloqueie recompensas!',{Size=UDim2.fromScale(1,1),TextSize=16,TextColor3=colors.Gold})
  collectionUI:Missions()
 elseif panelName=="Rebirth" then
  panelTitle.Text="♻️ Renascer"
  label(tabs,"Recomece com produção permanente maior.",{Size=UDim2.fromScale(1,1),TextSize=11,TextColor3=colors.Muted})
  local box=card(334,"Rebirth_Details")
  local count=state.Rebirths or 0
  local cost=C.RebirthCost*3^count
  label(box,"+25% DE PRODUÇÃO",{Position=UDim2.fromOffset(14,15),Size=UDim2.new(1,-28,0,42),TextSize=28,Font=Enum.Font.FredokaOne,TextColor3=colors.Purple})
  label(box,"Bônus atual: +"..math.floor(count*C.RebirthMultiplier*100).."%\nPróximo bônus: +"..math.floor((count+1)*C.RebirthMultiplier*100).."%\n\nDinheiro, criaturas e compras recomeçam. Sua coleção e seu bônus permanecem. Você recebe o kit inicial novamente.",{Position=UDim2.fromOffset(14,70),Size=UDim2.new(1,-28,0,180),TextSize=16,TextWrapped=true,TextColor3=colors.Muted})
  button(box,"RENASCER  "..money(cost),colors.Purple,function()
   if (state.Cash or 0)<cost then toast("Você precisa de "..money(cost).." para renascer.") return end
   confirm("Renascimento", "Você recomeçará com o kit inicial e ganhará +25% de produção permanente. Sua coleção será mantida.",function() send("Rebirth") end)
  end,{Position=UDim2.fromOffset(14,275),Size=UDim2.new(1,-28,0,44),TextSize=18,TextColor3=colors.Text})
 end
 if panelName=="Criaturas" and collectionUI.Tab~="Habitats" then lastPanelSignature=collectionUI:Signature() end
 task.defer(function() collectionUI:LoadVisiblePreviews() end)
end

for index,entry in ipairs({{'Construir','🔨','Construir',colors.Green},{'Criaturas','📖','Livro',colors.Blue},{'Rebirth','♻️','Renascer',colors.Purple},{'Missoes','📜','Missões',colors.Gold}}) do
 local name,icon,title,color=entry[1],entry[2],entry[3],entry[4]
 local b=button(nav,icon..' '..title,color,function()
  if name=='Construir' and not hud:InsidePlot() then return end
  if panelName==name and panel.Visible then panel.Visible=false panelName=nil return end
  if name=='Criaturas' then collectionUI.Tab='Livro' end
  panelName=name;panel.Visible=true;scroll.CanvasPosition=Vector2.zero;panelRefresh()
 end,{Name='Nav_'..name,Position=UDim2.fromOffset(0,(index-1)*64),Size=UDim2.new(1,0,0,56),TextSize=23,TextColor3=colors.Text,Visible=name~='Construir'})
 b:SetAttribute('Icon',icon);b:SetAttribute('Title',title)
 navButtons[index]=b
end
hud.MissionBadge=label(navButtons[4],'0',{Name='RecompensasDisponiveis',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(1,-3,0,3),Size=UDim2.fromOffset(24,24),TextSize=16,TextXAlignment=Enum.TextXAlignment.Center,TextColor3=colors.Text,BackgroundColor3=colors.Red,Visible=false,ZIndex=3})
hud.MissionBadge.BackgroundTransparency=0;round(hud.MissionBadge,5);stroke(hud.MissionBadge,Color3.new(),2,0)

local function plot()
 local world=workspace:FindFirstChild("EggTycoonV3")
 local plots=world and world:FindFirstChild("Plots")
 return plots and state.PlotId and plots:FindFirstChild(string.format("Plot_%02d",state.PlotId))
end
local function plotFrame()
 return state.PlotCFrame or (state.PlotId and C.PlotCFrame(state.PlotId))
end
local function refreshSelection()
 if not hud:InsidePlot() then selection.Visible=false;highlight.Adornee=nil;return end
 local b=selectedBuild()
 if not b then
  selectedId=nil selection.Visible=false highlight.Adornee=nil
  return
 end
 if build or state.Carrying then selection.Visible=false return end
 selection.Visible=true
 local creature=selectedCreature()
 local level=b.Level or 0
 selectionTitle.Text=string.upper(C.Items[b.Kind].Name)..(b.Kind=="Habitat" and "  •  NÍVEL "..level or "")..(creature and "  •  "..C.Species[creature.Species].Name or "")
 habitatUpgrade.Visible=b.Kind=="Habitat"
 if habitatUpgrade.Visible then
  local price=C.HabitatPrices[level+1]
  local multiplier=C.HabitatMultipliers[math.min(level+2,#C.HabitatMultipliers)]
  habitatUpgrade.Text=price and ("MELHORAR  "..money(price).."  •  PRODUÇÃO +"..math.floor((multiplier-1)*100).."%") or "HABITAT NO NÍVEL MÁXIMO  •  PRODUÇÃO +75%"
  sizeButton(habitatUpgrade,price~=nil and (state.Cash or 0)>=price and (state.LastCombatRemaining or 0)<=0)
 end
 selection.Size=UDim2.fromOffset(math.min(540,workspace.CurrentCamera.ViewportSize.X-24),habitatUpgrade.Visible and (UserInputService.TouchEnabled and 147 or 136) or (UserInputService.TouchEnabled and 103 or 92))
 sizeButton(releaseButton,creature~=nil)
 local p=plot()
 local structures=p and p:FindFirstChild("Structures")
 if structures then
  for _,model in ipairs(structures:GetChildren()) do if model:GetAttribute("BuildId")==b.Id then highlight.Adornee=model break end end
 end
end

local function refreshHUD()
 cashText.Text='💵 '..money(state.Cash)
 incomeText.Text='+'..money(state.Income)..' /s'
 local rebirths=math.max(0,math.floor(tonumber(state.Rebirths) or 0))
 rebirthText.Text='♻️ '..(rebirths>=10000 and money(rebirths):sub(2) or tostring(rebirths))
 rebirthText:SetAttribute('FullCount',rebirths)
 hud:FitEconomy()
 local ready=collectionUI:ReadyMissions()
 hud.MissionBadge.Visible=ready>0;hud.MissionBadge.Text=tostring(ready)
 carryBox.Visible=state.Carrying==true and not build
 carryText.Text=tostring(state.Carry or 'Transportando')..'\nArmas indisponíveis • velocidade −10%'
 refreshSelection()
end

local function responsive()
 local camera=workspace.CurrentCamera;if not camera then return end
 local viewport=camera.ViewportSize
 local top,bottom=GuiService:GetGuiInset()
 local height=math.max(180,viewport.Y-top.Y-bottom.Y)
 local touch=UserInputService.TouchEnabled
 local compact=viewport.X<900 or height<520
 local sidebarWidth=compact and 130 or 176
 local buttonHeight=compact and 45 or 56
 local gap=compact and 6 or 8
 local sidebarHeight=buttonHeight*4+gap*3
 nav.AnchorPoint=touch and compact and Vector2.zero or Vector2.new(0,.5)
 nav.Size=UDim2.fromOffset(sidebarWidth,touch and compact and 94 or sidebarHeight)
 nav.Position=touch and compact and UDim2.fromOffset(10,12) or UDim2.new(0,compact and 10 or 18,.47,0)
 if touch and compact and height>=300 then
  hud.GuideToggle.Position=UDim2.fromOffset(10,114)
  hud.GuideToggle.Size=UDim2.fromOffset(130,44)
 elseif compact then
  -- Short landscapes reserve the upper-right strip for alerts.
  hud.GuideToggle.Position=UDim2.fromOffset(math.max(10,viewport.X-166),88)
  hud.GuideToggle.Size=UDim2.fromOffset(150,44)
 else
  hud.GuideToggle.Position=UDim2.fromOffset(18,math.min(height-150,height*.47+sidebarHeight/2+12))
  hud.GuideToggle.Size=UDim2.fromOffset(sidebarWidth,44)
 end
 hud.GuideToggle.TextSize=compact and 12 or 14
 for index,b in ipairs(navButtons) do
  if touch and compact then
   local column=index>2 and 1 or 0;local row=(index-1)%2
   b.Size=UDim2.fromOffset(61,44);b.Position=UDim2.fromOffset(column*68,row*50)
   b.Text=b:GetAttribute('Icon')..'\n'..b:GetAttribute('Title');b.TextSize=13
  else
   b.Size=UDim2.new(1,0,0,buttonHeight);b.Position=UDim2.fromOffset(0,(index-1)*(buttonHeight+gap));b.TextSize=compact and 17 or 23
   b.Text=b:GetAttribute('Icon')..' '..b:GetAttribute('Title')
  end
 end
 cashBox.Position=UDim2.new(0,compact and 12 or 18,1,touch and compact and -100 or -18)
 -- The list layout alone positions the natural-width labels, keeping the counter
 -- ten pixels beside the amount without a second writer resetting its X position.
 local economyWidth=math.min(compact and 360 or 460,math.max(216,viewport.X-24))
 cashBox.Size=UDim2.fromOffset(economyWidth,touch and compact and 38 or compact and 56 or 83)
 hud.EconomyRow.Size=UDim2.new(1,0,0,compact and 38 or 58)
 local cashHeight,rebirthHeight=compact and 38 or 58,compact and 38 or 48
 if cashText.Size.Y.Offset~=cashHeight then cashText.Size=UDim2.fromOffset(0,cashHeight) end
 if rebirthText.Size.Y.Offset~=rebirthHeight then rebirthText.Size=UDim2.fromOffset(0,rebirthHeight) end
 hud.EconomyCompact=compact;hud.EconomyWidth=economyWidth;hud:FitEconomy()
 incomeText.Position=UDim2.fromOffset(5,compact and 36 or 57)
 incomeText.TextSize=compact and 13 or 17
 incomeText.Size=UDim2.fromOffset(math.min(240,economyWidth),20)
 incomeText.Visible=not (touch and compact)
 local panelWidth=math.min(700,viewport.X-(compact and 158 or 240))
 if viewport.X<560 then panelWidth=viewport.X-24 end
 local panelHeight=math.min(570,height-(compact and 20 or 80))
 panel.AnchorPoint=Vector2.new(.5,.5)
 panel.Position=UDim2.new(viewport.X<560 and .5 or .57,0,.48,0)
 panel.Size=UDim2.fromOffset(math.max(250,panelWidth),math.max(180,panelHeight))
 panelHeader.Size=UDim2.new(1,0,0,compact and 48 or 64)
 panelTitle.TextSize=compact and 23 or 32
 closePanel.Size=UDim2.fromOffset(touch and 44 or compact and 36 or 46,touch and 44 or compact and 36 or 46)
 closePanel.Position=UDim2.new(1,-8,0,compact and 6 or 9)
 closePanel.TextSize=compact and 28 or 35
 local tabsY=compact and 56 or 76
 tabs.Position=UDim2.fromOffset(12,tabsY)
 tabs.Size=UDim2.new(1,-24,0,touch and 44 or 42)
 local listY=tabsY+(touch and 44 or 42)+10
 scroll.Position=UDim2.fromOffset(12,listY)
 scroll.Size=UDim2.new(1,-24,1,-listY-12)
 local toastHeight=compact and 64 or 200
 toasts.Position=UDim2.new(1,-16,0,compact and 12 or 24)
 toasts.Size=UDim2.fromOffset(math.min(320,viewport.X-36),toastHeight)
 fitToasts()
 local width=math.min(540,viewport.X-24)
 buildBar.Position=UDim2.new(.5,0,1,compact and -72 or -100)
 buildBar.Size=UDim2.fromOffset(width,touch and 114 or 100)
 selection.Position=buildBar.Position
 selection.Size=UDim2.fromOffset(width,habitatUpgrade.Visible and (touch and 147 or 136) or (touch and 103 or 92))
 habitatUpgrade.Size=UDim2.new(1,-24,0,touch and 44 or 33)
 for index,b in ipairs({placeButton,rotateBuild,cancelButton}) do b.Position=UDim2.new((index-1)/3,8,0,59);b.Size=UDim2.new(1/3,-12,0,touch and 44 or 30);b.TextSize=compact and 11 or 14 end
 for index,b in ipairs({moveButton,rotateSelection,storeButton,releaseButton}) do b.Position=UDim2.new((index-1)/5,8,0,45);b.Size=UDim2.new(1/5,-10,0,touch and 44 or 33);b.TextSize=compact and 9 or 12 end
 for _,b in ipairs(selection:GetChildren()) do if b:IsA('TextButton') and b.Text=='×' then b.Position=UDim2.new(.8,8,0,45);b.Size=UDim2.new(.2,-18,0,touch and 44 or 33) end end
 carryBox.Position=UDim2.new(.5,0,1,compact and -70 or -100)
 carryBox.Size=UDim2.fromOffset(math.min(460,viewport.X-24),touch and 62 or 52)
end
local function panelVisibility()
 local small=UserInputService.TouchEnabled
 cashBox.Visible=not (small and panel.Visible)
 nav.Visible=not (panel.Visible and (small or workspace.CurrentCamera.ViewportSize.X<560))
 hud.GuideToggle.Visible=not panel.Visible
end

-- One listener per persistent container; card refreshes do not add listeners.
panel:GetPropertyChangedSignal("Visible"):Connect(panelVisibility)
buildBar:GetPropertyChangedSignal("Visible"):Connect(panelVisibility)
selection:GetPropertyChangedSignal("Visible"):Connect(panelVisibility)
carryBox:GetPropertyChangedSignal("Visible"):Connect(panelVisibility)
toasts:GetPropertyChangedSignal("Visible"):Connect(panelVisibility)
panelVisibility()

local function worldPoint(screen)
 local camera=workspace.CurrentCamera
 local ray=camera:ScreenPointToRay(screen.X,screen.Y)
 if math.abs(ray.Direction.Y)<.001 then return end
 local distance=-ray.Origin.Y/ray.Direction.Y
 if distance<=0 or distance>3000 then return end
 return ray.Origin+ray.Direction*distance
end
local function updateGhost()
 if not build or not ghostPart or not hud.PreviewModel then return end
 local cf=plotFrame()
 if not cf then return end
 local point
 if UserInputService.TouchEnabled and touchPoint then point=touchPoint
 else
  local camera=workspace.CurrentCamera
  local screen=UserInputService.TouchEnabled and Vector2.new(camera.ViewportSize.X*.5,camera.ViewportSize.Y*.55) or UserInputService:GetMouseLocation()
  point=worldPoint(screen)
 end
 if not point then return end
 local localPoint=cf:PointToObjectSpace(point)
 local x=math.round(localPoint.X/C.Grid)*C.Grid
 local z=math.round(localPoint.Z/C.Grid)*C.Grid
 local candidate={Id=build.Id or "Preview",Kind=build.Kind,X=x,Z=z,R=build.R}
 local key=build.Kind..":"..x..":"..z..":"..build.R
 if key~=lastCandidateKey then
  local valid,reason=Rules.Validate(state.Builds or {},candidate,build.Id,state.PlotHalf or C.PlotHalf)
  if not build.Id and (state.Inventory[build.Kind] or 0)<1 then valid=false reason="Sem unidades guardadas. Compre mais na oficina." end
  if (state.LastCombatRemaining or 0)>0 then valid=false reason="Edição bloqueada durante combate." end
  build.Valid=valid build.Reason=reason build.Candidate=candidate lastCandidateKey=key
  ghostPart.Color=valid and colors.Green or colors.Red
  hud.PreviewHighlight.OutlineColor=ghostPart.Color;hud.PreviewHighlight.FillColor=ghostPart.Color
  buildHint.Text=valid and ("Posição válida  •  "..x..", "..z.."  •  saída indicada em branco") or tostring(reason or "Posição inválida")
  buildHint.TextColor3=valid and colors.Green or colors.Red
  sizeButton(placeButton,valid)
 end
 local itemCF=C.ItemCFrame(cf,candidate)
 hud.PreviewModel:PivotTo(itemCF)
 ghostPart.CFrame=itemCF*CFrame.new(0,.04,0)
 ghostArrow.CFrame=itemCF*CFrame.new(0,1,-C.Items[build.Kind].D/2-1.5)
 for _,head in ipairs(hud.PreviewArrowHeads or {}) do head.Part.CFrame=ghostArrow.CFrame*CFrame.new(head.Side*.3,0,-1)*CFrame.Angles(0,head.Side*.65,0) end
end

local function selectAt(screen)
 if modal then return end
 if not hud:InsidePlot() then return end
 local camera=workspace.CurrentCamera
 local ray=camera:ScreenPointToRay(screen.X,screen.Y)
 if build then
  local point=worldPoint(screen)
  if point then touchPoint=point lastCandidateKey=nil updateGhost() end
  if not UserInputService.TouchEnabled and build and build.Valid then placeCurrent() end
  return
 end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded=player.Character and {player.Character} or {}
 if hud.PreviewRoot then table.insert(excluded,hud.PreviewRoot) end
 local own=plot()
 if own then
  for _,part in ipairs(own:GetChildren()) do
   if part.Name=="Roof" or part.Name=="RoofFrame" or part.Name=="RoofCollision" or part.Name=="Perimeter" then table.insert(excluded,part) end
  end
 end
 params.FilterDescendantsInstances=excluded
 local result=workspace:Raycast(ray.Origin,ray.Direction*1500,params)
 if not result then return end
 local object=result.Instance
 local found
 while object and object~=workspace do
  if object:GetAttribute("BuildId") then found=object break end
  object=object.Parent
 end
 if found and own and found:IsDescendantOf(own) then
  selectedId=found:GetAttribute("BuildId")
  refreshSelection()
 elseif not state.Carrying then selectedId=nil selection.Visible=false highlight.Adornee=nil end
end

local equipped=nil
local hookedTools=setmetatable({},{__mode="k"})
local crosshair=label(gui,"+",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(24,24),TextSize=28,TextXAlignment=Enum.TextXAlignment.Center,Visible=false,TextColor3=colors.Text})
local function aim()
 if UserInputService.TouchEnabled then
  local camera=workspace.CurrentCamera
  local ray=camera:ViewportPointToRay(camera.ViewportSize.X*.5,camera.ViewportSize.Y*.5)
  return ray.Origin+ray.Direction*200
 end
 return mouse.Hit.Position
end
local function attack()
 if not equipped or state.Carrying or build or modal or state.NeedsClaim or not state.PlotId then return end
 local kind=equipped:GetAttribute("WeaponKind")
 if not C.Weapons[kind] then return end
 send("Attack",{Weapon=kind,Target=aim()})
end
local mobileAttack=button(gui,"ATIRAR",colors.Red,attack,{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-28,1,-180),Size=UDim2.fromOffset(86,62),TextSize=13,Visible=false})
stroke(mobileAttack,colors.Text,1,.6)
local function hookTool(tool)
 if not tool:IsA("Tool") or hookedTools[tool] then return end
 hookedTools[tool]=true
 tool.Equipped:Connect(function()
  if state.NeedsClaim or not state.PlotId then
   equipped=nil;crosshair.Visible=false;mobileAttack.Visible=false
   local humanoid=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
   if humanoid then humanoid:UnequipTools() end
   return
  end
  equipped=tool
  crosshair.Visible=UserInputService.TouchEnabled and tool:GetAttribute("WeaponKind")~="Baton"
  mobileAttack.Visible=UserInputService.TouchEnabled
  mobileAttack.Text=tool:GetAttribute("WeaponKind")=="Baton" and "GOLPEAR" or "ATIRAR"
 end)
 tool.Unequipped:Connect(function()
  if equipped==tool then equipped=nil crosshair.Visible=false mobileAttack.Visible=false end
 end)
 tool.Activated:Connect(attack)
end
local function hookCharacter(character)
 equipped=nil crosshair.Visible=false mobileAttack.Visible=false
 for _,tool in ipairs(character:GetChildren()) do hookTool(tool) end
 character.ChildAdded:Connect(hookTool)
 cancelBuild()
end
if player.Character then hookCharacter(player.Character) end
player.CharacterAdded:Connect(hookCharacter)
local backpack=player:WaitForChild("Backpack")
for _,tool in ipairs(backpack:GetChildren()) do hookTool(tool) end
backpack.ChildAdded:Connect(hookTool)

UserInputService.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.B then
  if not hud:InsidePlot() then return end
  local closing=panelName=='Construir' and panel.Visible
  panelName="Construir" panel.Visible=not closing
  if panel.Visible then panelRefresh() end
 elseif input.KeyCode==Enum.KeyCode.R and build then build.R=(build.R+1)%4 lastCandidateKey=nil
 elseif input.KeyCode==Enum.KeyCode.Escape then cancelBuild() selectedId=nil selection.Visible=false highlight.Adornee=nil
 elseif input.KeyCode==Enum.KeyCode.G and state.Carrying then send("Drop")
 elseif input.UserInputType==Enum.UserInputType.MouseButton1 and not UserInputService.TouchEnabled then selectAt(UserInputService:GetMouseLocation()) end
end)
UserInputService.TouchTapInWorld:Connect(function(position,processed) if not processed then selectAt(position) end end)

local effects=Instance.new("Folder")
effects.Name="EggTycoonV3LocalFX"
effects.Parent=workspace
local activeResources=0
local productionPulses={}
local function resource(payload)
 if type(payload.CreatureId)=="string" then productionPulses[payload.CreatureId]=os.clock() end
 if activeResources>=100 or type(payload.Path)~="table" or #payload.Path<2 then return end
 local path=payload.Path
 local species=C.Species[payload.Species or 1]
 local part=create("Part",{Name="Recurso",Shape=Enum.PartType.Ball,Size=Vector3.new(.8,.8,.8),Color=payload.Processed and colors.Gold or species.Color,Material=Enum.Material.Neon,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Position=path[1]+Vector3.new(0,1.3,0)},effects)
 activeResources+=1
 task.spawn(function()
  for index=2,#path do
   if not part.Parent or typeof(path[index])~="Vector3" then break end
   local distance=(path[index]-path[index-1]).Magnitude
   local tween=TweenService:Create(part,TweenInfo.new(math.clamp(distance/26,.06,.8),Enum.EasingStyle.Linear),{Position=path[index]+Vector3.new(0,1.3,0)})
   tween:Play() tween.Completed:Wait()
  end
  part:Destroy() activeResources-=1
 end)
end
local function shot(payload)
 if typeof(payload.From)~="Vector3" or typeof(payload.To)~="Vector3" then return end
 local distance=(payload.To-payload.From).Magnitude
 if distance<.01 then return end
 local part=create("Part",{Name="Disparo",Size=Vector3.new(.15,.15,distance),CFrame=CFrame.lookAt((payload.From+payload.To)*.5,payload.To),Material=Enum.Material.Neon,Color=payload.Color or colors.Blue,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false},effects)
 TweenService:Create(part,TweenInfo.new(.2),{Transparency=1}):Play()
 Debris:AddItem(part,.25)
end
local function ring(payload)
 local position=payload.Position or payload.At
 if typeof(position)~="Vector3" then return end
 local radius=payload.Radius or 5
 local part=create("Part",{Name="AvisoGuardiao",Shape=Enum.PartType.Cylinder,Size=Vector3.new(.12,radius*2,radius*2),CFrame=CFrame.new(position.X,.18,position.Z)*CFrame.Angles(0,0,math.pi/2),Color=payload.Color or colors.Red,Transparency=.55,Material=Enum.Material.Neon,Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false},effects)
 TweenService:Create(part,TweenInfo.new(payload.Duration or .6),{Transparency=.9,Size=Vector3.new(.12,radius*2.3,radius*2.3)}):Play()
 Debris:AddItem(part,(payload.Duration or .6)+.1)
end
fxRemote.OnClientEvent:Connect(function(kind,payload)
 payload=payload or {}
 if kind=="Resource" then resource(payload)
 elseif kind=="Shot" then shot(payload)
 elseif kind=="Telegraph" or kind=="GuardianAttack" or kind=="GuardianWarning" or kind=="Breach" or kind=="Hit" then ring(payload)
 end
end)

local animated={}
local function scanCreatures()
 local world=workspace:FindFirstChild("EggTycoonV3")
 if not world then return end
 local models={}
 local plots=world:FindFirstChild("Plots")
 if plots then
  for _,p in ipairs(plots:GetChildren()) do
   local folder=p:FindFirstChild("Creatures")
   if folder then for _,model in ipairs(folder:GetChildren()) do table.insert(models,model) end end
  end
 end
 local guardians=world:FindFirstChild("Guardians")
 if guardians then for _,model in ipairs(guardians:GetChildren()) do table.insert(models,model) end end
 local nextAnimated={}
 for _,model in ipairs(models) do
  if model:IsA("Model") and model.PrimaryPart then
   local entry=animated[model] or {Parts={},Phase=math.random()*6.28,Motion=0,PreviousPosition=model:GetPivot().Position}
   entry.CreatureId=model:GetAttribute("CreatureId")
   if not animated[model] then
    local pivot=model:GetPivot()
    for _,part in ipairs(model:GetDescendants()) do
     if part:IsA("BasePart") and part~=model.PrimaryPart then
      local name=string.lower(part.Name)
      local wing=name:find("wing",1,true)~=nil or name:find("flipper",1,true)~=nil
      local leg=name:find("leg",1,true)~=nil or name:find("foot",1,true)~=nil
      local arm=name:find("arm",1,true)~=nil
      local tail=name:find("tail",1,true)~=nil
      if wing or leg or arm or tail then
       local rest=part:GetAttribute("RestCF")
       if typeof(rest)~="CFrame" then rest=pivot:ToObjectSpace(part.CFrame) end
       local joint=part:GetAttribute('AnimationJoint')
       table.insert(entry.Parts,{Part=part,Local=rest,Joint=typeof(joint)=='CFrame' and joint or nil,MotionScale=part:GetAttribute('WingMotionScale') or 1,Wing=wing,Leg=leg,Arm=arm,Tail=tail,Side=rest.Position.X<0 and -1 or 1})
      end
     end
    end
   end
   nextAnimated[model]=entry
  end
 end
 animated=nextAnimated
 for id,at in pairs(productionPulses) do if os.clock()-at>2 then productionPulses[id]=nil end end
end
function hud:Update(dt)
 self.Timer+=dt
 if self.Timer<.15 then return end
 self.Timer=0
 local inside=self:InsidePlot()
 if self.Inside~=inside then
  self.Inside=inside
  navButtons[1].Visible=inside
  if not inside then
   if panelName=='Construir' then panel.Visible=false;panelName=nil end
   if build then cancelBuild() end
   selectedId=nil;selection.Visible=false;highlight.Adornee=nil
  end
 end
end

stateRemote.OnClientEvent:Connect(function(snapshot)
 if type(snapshot)~="table" then return end
 state=snapshot
 state.Builds=state.Builds or {} state.Creatures=state.Creatures or {} state.Inventory=state.Inventory or {} state.Pending=state.Pending or {}
 if state.NeedsClaim or not state.PlotId then
  cancelBuild();equipped=nil;crosshair.Visible=false;mobileAttack.Visible=false
  selectedId=nil;selection.Visible=false;highlight.Adornee=nil
 end
 if state.Carrying and build then cancelBuild() end
 lastCandidateKey=nil
 refreshHUD()
 -- Avoid destroying shop buttons on every energy tick.
 local signature=tostring(#state.Builds)..":"..tostring(#state.Creatures)..":"..tostring(state.BatteryLevel)..":"..tostring(state.WeaponLevel)..":"..tostring(state.SpeedLevel)..":"..tostring(state.ProcessorLevel)..":"..tostring(state.DefensesBuilt)..":"..tostring(state.NeedsClaim)
 for kind in pairs(C.Items) do signature..=kind..tostring(state.Inventory[kind] or 0) end
 if panelName=="Missoes" then
  local previous=collectionUI.Tab;collectionUI.Tab="Missões";signature=collectionUI:Signature();collectionUI.Tab=previous
 elseif panelName=="Criaturas" then
  if collectionUI.Tab=="Livro" then
   -- Model previews stay intact while energy, money, and unrelated missions tick.
   signature=collectionUI:Signature()
  elseif collectionUI.Tab=="Missões" then
   signature=collectionUI:Signature()
  end
 end
 if panel.Visible and signature~=lastPanelSignature then panelRefresh() end
 lastPanelSignature=signature
end)
toastRemote.OnClientEvent:Connect(toast)

local elapsed=0
local ghostElapsed=0
RunService.RenderStepped:Connect(function(dt)
 elapsed+=dt ghostElapsed+=dt
 hud:Update(dt)
 if hud.Guide then
  hud.Guide:Update(state,panel.Visible and panelName=='Missoes',dt)
  hud.Guide:Render(dt)
 end
 if ghostElapsed>.06 then ghostElapsed=0 updateGhost() end
 if elapsed>3 then elapsed=0 scanCreatures() responsive() collectionUI:LoadVisiblePreviews() end
 local now=os.clock()
 local camera=workspace.CurrentCamera
 for model,entry in pairs(animated) do
  if model.Parent and model.PrimaryPart and camera and (model.PrimaryPart.Position-camera.CFrame.Position).Magnitude<220 then
   local pivot=model:GetPivot()
   local moved=(pivot.Position-entry.PreviousPosition).Magnitude>.005
   entry.PreviousPosition=pivot.Position
   local walking=(model:GetAttribute("Chasing")==true or moved) and 1 or 0
   entry.Motion+=(walking-entry.Motion)*math.min(1,dt*10)
   local attacking=model:GetAttribute("Attacking")==true
   local producedAt=entry.CreatureId and productionPulses[entry.CreatureId]
   local age=producedAt and now-producedAt or 2
   local producing=age<.9 and math.sin(age/.9*math.pi) or 0
   local idle=math.sin(now*3+entry.Phase)
   local stride=math.sin(now*11+entry.Phase)*entry.Motion
   for _,limb in ipairs(entry.Parts) do
    if limb.Part.Parent then
     local pitch,yaw,roll=0,0,0
     local lift=0
     if limb.Wing then
      roll=limb.Side*(idle*.08+stride*.22+producing*.65+(attacking and .8 or 0))*limb.MotionScale
     elseif limb.Leg then
      pitch=stride*.45*limb.Side
      lift=math.max(0,stride*limb.Side)*.16
     elseif limb.Arm then
      pitch=-stride*.3*limb.Side+(attacking and -.85 or 0)+producing*.3
     elseif limb.Tail then
      yaw=idle*.08+stride*.15
      pitch=producing*.2+(attacking and .25 or 0)
     end
     local rotation=CFrame.Angles(pitch,yaw,roll)
     if limb.Joint then
      limb.Part.CFrame=pivot*CFrame.new(0,lift,0)*limb.Joint*rotation*limb.Joint:Inverse()*limb.Local
     else
      limb.Part.CFrame=pivot*CFrame.new(0,lift,0)*limb.Local*rotation
     end
    end
   end
  end
 end
end)
responsive()
send("GetState")
task.delay(2,function() send("GetState") scanCreatures() end)
