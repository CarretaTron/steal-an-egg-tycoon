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
local remotes=package:WaitForChild("Remotes")
local command=remotes:WaitForChild("Command")
local stateRemote=remotes:WaitForChild("State")
local toastRemote=remotes:WaitForChild("Toast")
local fxRemote=remotes:WaitForChild("FX")
local mouse=player:GetMouse()

local colors={Background=Color3.fromRGB(18,28,46),Panel=Color3.fromRGB(29,43,65),Card=Color3.fromRGB(39,56,81),
 Text=Color3.fromRGB(245,250,255),Muted=Color3.fromRGB(172,194,214),Green=Color3.fromRGB(95,233,163),
 Blue=Color3.fromRGB(95,196,255),Gold=Color3.fromRGB(255,211,87),Red=Color3.fromRGB(255,112,114),Purple=Color3.fromRGB(194,148,255)}
local state={Cash=0,Income=0,Builds={},Creatures={},Inventory={},Pending={},Energy=100,Rebirths=0}
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
 create("UICorner",{CornerRadius=UDim.new(0,radius or 12)},object)
end
local function stroke(object,color,thickness,transparency)
 return create("UIStroke",{Color=color or Color3.fromRGB(76,105,138),Thickness=thickness or 1,Transparency=transparency or .25},object)
end
local function frame(parent,props)
 props=props or {}
 props.BorderSizePixel=0
 props.BackgroundColor3=props.BackgroundColor3 or colors.Panel
 local result=create("Frame",props,parent)
 round(result,props.Name=="Shade" and 0 or 12)
 return result
end
local function label(parent,text,props)
 props=props or {}
 props.Text=text
 props.BackgroundTransparency=1
 props.BorderSizePixel=0
 props.Font=props.Font or Enum.Font.GothamMedium
 props.TextColor3=props.TextColor3 or colors.Text
 props.TextSize=props.TextSize or 14
 props.TextXAlignment=props.TextXAlignment or Enum.TextXAlignment.Left
 props.TextYAlignment=props.TextYAlignment or Enum.TextYAlignment.Center
 return create("TextLabel",props,parent)
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
 props.Font=Enum.Font.GothamBold
 props.TextColor3=props.TextColor3 or colors.Text
 props.TextSize=props.TextSize or 13
 local result=create("TextButton",props,parent)
 round(result,9)
 result.Activated:Connect(function() if callback then callback() end end)
 return result
end
local function send(action,payload)
 command:FireServer(action,payload or {})
end
local function money(n)
 n=tonumber(n) or 0
 if n>=1e12 then return string.format("$%.2fT",n/1e12) end
 if n>=1e9 then return string.format("$%.2fB",n/1e9) end
 if n>=1e6 then return string.format("$%.2fM",n/1e6) end
 if n>=10000 then return string.format("$%.1f mil",n/1000) end
 local formatted=tostring(math.floor(n))
 repeat local replaced,count=formatted:gsub("^(%-?%d+)(%d%d%d)","%1.%2") formatted=replaced until count==0
 return "$"..formatted
end
local function sizeButton(btn,enabled)
 btn.AutoButtonColor=enabled
 btn.BackgroundTransparency=enabled and 0 or .55
 btn.TextTransparency=enabled and 0 or .3
end

local cashBox=frame(gui,{Name="Economia",Position=UDim2.fromOffset(18,16),Size=UDim2.fromOffset(254,91)})
stroke(cashBox,colors.Green,2,.3)
local cashCaption=label(cashBox,"STEAL AN EGG  /  TYCOON",{Position=UDim2.fromOffset(14,8),Size=UDim2.new(1,-28,0,15),TextSize=10,TextColor3=colors.Muted,Font=Enum.Font.GothamBold})
local cashText=label(cashBox,"$0",{Position=UDim2.fromOffset(14,24),Size=UDim2.new(1,-28,0,35),TextSize=30,TextColor3=colors.Green,Font=Enum.Font.GothamBlack})
local incomeText=label(cashBox,"$0 /s  •  Rebirth 0",{Position=UDim2.fromOffset(15,64),Size=UDim2.new(1,-28,0,18),TextSize=12})

local securityBox=frame(gui,{Name="Seguranca",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-18,0,16),Size=UDim2.fromOffset(244,91)})
stroke(securityBox,colors.Blue,1,.5)
local shieldText=label(securityBox,"BATERIA  200 / 200",{Position=UDim2.fromOffset(12,9),Size=UDim2.new(1,-24,0,18),TextSize=12,Font=Enum.Font.GothamBold})
local shieldTrack=frame(securityBox,{Position=UDim2.fromOffset(12,33),Size=UDim2.new(1,-24,0,7),BackgroundColor3=colors.Background})
local shieldFill=frame(shieldTrack,{Size=UDim2.fromScale(1,1),BackgroundColor3=colors.Blue})
local energyText=label(securityBox,"ENERGIA  100%",{Position=UDim2.fromOffset(12,47),Size=UDim2.new(1,-24,0,17),TextSize=10,TextColor3=colors.Muted})
local energyTrack=frame(securityBox,{Position=UDim2.fromOffset(12,73),Size=UDim2.new(1,-24,0,5),BackgroundColor3=colors.Background})
local energyFill=frame(energyTrack,{Size=UDim2.fromScale(1,1),BackgroundColor3=colors.Gold})

