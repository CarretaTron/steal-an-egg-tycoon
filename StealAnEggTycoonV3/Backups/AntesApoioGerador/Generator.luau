-- Blender-authored generator presentation. Battery remains the authoritative hitbox.
local Data = require(script.Parent.GeneratorData)
local AssetService = game:GetService('AssetService')
local Generator = {Revision = 2}
local prototypes = {}
local signatures = setmetatable({}, {__mode = 'k'})
local colors = {
 Background = Color3.fromRGB(24, 30, 37),
 Inset = Color3.fromRGB(12, 19, 25),
 White = Color3.fromRGB(239, 235, 239),
 Muted = Color3.fromRGB(160, 178, 183),
 Green = Color3.fromRGB(149, 235, 91),
 Amber = Color3.fromRGB(255, 187, 63),
 Red = Color3.fromRGB(255, 86, 70),
}

local function prototype(def)
 local key = def.Name .. def.MeshId
 if prototypes[key] then return prototypes[key] end
 local p = AssetService:CreateMeshPartAsync(Content.fromUri(def.MeshId))
 p.Name = def.Name
 p.Anchored = true
 p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
 prototypes[key] = p
 return p
end

function Generator.Seed(model)
 for _, def in ipairs(Data.Meshes) do
  local original = model:FindFirstChild(def.SourceName or def.Name, true)
  assert(original and original:IsA('MeshPart') and original.MeshId == def.MeshId,
   'Generator mesh mismatch: ' .. def.Name)
  prototypes[def.Name .. def.MeshId] = original:Clone()
 end
end

local function corner(parent, radius)
 local c = Instance.new('UICorner')
 c.CornerRadius = UDim.new(0, radius)
 c.Parent = parent
end

local function label(parent, name, position, size, color, font)
 local text = Instance.new('TextLabel')
 text.Name = name; text.Position = position; text.Size = size
 text.BackgroundTransparency = 1
 text.TextColor3 = color; text.Font = font or Enum.Font.GothamBold
 text.TextScaled = false; text.TextSize = 32; text.TextWrapped = false
 text.TextXAlignment = Enum.TextXAlignment.Center
 text.TextYAlignment = Enum.TextYAlignment.Center
 text.Parent = parent
 return text
end

local function screen(panel)
 local gui = Instance.new('SurfaceGui')
 gui.Name = 'BatteryLabel'; gui.Face = Enum.NormalId.Front
 gui.Adornee = panel; gui.AlwaysOnTop = false; gui.LightInfluence = 0
 gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
 gui.CanvasSize = Vector2.new(1024, 320)
 gui.PixelsPerStud = 75; gui.MaxDistance = 100
 gui:SetAttribute('BaseShellEnabled', true)
 gui.Parent = panel

 local body = Instance.new('Frame')
 body.Name = 'Display'; body.Size = UDim2.fromScale(1, 1)
 body.BorderSizePixel = 0; body.BackgroundColor3 = colors.Background
 body.Parent = gui; corner(body, 12)
 local trim = Instance.new('UIStroke')
 trim.Color = colors.Muted; trim.Thickness = 3; trim.Parent = body

 local header = label(body, 'Header', UDim2.fromScale(.04, .045), UDim2.fromScale(.92, .16), colors.Muted)
 header.Text = 'GERADOR • NÍVEL 1'
 local hp = label(body, 'Text', UDim2.fromScale(.04, .25), UDim2.fromScale(.92, .29), colors.White, Enum.Font.GothamBlack)
 hp.TextSize = 90
 hp.Text = '200 / 200'
 local bar = Instance.new('Frame')
 bar.Name = 'HealthBar'; bar.Position = UDim2.fromScale(.075, .61)
 bar.Size = UDim2.fromScale(.85, .10); bar.BorderSizePixel = 0
 bar.BackgroundColor3 = colors.Inset; bar.Parent = body; corner(bar, 5)
 local fill = Instance.new('Frame')
 fill.Name = 'Fill'; fill.Size = UDim2.fromScale(1, 1)
 fill.BorderSizePixel = 0; fill.BackgroundColor3 = colors.Green
 fill.Parent = bar; corner(fill, 5)
 local status = label(body, 'Status', UDim2.fromScale(.04, .79), UDim2.fromScale(.92, .14), colors.Green)
 status.Text = 'LASER ATIVO'
 return gui
end

local function defaults(part, transparency)
 part:SetAttribute('GeneratorPart', true)
 part:SetAttribute('GeneratorTransparency', transparency)
 part:SetAttribute('BaseShellTransparency', transparency)
 part:SetAttribute('BaseShellCanCollide', false)
 part:SetAttribute('BaseShellCanTouch', false)
 part:SetAttribute('BaseShellCanQuery', false)
 part:SetAttribute('BaseShellRevision', Generator.Revision)
end

function Generator.Present(plot, owned, _open)
 local battery = plot and plot:FindFirstChild('Battery')
 if not battery or not battery:IsA('BasePart') then return end
 battery.Transparency = 1
 battery.CanCollide = owned == true; battery.CanTouch = owned == true
 battery.CanQuery = owned == true
 local visual = battery:FindFirstChild('GeneratorVisual')
 if not visual then return end
 for _, object in ipairs(visual:GetDescendants()) do
  if object:IsA('BasePart') then
   object.Transparency = owned and (object:GetAttribute('GeneratorTransparency') or 0) or 1
   object.CanCollide = false; object.CanTouch = false; object.CanQuery = false
  elseif object:IsA('SurfaceGui') then
   object.Enabled = owned == true
  end
 end
