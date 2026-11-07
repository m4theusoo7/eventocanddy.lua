--[[
	==================================================
		BLOX FRUITS — AUTO FARM
		Auto Farm para executores: Fluxus, Hydrogen, Arceus X
	==================================================
]]

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- // ===== CONFIGURAÇÕES =====
-- Delay entre ataques: intervalo calculado para evitar travamento do jogo
local CONFIG = {
	DELAY = 0.1,          -- Tempo entre um ataque e outro
	FIGHT_RANGE = 30,     -- Alcance máximo para atacar o NPC
	REFRESH_INTERVAL = 5 -- Tempo para renovar a lista de inimigos
}

-- // ===== CACHE DE INIMIGOS =====
-- Mantém a lista de inimigos para não varrer o workspace a cada frame (otimização)
local enemies = {}
local lastRefresh = 0

local function refreshEnemies()
	enemies = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			local enemyRoot = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
			-- // Só considera inimigos vivos
			if hum and hum.Health > 0 and hum.MaxHealth > 0 and enemyRoot then
				table.insert(enemies, { humanoid = hum, rootPart = enemyRoot })
			end
		end
	end
	lastRefresh = os.clock()
end
refreshEnemies()

-- // ===== FUNÇÃO: BUSCAR O INIMIGO MAIS PRÓXIMO =====
local function getNearestEnemy()
	-- // Renova a lista de inimigos a cada REFRESH_INTERVAL segundos
	if os.clock() - lastRefresh > CONFIG.REFRESH_INTERVAL then
		refreshEnemies()
	end

	local nearest = nil
	local nearestDistance = math.huge

	for _, enemy in ipairs(enemies) do
		local hum = enemy.humanoid
		if hum and hum.Health > 0 then
			local dist = (enemy.rootPart.Position - rootPart.Position).Magnitude
			-- // Só ataca se estiver dentro do alcance configurado
			if dist < nearestDistance and dist <= CONFIG.FIGHT_RANGE then
				nearestDistance = dist
				nearest = enemy
			end
		end
	end

	return nearest
end

-- // ===== FUNÇÃO: ATACAR =====
local function attack()
	local enemy = getNearestEnemy()
	if not enemy or not enemy.humanoid or enemy.humanoid.Health <= 0 then return end

	-- // Move o jogador até a posição do inimigo antes de atacar
	if (enemy.rootPart.Position - rootPart.Position).Magnitude > 5 then
		rootPart.CFrame = CFrame.new(enemy.rootPart.Position)
	end

	-- // Dano base do soco
	local damage = 10

	-- // Se o jogador estiver com uma espada equipada, usa o dano dela
	local tool = character:FindFirstChildOfClass("Tool")
	if tool and tool.Name == "Sword" then
		damage = tool:GetAttribute("Damage") or 42
	end

	-- // Aplica o dano no NPC (soco ou espada)
	enemy.humanoid:TakeDamage(damage)
end

-- // ===== LOOP PRINCIPAL (com delay para evitar travamento) =====
task.spawn(function()
	while true do
		if humanoid.Health > 0 then
			attack()
		end
		task.wait(CONFIG.DELAY)
	end
end)

-- // ===== RECONEXÃO COM O PERSONAGEM =====
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = newCharacter:WaitForChild("Humanoid")
	rootPart = newCharacter:WaitForChild("HumanoidRootPart")
end)
