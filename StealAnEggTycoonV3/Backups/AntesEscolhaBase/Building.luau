local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage:WaitForChild("EggTycoonV3").Shared.BuildRules)
local Building = {}
Building.__index = Building

function Building.new(ctx)
	return setmetatable({ctx=ctx},Building)
end

function Building:GetBuild(state,id)
	for _, build in ipairs(state.Profile.Builds) do
		if build.Id == id then return build end
	end
	return nil
end

function Building:Reserved(state,id)
	if state.Pending and state.Pending[id] then return true end
	for _, pending in pairs(state.Pending or {}) do
		if pending.IncubatorId == id then return true end
	end
	for _, other in pairs(self.ctx.States) do
		local carry = other.Carry
		if carry and carry.Kind == "Creature" then
			if (other == state and carry.DestinationHabitatId == id)
				or (carry.VictimUserId == state.Player.UserId and carry.SourceHabitatId == id) then return true end
		end
	end
	return false
end

function Building:FreeHabitat(state)
	local used = {}
	for _, creature in ipairs(state.Profile.Creatures) do used[creature.HabitatId]=true end
	for _, build in ipairs(state.Profile.Builds) do
		if build.Kind == "Habitat" and not used[build.Id] and not self:Reserved(state,build.Id) then return build end
	end
	return nil
end

local function occupied(state,id)
	for _, creature in ipairs(state.Profile.Creatures) do
		if creature.HabitatId == id then return true end
	end
	return false
end

function Building:Starter(state)
	if #state.Profile.Builds>0 then state.Profile.StarterPlaced=true;state.Runtime.StarterGeneration=state.Generation return end
	if state.Profile.StarterPlaced then state.Runtime.StarterGeneration=state.Generation return end
	if state.Runtime.StarterGeneration==state.Generation then return end
	state.Runtime.StarterGeneration=state.Generation
	state.Profile.StarterPlaced=true
	local layout = {
		{"Habitat",0,16},{"Belt",0,0},{"Belt",0,-4},{"Belt",0,-8},
		{"Processor",0,-16},{"Belt",0,-24},{"Belt",0,-28},
		{"Seller",0,-36},{"Incubator",-32,-40},
	}
	for _, entry in ipairs(layout) do
		local kind = entry[1]
		if (state.Profile.Inventory[kind] or 0)>0 then
			state.Profile.Inventory[kind] -= 1
			table.insert(state.Profile.Builds,{Id=HttpService:GenerateGUID(false),Kind=kind,X=entry[2],Z=entry[3],R=0,Level=kind=="Habitat" and 0 or nil})
		end
	end
	state.Runtime.BuildVersion = (state.Runtime.BuildVersion or 0)+1
end

function Building:Render(state)
	self:Starter(state)
	local folder = state.Plot:FindFirstChild("Structures")
	if not folder then folder=Instance.new("Folder") folder.Name="Structures" folder.Parent=state.Plot end
	folder:ClearAllChildren()
	for _, build in ipairs(state.Profile.Builds) do
		local model = self.ctx.Art.Structure(build.Kind,self.ctx.Config.ItemCFrame(self.ctx.Config.PlotCFrame(state.PlotId),build),folder)
		model.Name = build.Kind .. "_" .. build.Id
		model:SetAttribute("BuildId",build.Id)
		model:SetAttribute("Kind",build.Kind)
		model:SetAttribute("OwnerUserId",state.Player.UserId)
		if build.Kind=="Habitat" then model:SetAttribute("Level",build.Level or 0) end
		local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
		if part then
			part:SetAttribute("BuildId",build.Id)
			part:SetAttribute("OwnerUserId",state.Player.UserId)
			if build.Kind == "Incubator" then
				local prompt=Instance.new("ProximityPrompt")
				prompt.Name="IncubateEgg"
				prompt.ActionText="Incubar ovo"
				prompt.ObjectText="Incubadora"
				prompt.HoldDuration=.3
				prompt.MaxActivationDistance=14
				prompt.RequiresLineOfSight=false
				prompt:SetAttribute("Action","Deliver")
				prompt:SetAttribute("BuildId",build.Id)
				prompt:SetAttribute("OwnerUserId",state.Player.UserId)
				prompt.Parent=part
			end
		end
	end
	state.Runtime.BuildVersion = (state.Runtime.BuildVersion or 0)+1
	local production=self.ctx.Services.Production
	if production then production:RenderCreatures(state) end
end