local objective=frame(gui,{Name="Objetivo",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,16),Size=UDim2.fromOffset(410,74)})
stroke(objective,colors.Gold,1,.55)
local objectiveHeading=label(objective,"SUA PRIMEIRA EXPEDIÇÃO",{Position=UDim2.fromOffset(14,8),Size=UDim2.new(1,-28,0,16),TextSize=10,TextColor3=colors.Gold,Font=Enum.Font.GothamBold})
local objectiveText=label(objective,"Vá ao Campo e roube um ovo do ninho.",{Position=UDim2.fromOffset(14,26),Size=UDim2.new(1,-28,0,38),TextSize=13,TextWrapped=true})
local saveLabel=label(gui,"Conectando ao tycoon...",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,18,1,-7),Size=UDim2.new(1,-36,0,16),TextSize=9,TextColor3=colors.Muted})

local nav=frame(gui,{Name="Navegacao",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-28),Size=UDim2.fromOffset(448,58)})
stroke(nav,nil,1,.6)
local navButtons={}
local panelName=nil
local panel=frame(gui,{Name="Painel",Position=UDim2.fromOffset(18,126),Size=UDim2.fromOffset(354,470),Visible=false})
stroke(panel,colors.Blue,1,.4)
local panelTitle=label(panel,"CONSTRUIR",{Position=UDim2.fromOffset(16,12),Size=UDim2.new(1,-65,0,23),Font=Enum.Font.GothamBlack,TextSize=18})
local closePanel=button(panel,"×",colors.Card,function() panel.Visible=false panelName=nil end,{Name="Panel_Close",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,10),Size=UDim2.fromOffset(30,30),TextSize=22})
local tabs=frame(panel,{Position=UDim2.fromOffset(12,48),Size=UDim2.new(1,-24,0,32),BackgroundTransparency=1})
local scroll=create("ScrollingFrame",{Name="Lista",Position=UDim2.fromOffset(12,89),Size=UDim2.new(1,-24,1,-101),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=colors.Blue,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},panel)
create("UIListLayout",{Padding=UDim.new(0,9),SortOrder=Enum.SortOrder.LayoutOrder},scroll)
create("UIPadding",{PaddingBottom=UDim.new(0,12),PaddingRight=UDim.new(0,5)},scroll)
local shopTab="Máquinas"
local collectionUI={Tab="Habitats",Previews={},Generation=0}
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
 if type(message)=="table" then message=message.Message or message.Text or "Atualizado" end
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
local guidePart=nil
local highlight=Instance.new("Highlight")
highlight.FillTransparency=.88
highlight.OutlineColor=colors.Blue
highlight.DepthMode=Enum.HighlightDepthMode.Occluded
highlight.Parent=gui

local buildBar=frame(gui,{Name="Construcao",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-102),Size=UDim2.fromOffset(540,100),Visible=false})
stroke(buildBar,colors.Blue,2,.3)
local buildTitle=label(buildBar,"CONSTRUIR",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,20),TextSize=13,Font=Enum.Font.GothamBold})
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
local placeButton=button(buildBar,"COLOCAR",colors.Green,placeCurrent,{Position=UDim2.fromOffset(12,59),Size=UDim2.fromOffset(164,30),TextColor3=colors.Background})
local rotateBuild=button(buildBar,"GIRAR  [R]",colors.Card,function() if build then build.R=(build.R+1)%4 lastCandidateKey=nil end end,{Position=UDim2.fromOffset(184,59),Size=UDim2.fromOffset(164,30)})
local cancelButton=button(buildBar,"CANCELAR",colors.Card,function() cancelBuild() end,{Position=UDim2.fromOffset(356,59),Size=UDim2.fromOffset(172,30)})

local selection=frame(gui,{Name="Selecao",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-102),Size=UDim2.fromOffset(542,92),Visible=false})
stroke(selection,colors.Blue,1,.4)
local selectionTitle=label(selection,"HABITAT",{Position=UDim2.fromOffset(12,9),Size=UDim2.new(1,-24,0,23),TextSize=14,Font=Enum.Font.GothamBold})
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
 create("UISizeConstraint",{MaxSize=Vector2.new(350,210)},box)
 stroke(box,colors.Gold,2,.3)
 label(box,title,{Position=UDim2.fromOffset(18,17),Size=UDim2.new(1,-36,0,27),TextSize=18,Font=Enum.Font.GothamBold,ZIndex=32})
 label(box,message,{Position=UDim2.fromOffset(18,50),Size=UDim2.new(1,-36,0,88),TextSize=13,TextWrapped=true,ZIndex=32})
 button(box,"CANCELAR",colors.Card,function() modal:Destroy() modal=nil end,{Position=UDim2.fromOffset(18,157),Size=UDim2.new(.5,-27,0,35),ZIndex=32})
 button(box,"CONFIRMAR",colors.Gold,function() modal:Destroy() modal=nil action() end,{Position=UDim2.new(.5,9,0,157),Size=UDim2.new(.5,-27,0,35),TextColor3=colors.Background,ZIndex=32})
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
end,{Name="Upgrade_Habitat",Position=UDim2.fromOffset(12,89),Size=UDim2.new(1,-24,0,33),TextSize=11,TextColor3=colors.Background,Visible=false})

