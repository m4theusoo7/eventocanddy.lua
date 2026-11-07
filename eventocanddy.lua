-- Farm Pumpkin Adaptado | RemoteEvent + VirtualInputManager + ClickDetector/ProximityPrompt
-- Uso: cole no EXECUTOR (LocalScript) e aperte E para ligar/desligar

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

-- CONFIG (troque aqui)
local CONFIG = {
	NomeAlvo = "Pumpkin",          -- nome exato no Explorer
	VelocidadeTP = 200,
	TeclaToggle = Enum.KeyCode.E,
	RangeAtaque = 15,              -- força ataque só perto
	Cooldown = 0.12,               -- cooldown do M1
	TrocarLock = false,            -- true = trava a câmera no alvo

	-- RemoteEvent
	UsarRemoteEvent = true,
	RemotePath = nil,              -- ex: ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HitEvent")
	RemoteKeywords = {"Combat", "Hit", "Attack", "M1", "Damage", "Swing", "Click"},
	-- Monte os args do seu jogo. Ex: return {parte} ou return {ferramenta, parte}
	-- Use SimpleSpy/Hydroxide para descobrir os args reais e ajuste.
	RemoteArgs = function(ferramenta, parte, alvo)
		-- Descomente o que o seu jogo usa:
		-- return parte
		-- return ferramenta, parte
		-- return "Hit", parte
		return { parte } -- padrão
	end,

	-- Outros métodos
	UsarClickDetector = true,      -- usa fireclickdetector (executor)
	UsarProximityPrompt = true,    -- usa fireproximityprompt (executor)
	UsarVirtualMouse = true,       -- usa VirtualInputManager (M1 simulado)
	UsarToolActivate = true,       -- usa Tool:Activate() (fallback vanilla)
}

local Rodando = false

-- ========= HELPERS =========
local function getChar()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local ferramenta = char and char:FindFirstChildOfClass("Tool")
	return char, root, hum, ferramenta
end

local function parteDaAbobora(obj)
	if obj:IsA("BasePart") then
		return obj
	elseif obj:IsA("Model") then
		return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

-- Descoberta automática do RemoteEvent (cache)
local RemoteEventCache = nil
local function acharRemoteEvent()
	if RemoteEventCache and RemoteEventCache.Parent then
		return RemoteEventCache
	end

	if CONFIG.RemotePath then
		local ok, re = pcall(function()
			return CONFIG.RemotePath
		end)
		if ok and re and re:IsA("RemoteEvent") then
			RemoteEventCache = re
			return re
		end
	end

	-- varre ReplicatedStorage procurando keyword no nome
	local candidatos = {}
	for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
		if v:IsA("RemoteEvent") then
			local nome = string.lower(v.Name)
			for _, kw in ipairs(CONFIG.RemoteKeywords) do
				if string.find(nome, string.lower(kw)) then
					table.insert(candidatos, v)
					break
				end
			end
		end
	end

	if #candidatos > 0 then
		-- pega o mais curto (geralmente o "HitEvent" principal)
		table.sort(candidatos, function(a, b) return #a.Name < #b.Name end)
		RemoteEventCache = candidatos[1]
		return RemoteEventCache
	end
	return nil
end

local function equipar(root, hum, ferramenta)
	if not ferramenta or not hum or hum.Health <= 0 then return end
	if ferramenta.Parent ~= hum then
		pcall(function() hum:EquipTool(ferramenta) end)
	end
end

-- Ataque via VirtualInputManager (simula clique esquerdo)
local function cliqueVirtual()
	if not CONFIG.UsarVirtualMouse then return end
	pcall(function()
		local pos = UIS:GetMouseLocation() -- fallback se não houver mouse
		VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
		task.wait(0.05)
		VIM:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
	end)
end

-- Dispara todos os métodos de ataque num alvo
local function atacar(alvo, parte, root, hum, ferramenta)
	-- 1) RemoteEvent (principal — servidor não precisa do clique)
	if CONFIG.UsarRemoteEvent then
		local re = acharRemoteEvent()
		if re then
			local args = CONFIG.RemoteArgs(ferramenta, parte, alvo)
			-- args pode ser valor único ou tabela
			if type(args) == "table" and #args > 0 then
				pcall(function() re:FireServer(table.unpack(args)) end)
			else
				pcall(function() re:FireServer(args) end)
			end
		end
	end

	-- 2) ClickDetector
	if CONFIG.UsarClickDetector then
		local cd = alvo:FindFirstChildWhichIsA("ClickDetector", true) or (parte and parte:FindFirstChildWhichIsA("ClickDetector"))
		if cd and fireclickdetector then
			-- fireclickdetector(clickDetector, distance, mouseButton)
			pcall(fireclickdetector, cd, CONFIG.RangeAtaque, Enum.MouseButton1)
		end
	end

	-- 3) ProximityPrompt
	if CONFIG.UsarProximityPrompt then
		local prompt = alvo:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt and fireproximityprompt then
			pcall(fireproximityprompt, prompt, CONFIG.RangeAtaque, 0)
		end
	end

	-- 4) VirtualInputManager (M1 físico simulado)
	cliqueVirtual()

	-- 5) Tool Activate (fallback vanilla)
	if CONFIG.UsarToolActivate and ferramenta then
		pcall(function() ferramenta:Activate() end)
	end
end

local function teleportAte(parte, root)
	local destino = parte.CFrame + Vector3.new(0, 3, 0)
	local dist = (destino.Position - root.Position).Magnitude
	local tempo = math.max(dist / CONFIG.VelocidadeTP, 0.05)

	local tween = TweenService:Create(root, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {
		CFrame = destino
	})
	tween:Play()
	tween.Completed:Wait()
	task.wait(0.05)
end

-- ========= TOGGLE =========
UIS.InputBegan:Connect(function(input, processado)
	if processado then return end
	if input.KeyCode == CONFIG.TeuclaToggle then
		Rodando = not Rodando
		print("Farm Pumpkin:", Rodando)
	end
end)

-- ========= LOOP PRINCIPAL =========
task.spawn(function()
	while true do
		task.wait()

		if Rodando then
			local char, root, hum, ferramenta = getChar()
			if root and hum and hum.Health > 0 then
				equipar(root, hum, ferramenta)

				-- VARRE O MAPA TODO
				for _, obj in ipairs(workspace:GetDescendants()) do
					if not Rodando then break end
					if obj.Name == CONFIG.NomeAlvo then
						local parte = parteDaAbobora(obj)
						if parte and parte.Parent then

							-- 2. TELEPORTA ATÉ ELA
							teleportAte(parte, root)

							-- 3. ATACA ATÉ QUEBRAR / SUMIR
							while obj.Parent and parte.Parent and Rodando do
								-- olha para a abóbora
								pcall(function()
									root.CFrame = CFrame.lookAt(root.Position, Vector3.new(parte.Position.X, root.Position.Y, parte.Position.Z))
								end)

								local dist = (parte.Position - root.Position).Magnitude
								if dist <= CONFIG.RangeAtaque then
									atacar(obj, parte, root, hum, ferramenta)
								end

								task.wait(CONFIG.Cooldown)
							end
						end
					end
				end
			end
		end
	end
end)