function Building:Command(state,action,payload)
	payload=type(payload)=="table" and payload or {}
	local profile,C=state.Profile,self.ctx.Config
	local function reject(message) self.ctx:Toast(state.Player,message) return false end
	if state.OperationBusy or state.Leaving then return reject("Aguarde a operação atual terminar.") end
	local function success(message,render)
		if render then self:Render(state) end
		self.ctx:Sync(state)
		if message then self.ctx:Toast(state.Player,message) end
		return true
	end
	if not self.ctx:Near(state.Player,C.PlotCFrame(state.PlotId).Position,135) then return reject("Volte para sua base para construir.") end
	if (state.LastCombat or 0)>0 and os.clock()-state.LastCombat<C.CombatLock then return reject("Construção bloqueada durante a invasão.") end
	if action == "BuyItem" then
		local def=C.Items[payload.Kind]
		if not def then return reject("Item desconhecido.") end
		local count=tonumber(payload.Count) or 1
		if count~=count or count%1~=0 or count<1 or count>20 then return reject("Quantidade inválida.") end
		local owned=profile.Inventory[payload.Kind] or 0
		if payload.Kind=="Habitat" then
			for _,build in ipairs(profile.Builds) do if build.Kind=="Habitat" then owned+=1 end end
			if owned+count>C.MaxHabitats then return reject("Limite de oito habitats.") end
		end
		if (profile.Inventory[payload.Kind] or 0)+count>500 then return reject("Limite de itens guardados atingido.") end
		local price=def.Price*count
		if profile.Cash<price then return reject("Dinheiro insuficiente.") end
		profile.Cash-=price
		profile.Inventory[payload.Kind]=(profile.Inventory[payload.Kind] or 0)+count
		return success("Compra concluída.",false)
	elseif action=="UpgradeHabitat" then
		if type(payload.Id)~="string" then return reject("Habitat inválido.") end
		local habitat=self:GetBuild(state,payload.Id)
		if not habitat or habitat.Kind~="Habitat" then return reject("Habitat não encontrado.") end
		if self:Reserved(state,habitat.Id) then return reject("Esse habitat está reservado por incubação ou roubo.") end
		local level=habitat.Level or 0
		local price=C.HabitatPrices[level+1]
		if level>=3 or not price then return reject("Habitat no nível máximo.") end
		if profile.Cash<price then return reject("Dinheiro insuficiente.") end
		profile.Cash-=price
		habitat.Level=level+1
		if self.ctx.Services.Progression then self.ctx.Services.Progression:Record(state,"HabitatUpgrades",1) end
		return success("Habitat melhorado! Produção aumentada.",true)
	elseif action=="Place" or action=="Move" then
		local previous=action=="Move" and self:GetBuild(state,payload.BuildId) or nil
		if action=="Move" and not previous then return reject("Construção não encontrada.") end
		if previous and self:Reserved(state,previous.Id) then return reject("Essa construção está reservada por incubação ou roubo.") end
		local kind=previous and previous.Kind or payload.Kind
		if not C.Items[kind] then return reject("Item desconhecido.") end
		if not previous and (profile.Inventory[kind] or 0)<1 then return reject("Compre esse item antes de posicionar.") end
		local storedIndex,storedHabitat
		if not previous and kind=="Habitat" then
			for index,habitat in ipairs(profile.StoredHabitats or {}) do
				if not storedHabitat or habitat.Level>storedHabitat.Level then storedIndex,storedHabitat=index,habitat end
			end
		end
		local candidate={Id=previous and previous.Id or (storedHabitat and storedHabitat.Id or HttpService:GenerateGUID(false)),Kind=kind,X=payload.X,Z=payload.Z,R=payload.R or 0,Level=kind=="Habitat" and (previous and previous.Level or storedHabitat and storedHabitat.Level or 0) or nil}
		local ok,reason=Rules.Validate(profile.Builds,candidate,previous and previous.Id)
		if not ok then return reject(reason) end
		if previous then
			previous.X,previous.Z,previous.R=candidate.X,candidate.Z,candidate.R
		else
			profile.Inventory[kind]-=1
			if storedIndex then table.remove(profile.StoredHabitats,storedIndex) end
			table.insert(profile.Builds,candidate)
		end
		return success(nil,true)
	elseif action=="Store" then
		local build=self:GetBuild(state,payload.BuildId)
		if not build then return reject("Construção não encontrada.") end
		if self:Reserved(state,build.Id) or occupied(state,build.Id) then return reject("Libere o habitat e aguarde a incubação ou roubo terminar.") end
		local ok,reason=Rules.Validate(profile.Builds,nil,build.Id)
		if not ok then return reject(reason) end
		for i,item in ipairs(profile.Builds) do if item==build then table.remove(profile.Builds,i) break end end
		profile.Inventory[build.Kind]=(profile.Inventory[build.Kind] or 0)+1
		if build.Kind=="Habitat" and (build.Level or 0)>0 then
			profile.StoredHabitats=profile.StoredHabitats or {}
			table.insert(profile.StoredHabitats,{Id=build.Id,Level=build.Level})
		end
		return success("Construção guardada.",true)
	elseif action=="ReleaseCreature" then
		for index,creature in ipairs(profile.Creatures) do
			if creature.Id==payload.CreatureId then
				if self:Reserved(state,creature.HabitatId) then return reject("A criatura está envolvida em uma transferência.") end
				table.remove(profile.Creatures,index)
				local production=self.ctx.Services.Production
				if production then production:RenderCreatures(state) end
				return success("Criatura liberada.",false)
			end
		end
		return reject("Criatura não encontrada.")
	end
	return false
end

return Building