local carryBox=frame(gui,{Name="Transporte",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-101),Size=UDim2.fromOffset(460,52),Visible=false})
stroke(carryBox,colors.Gold,2,.35)
local carryText=label(carryBox,"OVO",{Position=UDim2.fromOffset(13,7),Size=UDim2.new(1,-116,1,-14),TextWrapped=true,TextSize=12,Font=Enum.Font.GothamBold})
button(carryBox,"SOLTAR [G]",colors.Card,function() send("Drop") end,{AnchorPoint=Vector2.new(1,.5),Position=UDim2.new(1,-9,.5,0),Size=UDim2.fromOffset(100,32),TextSize=10})

cancelBuild=function()
 build=nil buildBar.Visible=false
 if ghostPart then ghostPart:Destroy() ghostPart=nil end
 if ghostArrow then ghostArrow:Destroy() ghostArrow=nil end
 lastCandidateKey=nil
end
beginBuild=function(kind,existing)
 if state.Carrying then toast("Entregue ou solte o que está carregando para construir.") return end
 if (state.LastCombatRemaining or 0)>0 then toast("Sua base está sob ataque. Aguarde para editar.") return end
 if not existing and (state.Inventory[kind] or 0)<1 then toast("Compre uma unidade antes de construir.") return end
 cancelBuild()
 build={Kind=kind,R=existing and existing.R or 0,Id=existing and existing.Id or nil}
 selection.Visible=false selectedId=nil highlight.Adornee=nil
 buildBar.Visible=true
 if UserInputService.TouchEnabled then panel.Visible=false end
 ghostPart=create("Part",{Name="LocalBuildPreview",Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Material=Enum.Material.Neon,Transparency=.55,Size=Vector3.new(C.Items[kind].W,.6,C.Items[kind].D),Color=colors.Green},workspace)
 ghostArrow=create("Part",{Name="LocalDirection",Anchored=true,CanCollide=false,CanQuery=false,CanTouch=false,Material=Enum.Material.Neon,Transparency=.15,Size=Vector3.new(1.2,.3,3),Color=colors.Text},workspace)
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
 return frame(scroll,{Name=name or "Card_"..tostring(#scroll:GetChildren()),Size=UDim2.new(1,0,0,height or 105),BackgroundColor3=colors.Card})
end
local function itemCard(kind)
 local item=C.Items[kind]
 local box=card(UserInputService.TouchEnabled and 120 or 106,"Item_"..kind)
 frame(box,{Position=UDim2.fromOffset(10,12),Size=UDim2.fromOffset(5,32),BackgroundColor3=item.Color})
 label(box,item.Name,{Position=UDim2.fromOffset(24,10),Size=UDim2.new(1,-33,0,22),TextSize=14,Font=Enum.Font.GothamBold})
 local amount=state.Inventory[kind] or 0
 label(box,string.format("%d guardado(s)  •  %d × %d studs",amount,item.W,item.D),{Position=UDim2.fromOffset(24,35),Size=UDim2.new(1,-33,0,18),TextSize=10,TextColor3=colors.Muted})
 local buy=button(box,"COMPRAR  "..money(item.Price),colors.Card,function() send("BuyItem",{Kind=kind,Count=1}) end,{Name="Buy_"..kind,Position=UDim2.fromOffset(10,66),Size=UDim2.new(.55,-15,0,30),TextSize=11})
 stroke(buy,item.Color,1,.5)
 local place=button(box,"COLOCAR  ("..amount..")",amount>0 and item.Color or colors.Panel,function() beginBuild(kind) end,{Name="Place_"..kind,Position=UDim2.new(.55,0,0,66),Size=UDim2.new(.45,-10,0,30),TextSize=11,TextColor3=amount>0 and colors.Background or colors.Muted})
 sizeButton(place,amount>0)
end
local function upgradeCard(kind,title,description,level,maxLevel,price,color)
 local box=card(UserInputService.TouchEnabled and 141 or 127,"Upgrade_"..kind)
 label(box,title.."  •  "..level.."/"..maxLevel,{Position=UDim2.fromOffset(12,10),Size=UDim2.new(1,-24,0,23),TextSize=14,Font=Enum.Font.GothamBold,TextColor3=color})
 label(box,description,{Position=UDim2.fromOffset(12,36),Size=UDim2.new(1,-24,0,36),TextSize=11,TextWrapped=true,TextColor3=colors.Muted})
 local buy=button(box,level>=maxLevel and "NÍVEL MÁXIMO" or "MELHORAR  "..money(price),color,function() if level<maxLevel then send("Upgrade",{Kind=kind}) end end,{Position=UDim2.fromOffset(12,84),Size=UDim2.new(1,-24,0,31),TextColor3=colors.Background})
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
  piece.Color=Color3.new(table.unpack(definition.Color))
  piece.Material=definition.Glow and Enum.Material.Neon or Enum.Material.SmoothPlastic
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
 local summary=card(74,"Book_Summary")
 label(summary,"LIVRO DE DESCOBERTAS  "..found.." / "..#C.Species,{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,25),TextSize=13,Font=Enum.Font.GothamBold,TextColor3=found==#C.Species and colors.Gold or colors.Green})
 label(summary,"Incube ovos para revelar as espécies. Suas descobertas permanecem após renascer.",{Position=UDim2.fromOffset(12,34),Size=UDim2.new(1,-24,0,31),TextSize=10,TextWrapped=true,TextColor3=colors.Muted})
 for index,species in ipairs(C.Species) do
  local discovered=self:Discovered(index)
  local box=card(discovered and 218 or 158,"Book_Species_"..index)
  box:SetAttribute("Discovered",discovered)
  stroke(box,discovered and species.Color or colors.Muted,1,discovered and .35 or .8)
  label(box,discovered and species.Name or "CRIATURA DESCONHECIDA",{Position=UDim2.fromOffset(12,9),Size=UDim2.new(1,-24,0,23),TextSize=14,Font=Enum.Font.GothamBold,TextColor3=discovered and species.Color or colors.Muted})
  label(box,discovered and "DESCOBERTA  •  "..species.Biome or "AINDA NÃO DESCOBERTA  •  "..species.Biome,{Position=UDim2.fromOffset(12,33),Size=UDim2.new(1,-24,0,16),TextSize=9,Font=Enum.Font.GothamBold,TextColor3=discovered and colors.Green or colors.Muted})
  if discovered then
   local viewport=create("ViewportFrame",{Name="CreaturePreview",Position=UDim2.fromOffset(12,58),Size=UDim2.fromOffset(104,126),BackgroundColor3=colors.Background,BorderSizePixel=0,
    Ambient=Color3.fromRGB(180,190,210),LightColor=Color3.fromRGB(255,247,226),LightDirection=Vector3.new(-1,-1,-1)},box)
   round(viewport,10)
   local hint=label(viewport,"Preparando prévia...",{Size=UDim2.fromScale(1,1),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Center,TextSize=10,TextColor3=colors.Muted})
   table.insert(self.Previews,{Viewport=viewport,Hint=hint,Species=index})
   label(box,"Recurso: "..species.Resource.."\nIncubação: "..species.Hatch.." segundos\nRenda básica: "..money(species.Rate).." /s\nGuardião: "..species.Speed.." velocidade\nDano do guardião: "..species.Damage,{Position=UDim2.fromOffset(128,58),Size=UDim2.new(1,-140,0,126),TextWrapped=true,TextSize=10,TextYAlignment=Enum.TextYAlignment.Top})
   label(box,"Produz a cada 4s  •  "..money(species.Rate*4).." por recurso processado",{Position=UDim2.fromOffset(12,190),Size=UDim2.new(1,-24,0,18),TextSize=9,TextColor3=colors.Muted})
  else
   local unknown=frame(box,{Position=UDim2.fromOffset(12,58),Size=UDim2.fromOffset(84,86),BackgroundColor3=colors.Background})
   label(unknown,"?",{Size=UDim2.fromScale(1,1),TextSize=42,TextColor3=colors.Muted,TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.GothamBlack})
   label(box,"Incube um ovo deste bioma para revelar a criatura, seu recurso e seus atributos.",{Position=UDim2.fromOffset(108,59),Size=UDim2.new(1,-120,0,83),TextWrapped=true,TextSize=11,TextColor3=colors.Muted})
  end
 end
end
function collectionUI:Missions()
 local ready=self:ReadyMissions()
 local summary=card(72,"Missions_Summary")
 label(summary,ready>0 and ready.." RECOMPENSA(S) DISPONÍVEL(IS)" or "SUA PRÓXIMA CONQUISTA",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,23),TextSize=12,Font=Enum.Font.GothamBold,TextColor3=ready>0 and colors.Gold or colors.Blue})
 label(summary,"Complete objetivos e receba peças para expandir sua base. Progresso e recompensas permanecem registrados.",{Position=UDim2.fromOffset(12,33),Size=UDim2.new(1,-24,0,31),TextSize=10,TextWrapped=true,TextColor3=colors.Muted})
 for _,definition in ipairs(C.Missions or {}) do
  local mission=self:MissionState(definition.Id) or {Current=0,Target=definition.Target,Complete=false,Claimed=false}
  local target=math.max(1,tonumber(mission.Target) or definition.Target or 1)
  local current=math.clamp(tonumber(mission.Current) or 0,0,target)
  local claimed,complete=mission.Claimed==true,mission.Complete==true
  local tint=claimed and colors.Green or complete and colors.Gold or colors.Blue
  local box=card(UserInputService.TouchEnabled and 216 or 202,"Mission_"..definition.Id)
  box:SetAttribute("Complete",complete);box:SetAttribute("Claimed",claimed)
  stroke(box,tint,1,.55)
  label(box,definition.Name,{Position=UDim2.fromOffset(12,9),Size=UDim2.new(1,-24,0,23),TextSize=14,Font=Enum.Font.GothamBold,TextColor3=tint})
  label(box,definition.Description,{Position=UDim2.fromOffset(12,36),Size=UDim2.new(1,-24,0,34),TextSize=11,TextWrapped=true,TextColor3=colors.Muted})
  label(box,(claimed and "RECEBIDA" or complete and "CONCLUÍDA" or "EM ANDAMENTO").."   "..current.." / "..target,{Position=UDim2.fromOffset(12,75),Size=UDim2.new(1,-24,0,18),TextSize=10,TextColor3=tint,Font=Enum.Font.GothamBold})
  local track=frame(box,{Position=UDim2.fromOffset(12,97),Size=UDim2.new(1,-24,0,6),BackgroundColor3=colors.Background})
  frame(track,{Size=UDim2.fromScale(current/target,1),BackgroundColor3=tint})
  local rewards={}
  for kind,amount in pairs(definition.Rewards or {}) do table.insert(rewards,tostring(amount).." × "..(C.Items[kind] and C.Items[kind].Name or kind)) end
  table.sort(rewards)
  label(box,"Recompensa: "..table.concat(rewards,"  •  "),{Position=UDim2.fromOffset(12,113),Size=UDim2.new(1,-24,0,32),TextSize=10,TextWrapped=true,TextColor3=colors.Text})
  local claim=button(box,claimed and "RECOMPENSA RECEBIDA" or complete and "RECEBER RECOMPENSA" or "COMPLETE O OBJETIVO",complete and not claimed and colors.Gold or colors.Panel,function()
   if complete and not claimed then send("ClaimMission",{Id=definition.Id}) end
  end,{Name="Claim_"..definition.Id,Position=UDim2.fromOffset(12,156),Size=UDim2.new(1,-24,0,32),TextSize=11,TextColor3=complete and not claimed and colors.Background or colors.Muted})
  sizeButton(claim,complete and not claimed)
 end
end
scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function() collectionUI:LoadVisiblePreviews() end)
panelRefresh=function()
 if not panelName then return end
 clearList()
 for _,child in ipairs(tabs:GetChildren()) do child:Destroy() end
 if panelName=="Construir" then
  panelTitle.Text="OFICINA DO TYCOON"
  for index,name in ipairs({"Máquinas","Esteiras"}) do
   button(tabs,name,shopTab==name and colors.Blue or colors.Card,function() shopTab=name panelRefresh() end,{Name=index==1 and "Tab_Machines" or "Tab_Belts",Position=UDim2.new((index-1)*.5,0,0,0),Size=UDim2.new(.5,-4,1,0),TextColor3=shopTab==name and colors.Background or colors.Text})
  end
  for _,kind in ipairs(shopTab=="Máquinas" and {"Habitat","Incubator","Processor","Seller"} or {"Belt","Curve","Merge"}) do itemCard(kind) end
  local hint=card(78)
  label(hint,"SAÍDA → ESTEIRAS → PROCESSADOR → VENDEDOR\nToque numa máquina da sua base para movê-la, girá-la ou guardá-la.",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),TextSize=10,TextWrapped=true,TextColor3=colors.Muted})
 elseif panelName=="Melhorias" then
  panelTitle.Text="MELHORIAS"
  label(tabs,"Expanda, produza mais e defenda sua base.",{Size=UDim2.fromScale(1,1),TextSize=11,TextColor3=colors.Muted})
  local battery=state.BatteryLevel or 1
  local weapon=state.WeaponLevel or 0
  local speed=state.SpeedLevel or 0
  local processor=state.ProcessorLevel or 1
  upgradeCard("Battery","Bateria","Mais resistência ao ataque. Se houver invasão, a melhoria entra na próxima reconstrução.",battery,4,C.BatteryPrices[battery] or 0,colors.Blue)
  upgradeCard("Weapon","Armas",weapon==0 and "Desbloqueia o blaster de energia recarregável." or "Desbloqueia o blaster melhorado. Sem custo de munição.",weapon,2,C.WeaponPrices[weapon+1] or 0,colors.Red)
  local speedPrice=C.SpeedPrices and C.SpeedPrices[speed+1] or 500*(speed+1)^2
  local processorPrice=C.ProcessorPrices and C.ProcessorPrices[processor] or 2000*processor^2
  upgradeCard("Speed","Velocidade","Corra mais para escapar dos guardiões e alcançar sua base.",speed,5,speedPrice,colors.Green)
  upgradeCard("Processor","Processamento","Aumenta o valor dos recursos que percorrem um circuito completo.",processor,3,processorPrice,colors.Gold)
 elseif panelName=="Criaturas" then
  panelTitle.Text="CRIATURAS E MISSÕES"
  for index,tab in ipairs({{"Habitats","Tab_Habitats"},{"Livro","Tab_Book"},{"Missões","Tab_Missions"}}) do
   local name=tab[1]
   button(tabs,name,collectionUI.Tab==name and colors.Green or colors.Card,function() collectionUI.Tab=name;scroll.CanvasPosition=Vector2.zero;panelRefresh() end,{Name=tab[2],Position=UDim2.new((index-1)/3,0,0,0),Size=UDim2.new(1/3,-4,1,0),TextSize=10,TextColor3=collectionUI.Tab==name and colors.Background or colors.Text})
  end
  if collectionUI.Tab=="Livro" then collectionUI:Book()
  elseif collectionUI.Tab=="Missões" then collectionUI:Missions()
  else
  local occupancy=card(48,"Habitats_Summary")
  label(occupancy,tostring(#(state.Creatures or {})).." / "..C.MaxHabitats.." HABITATS OCUPADOS",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),TextSize=12,TextColor3=colors.Green,Font=Enum.Font.GothamBold})
  if #(state.Creatures or {})==0 then
   local empty=card(115)
   label(empty,"Seu primeiro companheiro está esperando!\nRoube um ovo no Campo e leve à incubadora.",{Position=UDim2.fromOffset(16,12),Size=UDim2.new(1,-32,1,-24),TextWrapped=true,TextSize=13})
  end
  for _,creature in ipairs(state.Creatures or {}) do
   local species=C.Species[creature.Species]
   local box=card(UserInputService.TouchEnabled and 120 or 106,"Creature_"..creature.Id)
   label(box,species.Name,{Position=UDim2.fromOffset(12,10),Size=UDim2.new(1,-24,0,22),TextSize=15,Font=Enum.Font.GothamBold,TextColor3=species.Color})
   label(box,species.Resource.."  •  estoque "..tostring(creature.Stored or 0).."/20",{Position=UDim2.fromOffset(12,37),Size=UDim2.new(1,-24,0,17),TextSize=10,TextColor3=colors.Muted})
   button(box,"SELECIONAR HABITAT",colors.Card,function()
    selectedId=creature.HabitatId
    selection.Visible=true
    panel.Visible=false panelName=nil
   end,{Position=UDim2.fromOffset(12,65),Size=UDim2.new(1,-24,0,30),TextSize=11})
  end
  local collection=card(52)
  local found=collectionUI:Count()
  label(collection,"COLEÇÃO DESCOBERTA   "..found.." / 7",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,1,-16),TextSize=12,TextColor3=colors.Gold,Font=Enum.Font.GothamBold})
  end
 elseif panelName=="Rebirth" then
  panelTitle.Text="RENASCER"
  label(tabs,"Recomece com produção permanente maior.",{Size=UDim2.fromScale(1,1),TextSize=11,TextColor3=colors.Muted})
  local box=card(UserInputService.TouchEnabled and 249 or 235,"Rebirth_Details")
  local count=state.Rebirths or 0
  local cost=C.RebirthCost*3^count
  label(box,"+25% DE PRODUÇÃO",{Position=UDim2.fromOffset(14,15),Size=UDim2.new(1,-28,0,31),TextSize=20,Font=Enum.Font.GothamBlack,TextColor3=colors.Purple})
  label(box,"Bônus atual: +"..math.floor(count*C.RebirthMultiplier*100).."%\nPróximo bônus: +"..math.floor((count+1)*C.RebirthMultiplier*100).."%\n\nDinheiro, criaturas e compras recomeçam. Sua coleção e seu bônus permanecem. Você recebe o kit inicial novamente.",{Position=UDim2.fromOffset(14,54),Size=UDim2.new(1,-28,0,119),TextSize=12,TextWrapped=true,TextColor3=colors.Muted})
  button(box,"RENASCER  "..money(cost),colors.Purple,function()
   if (state.Cash or 0)<cost then toast("Você precisa de "..money(cost).." para renascer.") return end
   confirm("Renascimento", "Você recomeçará com o kit inicial e ganhará +25% de produção permanente. Sua coleção será mantida.",function() send("Rebirth") end)
  end,{Position=UDim2.fromOffset(14,188),Size=UDim2.new(1,-28,0,34),TextColor3=colors.Background})
 end
 if panelName=="Criaturas" and collectionUI.Tab~="Habitats" then lastPanelSignature=collectionUI:Signature() end
 task.defer(function() collectionUI:LoadVisiblePreviews() end)
