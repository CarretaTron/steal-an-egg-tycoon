-- Shared placement and deterministic, single-route conveyor rules.
local C = require(script.Parent.Config)
local Rules = {}

local function finite(value)
	return type(value) == "number" and value == value and math.abs(value) < 1e7
end

function Rules.Rotate(x, z, rotation)
	local r = (rotation or 0) % 4
	if r == 1 then return z, -x end
	if r == 2 then return -x, -z end
	if r == 3 then return -z, x end
	return x, z
end

function Rules.Footprint(build)
	local def = C.Items[build.Kind]
	if not def then return 0, 0 end
	if (build.R or 0) % 2 == 1 then return def.D, def.W end
	return def.W, def.D
end

function Rules.Bounds(build)
	local width, depth = Rules.Footprint(build)
	return {MinX=build.X-width/2, MaxX=build.X+width/2, MinZ=build.Z-depth/2, MaxZ=build.Z+depth/2}
end

function Rules.Port(build, port)
	local x, z = Rules.Rotate(port[1], port[2], build.R)
	return build.X+x, build.Z+z
end

function Rules.IsBelt(kind)
	return kind == "Belt" or kind == "Curve" or kind == "Merge"
end

local function key(x, z)
	return tostring(x) .. ":" .. tostring(z)
end

local function walkable(builds)
	-- Belts sit below the avatar's step height. Machines require room around them.
	local half, spacing = C.PlotHalf-8, C.Grid
	local blocked, reached = {}, {}
	for x = -half, half, spacing do
		for z = -half, half, spacing do
			for _, build in ipairs(builds) do
				if not Rules.IsBelt(build.Kind) then
					local width, depth = Rules.Footprint(build)
					if math.abs(x-build.X) < width/2+2 and math.abs(z-build.Z) < depth/2+2 then
						blocked[key(x,z)] = true
						break
					end
				end
			end
		end
	end
	local seed = key(0,-half)
	if blocked[seed] then return false, "Mantenha a entrada livre." end
	local queue, head = {{0,-half}}, 1
	reached[seed] = true
	while head <= #queue do
		local cell = queue[head]
		head += 1
		for _, delta in ipairs({{spacing,0},{-spacing,0},{0,spacing},{0,-spacing}}) do
			local x, z = cell[1]+delta[1], cell[2]+delta[2]
			local id = key(x,z)
			if math.abs(x) <= half and math.abs(z) <= half and not blocked[id] and not reached[id] then
				reached[id] = true
				table.insert(queue, {x,z})
			end
		end
	end
	for _, build in ipairs(builds) do
		if build.Kind == "Habitat" or build.Kind == "Incubator" then
			local width, depth = Rules.Footprint(build)
			local accessible = false
			for _, cell in ipairs(queue) do
				local dx = math.max(math.abs(cell[1]-build.X)-width/2,0)
				local dz = math.max(math.abs(cell[2]-build.Z)-depth/2,0)
				if dx+dz <= 6 then accessible=true break end
			end
			if not accessible then return false, "Deixe um caminho da entrada até os habitats e incubadoras." end
		end
	end
	return true
end

function Rules.Validate(builds, candidate, ignoreId)
	if type(builds) ~= "table" then return false, "Construções inválidas." end
	local all = {}
	for _, build in ipairs(builds) do
		if not ignoreId or build.Id ~= ignoreId then table.insert(all,build) end
	end
	if candidate then table.insert(all,candidate) end
	if #all > C.MaxBuilds then return false, "Limite de construções atingido." end
	local seen, habitats = {}, 0
	for i, build in ipairs(all) do
		if type(build) ~= "table" or not C.Items[build.Kind] or type(build.Id) ~= "string" or build.Id == "" then
			return false, "Construção desconhecida."
		end
		if seen[build.Id] then return false, "Identificador de construção repetido." end
		seen[build.Id] = true
		if not finite(build.X) or not finite(build.Z) or not finite(build.R) then return false, "Posição inválida." end
		if build.X%C.Grid ~= 0 or build.Z%C.Grid ~= 0 or build.R%1 ~= 0 or build.R<0 or build.R>3 then
			return false, "Use a grade de quatro studs e giros de 90 graus."
		end
		local bounds = Rules.Bounds(build)
		local limit = C.PlotHalf-8
		if bounds.MinX < -limit or bounds.MaxX > limit or bounds.MinZ < -limit or bounds.MaxZ > limit then
			return false, "A construção precisa ficar dentro do terreno."
		end
		if not Rules.IsBelt(build.Kind) and bounds.MinX<8 and bounds.MaxX>-8 and bounds.MinZ<-56 and bounds.MaxZ>-72 then
			return false, "Mantenha livre a área de chegada e entrega."
		end
		if build.Kind == "Habitat" then habitats += 1 end
		for j=1,i-1 do
			local other = Rules.Bounds(all[j])
			if bounds.MinX<other.MaxX and bounds.MaxX>other.MinX and bounds.MinZ<other.MaxZ and bounds.MaxZ>other.MinZ then
				return false, "As construções não podem se sobrepor."
			end
		end
	end
	if habitats > C.MaxHabitats then return false, "Você pode construir até oito habitats." end
	return walkable(all)