end

function Generator.Update(plot, hp, maximum, open, remaining, level)
 local battery = plot and plot:FindFirstChild('Battery')
 local visual = battery and battery:FindFirstChild('GeneratorVisual')
 local panel = visual and visual:FindFirstChild('GeneratorPanel')
 local gui = panel and panel:FindFirstChild('BatteryLabel')
 local body = gui and gui:FindFirstChild('Display')
 if not body then return end
 maximum = math.max(1, math.ceil(tonumber(maximum) or 200))
 hp = math.clamp(math.ceil(tonumber(hp) or maximum), 0, maximum)
 remaining = math.max(0, math.ceil(tonumber(remaining) or 0))
 level = math.clamp(math.floor(tonumber(level) or 1), 1, 4)
 local signature = table.concat({hp, maximum, open and 1 or 0, remaining, level}, ':')
 if signatures[battery] == signature then return end
 signatures[battery] = signature
 local tint = open and colors.Red or (hp / maximum <= .35 and colors.Amber or colors.Green)
 body.Header.Text = 'GERADOR • NÍVEL ' .. level
 body.Text.Text = hp .. ' / ' .. maximum
 body.HealthBar.Fill.Size = UDim2.fromScale(hp / maximum, 1)
 body.HealthBar.Fill.BackgroundColor3 = tint
 body.Status.TextColor3 = tint
 body.Status.Text = open and ('RECONSTRUINDO • ' .. remaining .. 's')
  or (hp / maximum <= .35 and 'INTEGRIDADE BAIXA' or 'LASER ATIVO')
end

function Generator.Apply(plot)
 assert(plot and plot:IsA('Model'), 'Generator.Apply expects a plot Model')
 local battery = plot:FindFirstChild('Battery')
 assert(battery and battery:IsA('BasePart'), 'Generator requires the existing Battery hitbox')
 local visual = battery:FindFirstChild('GeneratorVisual')
 if battery:GetAttribute('GeneratorRevision') == Generator.Revision and visual
  and visual:FindFirstChild('GeneratorPanel') and #visual:GetChildren() == #Data.Meshes + 1 then
  return battery
 end
 -- Resolve every uploaded mesh before replacing the previous appearance.
 for _, def in ipairs(Data.Meshes) do prototype(def) end
 local staging = Instance.new('Model')
 staging.Name = 'GeneratorVisual'
 local origin = battery.CFrame * CFrame.new(0, -3.5, 0)
 for _, def in ipairs(Data.Meshes) do
  local p = prototype(def):Clone()
  p.Name = def.Name; p.Size = def.Size; p.CFrame = origin * def.LocalCF
  p.Color = def.Color; p.Material = Enum.Material.SmoothPlastic
  p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
  p.Transparency = 0; p.CastShadow = true; defaults(p, 0)
  p.Parent = staging
 end
 local panel = Instance.new('Part')
 panel.Name = 'GeneratorPanel'; panel.Size = Data.Panel.Size
 panel.CFrame = origin * Data.Panel.LocalCF; panel.Color = colors.Background
 panel.Material = Enum.Material.SmoothPlastic; panel.Anchored = true
 panel.CanCollide = false; panel.CanTouch = false; panel.CanQuery = false
 panel.CastShadow = false; defaults(panel, 0)
 for _, face in ipairs({'TopSurface', 'BottomSurface', 'LeftSurface', 'RightSurface', 'FrontSurface', 'BackSurface'}) do
  panel[face] = Enum.SurfaceType.Smooth
 end
 screen(panel); panel.Parent = staging
 if visual then visual:Destroy() end
 -- The old information was a floating label parented to Battery.
 for _, object in ipairs(battery:GetDescendants()) do
  if object:IsA('BillboardGui') or (object:IsA('SurfaceGui') and object.Name == 'BatteryLabel') then
   object:Destroy()
  end
 end
 battery.Size = Vector3.new(12, 7, 6); battery.Anchored = true
 battery.Transparency = 1
 battery:SetAttribute('BaseShellTransparency', 1)
 battery:SetAttribute('BaseShellCanCollide', true)
 battery:SetAttribute('BaseShellCanTouch', true)
 battery:SetAttribute('BaseShellCanQuery', true)
 staging.Parent = battery
 battery:SetAttribute('GeneratorRevision', Generator.Revision)
 signatures[battery] = nil
 -- Combat caches presentation by generation; invalidate it after installing new art.
 plot:SetAttribute('BaseShellGeneration', (plot:GetAttribute('BaseShellGeneration') or 0) + 1)
 local owned = (plot:GetAttribute('OwnerUserId') or 0) ~= 0
 Generator.Present(plot, owned, false)
 Generator.Update(plot, battery:GetAttribute('HP') or 200, battery:GetAttribute('MaxHP') or 200, false, 0, 1)
 return battery
end

return Generator