end

for index,entry in ipairs({{"Construir",colors.Blue},{"Melhorias",colors.Gold},{"Criaturas",colors.Green},{"Rebirth",colors.Purple}}) do
 local name,color=entry[1],entry[2]
 local b=button(nav,string.upper(name),colors.Card,function()
  if panelName==name and panel.Visible then panel.Visible=false panelName=nil return end
  panelName=name panel.Visible=true panelRefresh()
 end,{Name="Nav_"..name,Position=UDim2.new((index-1)*.25,7,0,8),Size=UDim2.new(.25,-10,1,-16),TextSize=11,TextColor3=color})
 navButtons[index]=b
end

local function plot()
 local world=workspace:FindFirstChild("EggTycoonV3")
 local plots=world and world:FindFirstChild("Plots")
 return plots and state.PlotId and plots:FindFirstChild(string.format("Plot_%02d",state.PlotId))
end
local function plotFrame()
 return state.PlotCFrame or (state.PlotId and C.PlotCFrame(state.PlotId))
end
local function refreshSelection()
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
 cashText.Text=money(state.Cash)
 incomeText.Text=money(state.Income).." /s  •  Rebirth "..tostring(state.Rebirths or 0)
 if navButtons[3] then
  local ready=collectionUI:ReadyMissions()
  navButtons[3].Text=ready>0 and "CRIATURAS ("..ready..")" or "CRIATURAS"
  navButtons[3].TextColor3=ready>0 and colors.Gold or colors.Green
 end
 local health=state.BatteryHP or C.BatteryHP[state.BatteryLevel or 1]
 local maximum=state.BatteryMax or C.BatteryHP[state.BatteryLevel or 1]
 local breach=state.BreachRemaining or 0
 shieldText.Text=breach>0 and "LASER DESLIGADO  •  "..math.ceil(breach).."s" or "BATERIA  "..math.floor(health).." / "..maximum
 shieldText.TextColor3=breach>0 and colors.Red or colors.Text
 shieldFill.Size=UDim2.fromScale(math.clamp(health/math.max(1,maximum),0,1),1)
 shieldFill.BackgroundColor3=breach>0 and colors.Red or colors.Blue
 energyText.Text="ENERGIA  "..math.floor(state.Energy or 100).."%"..((state.LastCombatRemaining or 0)>0 and "  •  EM COMBATE" or "")
 energyFill.Size=UDim2.fromScale(math.clamp((state.Energy or 100)/100,0,1),1)
 carryBox.Visible=state.Carrying==true and not build
 carryText.Text=tostring(state.Carry or "Transportando").."\nArmas indisponíveis • velocidade −10%"
 local saveMode=tostring(state.SaveMode or "Conectando")
 saveLabel.Text=saveMode:find("Sessão") and "MODO DE TESTE: apenas esta sessão • APIs do Studio desativadas" or "Progresso: "..saveMode.."  •  B construir / R girar / G soltar"
 saveLabel.TextColor3=saveMode:find("Sessão") and colors.Gold or colors.Muted
 local hasPending=next(state.Pending or {})~=nil
 if state.Carrying then
  objectiveHeading.Text="VOLTE À SUA BASE"
  objectiveText.Text=string.find(string.lower(tostring(state.Carry)),"ovo",1,true) and "Leve o ovo à incubadora. Um habitat livre será reservado." or "Entregue a criatura no habitat reservado da sua base."
 elseif hasPending then
  local remaining=0
  for _,pending in pairs(state.Pending) do remaining=math.max(remaining,pending.Remaining or 0) end
  objectiveHeading.Text="SEU OVO ESTÁ CHOCANDO"
  objectiveText.Text=remaining>0 and "Mais "..math.ceil(remaining).."s! Confira o caminho das esteiras até o vendedor." or "Prepare a produção: habitat → processador → vendedor."
 elseif #(state.Creatures or {})>0 then
  objectiveHeading.Text=(state.Income or 0)>0 and "SEU TYCOON ESTÁ PRODUZINDO" or "CONECTE A PRODUÇÃO"
  objectiveText.Text=(state.Income or 0)>0 and "Explore biomas mais perigosos, melhore a base e proteja suas criaturas." or "Conecte habitat → esteiras → processador → vendedor. O estoque para em 20."
 else
  objectiveHeading.Text="SUA PRIMEIRA EXPEDIÇÃO"
  objectiveText.Text="Siga o corredor até o Campo. Roube um ovo e fuja do guardião!"
 end
 refreshSelection()
