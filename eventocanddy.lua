--[[
	SCRIPT: Ir até objetos no chão e quebrar
	Coloque como LocalScript dentro de StarterPlayer > StarterCharacterScripts
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- ==================== CONFIGURAÇÃO ====================
-- Mude para o nome exato dos objetos espalhados pelo mapa
local NOME_DO_OBJETO = "Abobora"          -- exemplo: "Abobora", "Caixa", "Pote", etc.
-- Ou use tags do CollectionService se preferir:
-- local TAG_DO_OBJETO = "Quebravel"

local DISTANCIA_MAXIMA_BUSCA = 150        -- até quantos estalos procura objetos
local DISTANCIA_PARA_QUEBRAR = 6          -- a que distância considera "chegou"
local TEMPO_CHEGADA = 1.2                 -- segundos do tween até o objeto
-- ======================================================

local alvoAtual = nil
let tweenAtual = nil

-- Função para achar o objeto mais próximo do jogador
local function encontrarObjetoMaisProximo()
	local maisProximo = nil
	local menorDist = math.huge
	local posJogador = root.Position

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == NOME_DO_OBJETO then
			local d = (obj.Position - posJogador).Magnitude
			if d <= DISTANCIA_MAXIMA_BUSCA and d < menorDist then
				menorDist = d
				maisProximo = obj
			end
		end
	end

	return maisProximo
end

-- Função para mover o jogador suavemente até o objeto
local function moverAte(obj)
	if tweenAtual then
		tweenAtual:Cancel()
	end

	-- Posiciona um pouco acima do objeto para não ficar preso dentro dele
	local destino = CFrame.new(obj.Position + Vector3.new(0, 4, 0))

	local info = TweenInfo.new(TEMPO_CHEGADA, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	tweenAtual = TweenService:Create(root, info, {CFrame = destino})
	tweenAtual:Play()

	alvoAtual = obj
end

-- Função para "quebrar" o objeto
local function quebrar(obj)
	if not obj then return end
	if obj:IsA("BasePart") then
		-- Opcional: tocar som de quebra, particulas, etc. aqui
		obj:Destroy()
	end
end

-- Loop principal: se não tiver alvo, procura; se tiver, verifica se chegou
RunService.Heartbeat:Connect(function()
	if not character or not root then return end

	if not alvoAtual then
		local obj = encontrarObjetoMaisProximo()
		if obj then
			moverAte(obj)
		end
	else
		-- Se o alvo ainda existe e está perto, quebra
		if alvoAtual.Parent then
			local d = (alvoAtual.Position - root.Position).Magnitude
			if d <= DISTANCIA_PARA_QUEBRAR then
				quebrar(alvoAtual)
				alvoAtual = nil
				tweenAtual = nil
			end
		else
			-- Alvo sumiu, busca outro
			alvoAtual = nil
			tweenAtual = nil
		end
	end
end)

-- Opcional: pressionar E para quebrar o objeto mais próximo sem esperar chegar perto
UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.E then
		local obj = encontrarObjetoMaisProximo()
		if obj then
			quebrar(obj)
			alvoAtual = nil
			if tweenAtual then tweenAtual:Cancel() end
		end
	end
end)
