local root=game.ServerStorage:WaitForChild('EggTycoonV2_Backup')
local list={root};for _,x in ipairs(root:GetDescendants()) do table.insert(list,x) end
local ids={};for i,x in ipairs(list) do ids[x]='V2_'..i end
local function pack(v)
 local t=typeof(v)
 if t=='Instance' then return {Type='Ref',Value=ids[v] or 'null'} end
 if t=='Vector3' then return {Type=t,Value={v.X,v.Y,v.Z}} end
 if t=='Vector2' then return {Type=t,Value={v.X,v.Y}} end
 if t=='CFrame' then return {Type=t,Value={v:GetComponents()}} end
 if t=='Color3' then return {Type=t,Value={v.R,v.G,v.B}} end
 if t=='UDim2' then return {Type=t,Value={v.X.Scale,v.X.Offset,v.Y.Scale,v.Y.Offset}} end
 if t=='UDim' then return {Type=t,Value={v.Scale,v.Offset}} end
 if t=='EnumItem' then return {Type='token',Value=v.Value} end
 if t=='string' or t=='boolean' or t=='number' then return {Type=t,Value=v} end
end
local fields={'Name','Source','Disabled','Enabled','Size','CFrame','Color','Material','Transparency','Anchored','CanCollide','CanTouch','CanQuery','CastShadow','Shape','TopSurface','BottomSurface','LeftSurface','RightSurface','FrontSurface','BackSurface','PrimaryPart','PivotOffset','WorldPivot','StudsOffset','StudsOffsetWorldSpace','MaxDistance','AlwaysOnTop','Adornee','Text','TextColor3','TextSize','Font','TextStrokeTransparency','TextStrokeColor3','TextScaled','TextWrapped','TextXAlignment','TextYAlignment','BackgroundColor3','BackgroundTransparency','BorderSizePixel','Position','AnchorPoint','Rotation','ZIndex','Visible','CornerRadius','Thickness','LightEmission','Brightness','Range','Value'}
for _,name in ipairs({'ActionText','ObjectText','KeyboardKeyCode','GamepadKeyCode','MaxActivationDistance','HoldDuration','RequiresLineOfSight','ClickablePrompt','Style','Color3','Adornee','ResetOnSpawn'}) do table.insert(fields,name) end
local out={}
for i,x in ipairs(list) do
 local row={Id=ids[x],Class=x.ClassName,Parent=ids[x.Parent],Properties={},Attributes={}}
 for _,name in ipairs(fields) do local ok,v=pcall(function() return x[name] end);if ok then row.Properties[name]=pack(v) end end
 for name,v in pairs(x:GetAttributes()) do row.Attributes[name]=pack(v) end
 table.insert(out,row);if i%100==0 then task.wait() end
end
return game:GetService('HttpService'):JSONEncode(out)