end

local function responsive()
 local camera=workspace.CurrentCamera
 if not camera then return end
 local viewport=camera.ViewportSize
 local insetTop,insetBottom=GuiService:GetGuiInset()
 local usableHeight=math.max(180,viewport.Y-insetTop.Y-insetBottom.Y)
 local touch=UserInputService.TouchEnabled
 local short=touch and usableHeight<520
 local compact=viewport.X<1080
 local narrow=viewport.X<600
 local narrowWidth=math.min(175,math.floor((viewport.X-48)/2))
 cashBox.Size=UDim2.fromOffset(narrow and narrowWidth or 254,91)
 cashCaption.TextSize=narrow and 8 or 10
 cashText.TextSize=narrow and 25 or 30
 securityBox.Size=UDim2.fromOffset(narrow and narrowWidth or 244,91)
 shieldText.TextSize=narrow and 10 or 12
 shieldText.TextTruncate=Enum.TextTruncate.AtEnd
 energyText.TextTruncate=Enum.TextTruncate.AtEnd
 incomeText.TextSize=narrow and 10 or 12
 objective.Position=compact and UDim2.new(.5,0,0,117) or UDim2.new(.5,0,0,16)
 objective.Size=UDim2.fromOffset(math.min(410,viewport.X-36),compact and 59 or 74)
 objectiveText.Position=UDim2.fromOffset(14,compact and 20 or 26)
 objectiveText.Size=UDim2.new(1,-28,0,compact and 32 or 38)
 objectiveText.TextSize=compact and 11 or 13
 local panelY=short and 8 or (compact and 113 or 126)
 panel.Position=UDim2.fromOffset(18,panelY)
 panel.Size=UDim2.fromOffset(math.min(354,viewport.X-36),math.max(160,math.min(480,usableHeight-panelY-104)))
 panelTitle.Visible=not short
 closePanel.Position=UDim2.new(1,-10,0,short and 8 or 10)
 closePanel.Size=UDim2.fromOffset(touch and 44 or 30,touch and 44 or 30)
 local tabsY=short and 8 or (touch and 54 or 48)
 local tabsHeight=touch and 44 or 32
 tabs.Position=UDim2.fromOffset(12,tabsY)
 tabs.Size=UDim2.new(1,short and -76 or -24,0,tabsHeight)
 local listY=tabsY+tabsHeight+10
 scroll.Position=UDim2.fromOffset(12,listY)
 scroll.Size=UDim2.new(1,-24,1,-listY-12)
 nav.Size=UDim2.fromOffset(math.min(448,viewport.X-28),touch and 62 or 58)
 for _,b in ipairs(navButtons) do b.TextSize=narrow and 9 or 11 end
 local toastY=math.min(short and 117 or (compact and 188 or 121),math.max(8,usableHeight-168))
 local toastHeight=short and 64 or math.max(64,math.min(250,usableHeight-toastY-104))
 toasts.Position=UDim2.new(1,-18,0,toastY)
 toasts.Size=UDim2.fromOffset(math.min(320,viewport.X-36),toastHeight)
 fitToasts()
 local width=math.min(540,viewport.X-24)
 buildBar.Size=UDim2.fromOffset(width,touch and 114 or 100)
 selection.Size=UDim2.fromOffset(width,habitatUpgrade.Visible and (touch and 147 or 136) or (touch and 103 or 92))
 habitatUpgrade.Size=UDim2.new(1,-24,0,touch and 44 or 33)
 for index,b in ipairs({placeButton,rotateBuild,cancelButton}) do b.Position=UDim2.new((index-1)/3,8,0,59) b.Size=UDim2.new(1/3,-12,0,touch and 44 or 30) b.TextSize=narrow and 10 or 12 end
 for index,b in ipairs({moveButton,rotateSelection,storeButton,releaseButton}) do b.Position=UDim2.new((index-1)/5,8,0,45) b.Size=UDim2.new(1/5,-10,0,touch and 44 or 33) b.TextSize=narrow and 9 or 12 end
 for _,b in ipairs(selection:GetChildren()) do if b:IsA("TextButton") and b.Text=="×" then b.Position=UDim2.new(.8,8,0,45) b.Size=UDim2.new(.2,-18,0,touch and 44 or 33) end end
 carryBox.Size=UDim2.fromOffset(math.min(460,viewport.X-24),touch and 62 or 52)
