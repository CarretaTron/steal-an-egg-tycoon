local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Rules = require(ReplicatedStorage:WaitForChild("EggTycoonV3").Shared.BuildRules)
local Production = {}
Production.__index = Production

function Production.new(ctx)
	return setmetatable({ctx=ctx},Production)
end

function Production:IsTransported(state,creature)
	for _,other in pairs(self.ctx.States) do
		local carry=other.Carry
		if carry and carry.Kind=="Creature" and carry.Creature and carry.Creature.Id==creature.Id then return true end
	end
	return false
end

function Production:Graph(state)
	local runtime=state.Runtime
	if runtime.ProductionBuildVersion~=runtime.BuildVersion or not runtime.ProductionGraph then
		runtime.ProductionGraph=Rules.Graph(state.Profile.Builds)
		runtime.ProductionRoutes={}
		runtime.ProductionBuildVersion=runtime.BuildVersion
	end
	return runtime.ProductionGraph
end

function Production:Route(state,habitatId)
	local graph=self:Graph(state)
	local routes=state.Runtime.ProductionRoutes
	if routes[habitatId]==nil then routes[habitatId]=Rules.Trace(state.Profile.Builds,habitatId,graph) or false end
	return routes[habitatId] or nil
end

function Production:Multiplier(state,habitatId)
	local multipliers=self.ctx.Config.ProcessorMultipliers
	local habitatMultiplier=1
	if habitatId then
		for _,build in ipairs(state.Profile.Builds) do
			if build.Id==habitatId and build.Kind=="Habitat" then
				local habitatMultipliers=self.ctx.Config.HabitatMultipliers or {1}
				habitatMultiplier=habitatMultipliers[math.clamp((build.Level or 0)+1,1,#habitatMultipliers)]
				break
			end
		end
	end
	return (1+state.Profile.Rebirths*self.ctx.Config.RebirthMultiplier)*multipliers[math.clamp(state.Profile.ProcessorLevel or 1,1,#multipliers)]*habitatMultiplier
end

function Production:Income(state)
	local income=0
	for _,creature in ipairs(state.Profile.Creatures) do
		if not self:IsTransported(state,creature) and self:Route(state,creature.HabitatId) then
			local species=self.ctx.Config.Species[creature.Species]
			if species then income+=species.Rate*self:Multiplier(state,creature.HabitatId) end
		end
	end
	return income
end

function Production:RenderCreatures(state)
	local folder=state.Plot:FindFirstChild("Creatures")
	if not folder then folder=Instance.new("Folder") folder.Name="Creatures" folder.Parent=state.Plot end
	folder:ClearAllChildren()
	local building=self.ctx.Services.Building
	if not building then return end
	for _,creature in ipairs(state.Profile.Creatures) do
		local build=building:GetBuild(state,creature.HabitatId)
		local species=self.ctx.Config.Species[creature.Species]
		if build and species and not self:IsTransported(state,creature) then
			local cf=self.ctx.Config.ItemCFrame(self.ctx.Config.PlotCFrame(state.PlotId),build)*CFrame.new(0,1.1,0)
			local model=self.ctx.Art.Creature(creature.Species,cf,1,folder)
			model.Name="Creature_"..creature.Id
			model:SetAttribute("CreatureId",creature.Id)
			model:SetAttribute("Species",creature.Species)
			model:SetAttribute("OwnerUserId",state.Player.UserId)
			model:SetAttribute("HabitatId",creature.HabitatId)
			local part=model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
			if part then
				local prompt=Instance.new("ProximityPrompt")
				prompt.Name="StealCreature"
				prompt.ActionText="Roubar criatura"
				prompt.ObjectText=species.Name
				prompt.HoldDuration=2
				prompt.MaxActivationDistance=20
				prompt.RequiresLineOfSight=false
				prompt:SetAttribute("Action","StealCreature")
				prompt:SetAttribute("OwnerUserId",state.Player.UserId)
				prompt:SetAttribute("CreatureId",creature.Id)
				prompt:SetAttribute("BuildId",creature.HabitatId)
				prompt.Parent=part
				local label=Instance.new("BillboardGui")
				label.Name="ProductionLabel"
				label.Size=UDim2.fromOffset(180,56)
				label.StudsOffset=Vector3.new(0,7,0)
				label.MaxDistance=90
				label.AlwaysOnTop=false
				label.Parent=part
				local text=Instance.new("TextLabel")
				text.Size=UDim2.fromScale(1,1)
				text.BackgroundTransparency=1
				text.TextColor3=species.Color
				text.TextStrokeTransparency=.25
				text.Font=Enum.Font.GothamBold
				text.TextSize=16
				text.Text=species.Name.."\n"..species.Resource
				text.Parent=label
			end
		end
	end
end

function Production:Step(state,dt)
	if not state.Profile or not state.Plot or not state.Runtime then return end
	dt=math.clamp(tonumber(dt) or 0,0,5)
	local runtime=state.Runtime
	runtime.ProductionClocks=runtime.ProductionClocks or {}
	runtime.ResourcePackets=runtime.ResourcePackets or {}
	if runtime.PacketGeneration~=state.Generation then
		local firstStep=runtime.PacketGeneration==nil
		runtime.ResourcePackets={}
		runtime.ProductionClocks={}
		runtime.PacketGeneration=state.Generation
		if firstStep then
			local restored={}
			local plotCf=self.ctx.Config.PlotCFrame(state.PlotId)
			for _,packet in ipairs(state.Profile.ResourceEscrow or {}) do
				if packet.Id and not restored[packet.Id] and #runtime.ResourcePackets<256 then
					restored[packet.Id]=true
					local path={}
					for _,point in ipairs(packet.Path or {}) do table.insert(path,plotCf:PointToWorldSpace(Vector3.new(point.X,1.6,point.Z))) end
					table.insert(runtime.ResourcePackets,{Id=packet.Id,Value=packet.Value,Remaining=packet.Remaining,Lifetime=0,
						CreatureId=packet.CreatureId,Species=packet.Species,Path=packet.Path})
					if #path>=2 and packet.Remaining>0 then
						self.ctx.Remotes.FX:FireAllClients("Resource",{Id=packet.Id,Path=path,Species=packet.Species,CreatureId=packet.CreatureId,Processed=true,Duration=packet.Remaining})
					end
				end
			end
		end
		-- Move escrow into runtime once. Snapshot replaces it with that queue on save.
		state.Profile.ResourceEscrow={}
	end
	local packets=runtime.ResourcePackets
	-- A packet is owned by this queue once, and removed before its one payment.
	for index=#packets,1,-1 do
		local packet=packets[index]
		packet.Remaining-=dt
		packet.Lifetime+=dt
		if packet.Remaining<=0 then
			table.remove(packets,index)
			state.Profile.Cash+=packet.Value
			local progression=self.ctx.Services.Progression
			if progression then
				progression:Record(state,"Sales",1)
				progression:Record(state,"ResourcesSold",1)
			end
		elseif packet.Lifetime>60 then
			-- Defensive bound for damaged runtime state, not a second payment route.
			table.remove(packets,index)
		end
	end
	local living={}
	local plotCf=self.ctx.Config.PlotCFrame(state.PlotId)
	for _,creature in ipairs(state.Profile.Creatures) do
		living[creature.Id]=true
		local species=self.ctx.Config.Species[creature.Species]
		if species and not self:IsTransported(state,creature) then
			local clock=(runtime.ProductionClocks[creature.Id] or 0)+dt
			creature.Stored=math.clamp(math.floor(tonumber(creature.Stored) or 0),0,20)
			while clock>=4 do
				clock-=4
				creature.Stored=math.min(20,creature.Stored+1)
			end
			runtime.ProductionClocks[creature.Id]=clock
			local route=self:Route(state,creature.HabitatId)
			if route and creature.Stored>0 and #packets<256 then
				local path,distance={},0
				for _,point in ipairs(route.Path) do
					local worldPoint=plotCf:PointToWorldSpace(Vector3.new(point.X,1.6,point.Z))
					if #path>0 then distance+=(worldPoint-path[#path]).Magnitude end
					table.insert(path,worldPoint)
				end
				local duration=math.clamp(distance/18,1,25)
				creature.Stored-=1
				local id=HttpService:GenerateGUID(false)
				table.insert(packets,{Id=id,Value=species.Rate*4*self:Multiplier(state,creature.HabitatId),Remaining=duration,Lifetime=0,CreatureId=creature.Id,Species=creature.Species,Path=route.Path})
				self.ctx.Remotes.FX:FireAllClients("Resource",{Id=id,Path=path,Species=creature.Species,CreatureId=creature.Id,Processed=true,Duration=duration})
			end
		end
	end
	for id in pairs(runtime.ProductionClocks) do if not living[id] then runtime.ProductionClocks[id]=nil end end
end

return Production