end

function Rules.Graph(builds)
	local graph = {ById={},Belts={},Consumers={}}
	local sorted = table.clone(builds)
	table.sort(sorted,function(a,b) return a.Id<b.Id end)
	for _, build in ipairs(sorted) do
		graph.ById[build.Id] = build
		if Rules.IsBelt(build.Kind) then
			graph.Belts[key(build.X,build.Z)] = build
		elseif C.Items[build.Kind] and C.Items[build.Kind].In then
			local x,z = Rules.Port(build,C.Items[build.Kind].In)
			local cellKey=key(x,z)
			graph.Consumers[cellKey]=graph.Consumers[cellKey] or {}
			table.insert(graph.Consumers[cellKey],build)
		end
	end
	return graph
end

local function acceptsSource(belt,sourceX,sourceZ)
	if not belt then return false end
	local dx,dz=sourceX-belt.X,sourceZ-belt.Z
	for _,input in ipairs(C.Items[belt.Kind].Inputs) do
		local ix,iz=Rules.Port(belt,input)
		ix,iz=ix-belt.X,iz-belt.Z
		if ix*dz-iz*dx==0 and ix*dx+iz*dz>0 then return true end
	end
	return false
end

function Rules.Trace(builds, habitatId, existingGraph)
	local graph = existingGraph or Rules.Graph(builds)
	local source = graph.ById[habitatId]
	if not source or source.Kind ~= "Habitat" then return nil,"Habitat ausente." end
	local x,z = Rules.Port(source,C.Items.Habitat.Out)
	local belt = graph.Belts[key(x,z)]
	if not acceptsSource(belt,source.X,source.Z) then return nil,"A saída do habitat precisa entrar pelo sentido correto da esteira." end
	local path, visited, processed = {{X=source.X,Z=source.Z}}, {}, false
	local processorCount = 0
	for _=1,C.MaxBuilds*2 do
		if not belt then return nil,"Conecte as esteiras." end
		local visitKey = belt.Id .. (processed and ":P" or ":R")
		if visited[visitKey] then return nil,"O circuito de esteiras está fechado." end
		visited[visitKey] = true
		table.insert(path,{X=belt.X,Z=belt.Z})
		local outX,outZ=Rules.Port(belt,C.Items[belt.Kind].Out)
		local headingX,headingZ=outX-belt.X,outZ-belt.Z
		local consumer
		for _,candidate in ipairs(graph.Consumers[key(belt.X,belt.Z)] or {}) do
			local dx,dz=candidate.X-belt.X,candidate.Z-belt.Z
			if headingX*dz-headingZ*dx==0 and headingX*dx+headingZ*dz>0 then consumer=candidate break end
		end
		if consumer then
			table.insert(path,{X=consumer.X,Z=consumer.Z})
			if consumer.Kind == "Seller" then
				if not processed then return nil,"Passe por um processador antes do vendedor." end
				return {Path=path,SellerId=consumer.Id,Processed=true,ProcessorCount=processorCount}
			end
			processed = true
			processorCount += 1
			x,z = Rules.Port(consumer,C.Items[consumer.Kind].Out)
			belt = graph.Belts[key(x,z)]
			if not acceptsSource(belt,consumer.X,consumer.Z) then return nil,"Confira o encaixe da saída do processador." end
		else
			x,z = outX,outZ
			local nextBelt = graph.Belts[key(x,z)]
			if not nextBelt then return nil,"A esteira termina antes do vendedor." end
			local accepts = false
			for _, input in ipairs(C.Items[nextBelt.Kind].Inputs) do
				local ix,iz = Rules.Port(nextBelt,input)
				if ix==belt.X and iz==belt.Z then accepts=true break end
			end
			if not accepts then return nil,"Confira o sentido das setas das esteiras." end
			belt = nextBelt
		end
	end
	return nil,"A rota de produção excede o limite."
end

return Rules