end

local function panelVisibility()
 local touch=UserInputService.TouchEnabled
 cashBox.Visible=not (touch and panel.Visible)
 securityBox.Visible=not (touch and panel.Visible)
 objective.Visible=not ((touch and (panel.Visible or buildBar.Visible or selection.Visible or carryBox.Visible)) or (shortTouchLayout() and toasts.Visible))
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
 if not build or not ghostPart then return end
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
  local valid,reason=Rules.Validate(state.Builds or {},candidate,build.Id)
  if not build.Id and (state.Inventory[build.Kind] or 0)<1 then valid=false reason="Sem unidades guardadas. Compre mais na oficina." end
  if (state.LastCombatRemaining or 0)>0 then valid=false reason="Edição bloqueada durante combate." end
  build.Valid=valid build.Reason=reason build.Candidate=candidate lastCandidateKey=key
  ghostPart.Color=valid and colors.Green or colors.Red
  buildHint.Text=valid and ("Posição válida  •  "..x..", "..z.."  •  saída indicada em branco") or tostring(reason or "Posição inválida")
  buildHint.TextColor3=valid and colors.Green or colors.Red
  sizeButton(placeButton,valid)
 end
 local itemCF=C.ItemCFrame(cf,candidate)
 ghostPart.CFrame=itemCF*CFrame.new(0,.45,0)
 ghostArrow.CFrame=itemCF*CFrame.new(0,1,-C.Items[build.Kind].D/2-1.5)
