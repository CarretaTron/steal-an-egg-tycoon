-- Editor-only display. Call Build(library, definitions) from a trusted command.
-- Never moves or decorates the playable map. The library models are copied.
local Showroom={}
local origin=Vector3.new(1600,1,0)
local function part(parent,name,size,position,color)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.Position=position;p.Color=color
 p.Anchored=true;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 p.Material=Enum.Material.SmoothPlastic;p.Parent=parent;return p
end
local function text(onPart,body,color,size,face)
 local surface=Instance.new('SurfaceGui');surface.Face=face or Enum.NormalId.Top;surface.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
 surface.PixelsPerStud=25;surface.Parent=onPart
 local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
 label.Text=body;label.TextColor3=color;label.Font=Enum.Font.GothamBold;label.TextSize=size;label.TextWrapped=true
 label.TextStrokeTransparency=1;label.Parent=surface
 if surface.Face==Enum.NormalId.Top then
  label.AnchorPoint=Vector2.new(.5,.5);label.Position=UDim2.fromScale(.5,.5)
  label.Size=UDim2.fromOffset(onPart.Size.X*25,onPart.Size.Z*25);label.Rotation=-90
 end
end
function Showroom.Build(library,definitions)
 assert(not game:GetService('RunService'):IsRunning(),'Use no modo Editar.')
 assert(not workspace:FindFirstChild('CatalogoDecoracao'),'Já existe um catálogo. Preserve-o antes de criar outro.')
 local root=Instance.new('Folder');root.Name='CatalogoDecoracao';root:SetAttribute('EditorCatalog',true)
 root:SetAttribute('Source','Blender/Decoracao/CatalogoDecoracao.blend');root:SetAttribute('Revision','Decoracao_v1')
 local display=Instance.new('Folder');display.Name='Modelos_Para_Copiar';display.Parent=root
 local stage=Instance.new('Folder');stage.Name='Vitrine_Nao_Copiar';stage.Parent=root
 local floor=part(stage,'Plataforma',Vector3.new(196,1,232),origin,Color3.fromRGB(215,231,218));floor.TopSurface=Enum.SurfaceType.Studs
 local path=part(stage,'Caminho',Vector3.new(9,.12,212),origin+Vector3.new(0,.56,0),Color3.fromRGB(245,244,226))
 part(stage,'BordaEsquerda',Vector3.new(2,1.3,232),origin+Vector3.new(-99,.2,0),Color3.fromRGB(53,91,78))
 part(stage,'BordaDireita',Vector3.new(2,1.3,232),origin+Vector3.new(99,.2,0),Color3.fromRGB(53,91,78))
 local title=part(stage,'PlacaDoCatalogo',Vector3.new(180,13,1.2),origin+Vector3.new(0,10,-117),Color3.fromRGB(25,51,53))
 text(title,'CATÁLOGO DE DECORAÇÃO\n20 modelos originais • árvores, plantas, rochas e cristais',Color3.fromRGB(204,255,181),64,Enum.NormalId.Front)
 local instruction=part(stage,'ComoUsar',Vector3.new(160,.25,8),origin+Vector3.new(0,.8,-108),Color3.fromRGB(244,246,223))
 text(instruction,'Selecione um modelo em Modelos_Para_Copiar  →  Ctrl+D  →  mova para decorar',Color3.fromRGB(25,51,53),34)
 local accents={Campo=Color3.fromRGB(141,211,82),Floresta=Color3.fromRGB(57,173,117),['Pântano']=Color3.fromRGB(107,173,139),Deserto=Color3.fromRGB(239,197,113),Gelo=Color3.fromRGB(142,224,246),['Vulcão']=Color3.fromRGB(250,126,77),Vazio=Color3.fromRGB(185,141,243)}
 local count=0
 for index,d in ipairs(definitions)do
  local sample=library:FindFirstChild(d.Id);assert(sample,'Modelo ausente: '..d.Id)
  local column=(index-1)%4;local row=math.floor((index-1)/4)
  local cell=origin+Vector3.new((column-1.5)*46,1.4,-81+row*44)
  local pedestal=part(stage,'Pedestal_'..d.Id,Vector3.new(34,1.2,32),cell-Vector3.new(0,.6,0),Color3.fromRGB(250,248,235))
  local stripe=part(stage,'Bioma_'..d.Id,Vector3.new(34,.12,2),cell+Vector3.new(0,.05,-15),accents[d.Biome] or accents.Campo)
  local plaque=part(stage,'Nome_'..d.Id,Vector3.new(34,.22,6.5),cell+Vector3.new(0,-.1,-19),Color3.fromRGB(30,60,59))
  text(plaque,string.format('%02d  %s\n%s',index,d.Name,d.Biome),Color3.fromRGB(248,255,231),33)
  local model=sample:Clone();model.Name=d.Id;model:PivotTo(CFrame.new(cell));model.Parent=display
  model:SetAttribute('Nome',d.Name);model:SetAttribute('Bioma',d.Biome);model:SetAttribute('Category',d.Category)
  count+=1
  if index%4==0 then task.wait()end
 end
 root:SetAttribute('Models',count);root.Parent=workspace
 return root
end
return Showroom