end

local function selectAt(screen)
 if modal then return end
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
 local own=plot()
 if own then
  for _,part in ipairs(own:GetChildren()) do
   if part.Name=="Roof" or part.Name=="RoofFrame" or part.Name=="Perimeter" then table.insert(excluded,part) end
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
 if not equipped or state.Carrying or build or modal then return end
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
  panelName="Construir" panel.Visible=not panel.Visible
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
       table.insert(entry.Parts,{Part=part,Local=rest,Wing=wing,Leg=leg,Arm=arm,Tail=tail,Side=rest.Position.X<0 and -1 or 1})
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
local function updateGuide()
 local cf=plotFrame()
 if not cf then return end
 if not guidePart then
  guidePart=create("Part",{Name="SuaBaseLocal",Size=Vector3.new(1,1,1),Transparency=1,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false},effects)
  local billboard=create("BillboardGui",{Name="SuaBase",Size=UDim2.fromOffset(160,46),StudsOffsetWorldSpace=Vector3.new(0,14,0),AlwaysOnTop=true,MaxDistance=1800},guidePart)
  local bg=frame(billboard,{Size=UDim2.fromScale(1,1),BackgroundColor3=colors.Background,BackgroundTransparency=.15})
  stroke(bg,colors.Green,2,.2)
  label(bg,"▼  SUA BASE",{Size=UDim2.fromScale(1,1),TextColor3=colors.Green,TextSize=18,Font=Enum.Font.GothamBlack,TextXAlignment=Enum.TextXAlignment.Center})
 end
 guidePart.Position=(cf*CFrame.new(0,0,-72)).Position
end

stateRemote.OnClientEvent:Connect(function(snapshot)
 if type(snapshot)~="table" then return end
 state=snapshot
 state.Builds=state.Builds or {} state.Creatures=state.Creatures or {} state.Inventory=state.Inventory or {} state.Pending=state.Pending or {}
 if state.Carrying and build then cancelBuild() end
 lastCandidateKey=nil
 refreshHUD()
 updateGuide()
 -- Avoid destroying shop buttons on every energy tick.
 local signature=tostring(#state.Builds)..":"..tostring(#state.Creatures)..":"..tostring(state.BatteryLevel)..":"..tostring(state.WeaponLevel)..":"..tostring(state.SpeedLevel)..":"..tostring(state.ProcessorLevel)
 for kind in pairs(C.Items) do signature..=kind..tostring(state.Inventory[kind] or 0) end
 if panelName=="Criaturas" then
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
      roll=limb.Side*(idle*.08+stride*.22+producing*.65+(attacking and .8 or 0))
     elseif limb.Leg then
      pitch=stride*.45*limb.Side
      lift=math.max(0,stride*limb.Side)*.16
     elseif limb.Arm then
      pitch=-stride*.3*limb.Side+(attacking and -.85 or 0)+producing*.3
     elseif limb.Tail then
      yaw=idle*.08+stride*.15
      pitch=producing*.2+(attacking and .25 or 0)
     end
     limb.Part.CFrame=pivot*CFrame.new(0,lift,0)*limb.Local*CFrame.Angles(pitch,yaw,roll)
    end
   end
  end
 end
end)
responsive()
send("GetState")
task.delay(2,function() send("GetState") scanCreatures() end)
