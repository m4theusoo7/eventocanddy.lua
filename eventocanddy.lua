--=====================================================
-- CONFIGURAÇÕES - MUDE AQUI
--=====================================================
local Distancia = 5 -- Distância que ele fica da Pumpkin. MUDE SÓ ESSE NÚMERO
local Delay = 0.15 -- Tempo de espera entre ataque e movimento. 0.15 é bom
local Tecla = Enum.KeyCode.F -- Tecla para Ligar/Desligar. Pode trocar por Enum.KeyCode.R, G, etc

--=====================================================
-- SERVIÇOS
--=====================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager") -- usado para apertar a tecla de ataque

local LocalPlayer = Players.LocalPlayer

local Ativo = false -- guarda se o script está ligado ou desligado
local Executando = false -- evita abrir 2 loops ao mesmo tempo

--=====================================================
-- FUNÇÃO 1: Pegar meu personagem
--=====================================================
local function PegarPersonagem()
	local personagem = LocalPlayer.Character
	if not personagem then return nil, nil, nil end

	local humanoid = personagem:FindFirstChildOfClass("Humanoid")
	local hrp = personagem:FindFirstChild("HumanoidRootPart") -- HumanoidRootPart é o centro do corpo

	return personagem, humanoid, hrp
end

--=====================================================
-- FUNÇÃO 2: Procurar a Pumpkin mais próxima no Workspace
-- Funciona se a Pumpkin for uma Part ou um Model com Part dentro
--=====================================================
local function EncontrarPumpkinMaisProxima()
	local _, _, hrp = PegarPersonagem()
	if not hrp then return nil end

	local melhor = nil -- vai guardar a Pumpkin mais próxima
	local menorDistancia = math.huge -- começa com um número gigante

	-- Varre tudo que está no Workspace
	for _, objeto in ipairs(workspace:GetDescendants()) do
		if objeto.Name == "Pumpkin" then -- procura pelo nome exato [Pumpkin]
			local parte = nil

			if objeto:IsA("BasePart") then
				parte = objeto -- se a própria Pumpkin já for uma Part
			else
				parte = objeto:FindFirstChildWhichIsA("BasePart", true) -- se for um Model, pega a Part dentro dele
			end

			if parte then
				local distancia = (parte.Position - hrp.Position).Magnitude -- calcula a distância até mim

				if distancia < menorDistancia then
					menorDistancia = distancia
					melhor = parte -- essa é a mais próxima até agora
				end
			end
		end
	end

	return melhor
end

--=====================================================
-- FUNÇÃO 3: Atacar
-- No seu jogo da foto é o "Ataque Rápido [Z]", então ele aperta Z
--=====================================================
local function Atacar()
	-- Aperta o Z
	VirtualInputManager:SendKeyEvent(Enum.KeyCode.Z, true, game, 1)
	task.wait(0.05)
	-- Solta o Z
	VirtualInputManager:SendKeyEvent(Enum.KeyCode.Z, false, game, 1)

	-- Se você tiver uma ferramenta na mão, descomente a linha abaixo:
	-- local ferramenta = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
	-- if ferramenta then ferramenta:Activate() end
end

--=====================================================
-- FUNÇÃO 4: Loop principal (andar até perto + atacar)
--=====================================================
local function LoopPrincipal()
	if Executando then return end
	Executando = true

	while Ativo do
		local personagem, humanoid, hrp = PegarPersonagem()

		-- SE EU MORRER OU SEM PERSONAGEM = PARA O SCRIPT
		if not humanoid or humanoid.Health <= 0 or not hrp then
			warn("[Pumpkin] Você morreu/sem personagem. Script parado.")
			Ativo = false
			break
		end

		local alvo = EncontrarPumpkinMaisProxima()

		-- SE NÃO ENCONTRAR A PUMPKIN = PARA O SCRIPT
		if not alvo or not alvo.Parent then
			warn("[Pumpkin] Nenhuma Pumpkin encontrada. Script parado.")
			Ativo = false
			break
		end

		local distanciaAtual = (alvo.Position - hrp.Position).Magnitude

		if distanciaAtual > Distancia then
			-- AINDA ESTOU LONGE: ANDAR DE FORMA SUAVE ATÉ FICAR A [Distancia] STUDS
			-- MoveTo faz o personagem andar normalmente (suave, não teleporta)
			local direcao = (alvo.Position - hrp.Position)
			if direcao.Magnitude > 0 then
				direcao = direcao.Unit
			end

			local destino = alvo.Position - (direcao * Distancia) -- ponto que fica exatamente a Distancia studs dela

			humanoid:MoveTo(Vector3.new(destino.X, hrp.Position.Y, destino.Z))
		else
			-- JÁ ESTOU PERTO: OLHAR PARA ELA E ATACAR EM LOOP
			hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(alvo.Position.X, hrp.Position.Y, alvo.Position.Z))
			Atacar()
		end

		task.wait(Delay) -- espera o tempo do Delay antes de repetir
	end

	-- Parar de andar quando desligar/morrer
	local _, humanoid, hrp = PegarPersonagem()
	if humanoid and hrp and humanoid.Health > 0 then
		humanoid:MoveTo(hrp.Position)
	end

	Executando = false
	print("[Pumpkin] Script desligado.")
end

--=====================================================
-- TECLA PARA LIGAR/DESLIGAR
--=====================================================
UserInputService.InputBegan:Connect(function(input, processado)
	if processado then return end -- ignora se já foi processado pelo jogo

	if input.KeyCode == Tecla then
		Ativo = not Ativo -- inverte: false vira true, true vira false

		if Ativo then
			print("[Pumpkin] Ligado! Indo até a Pumpkin mais próxima...")
			task.spawn(LoopPrincipal) -- começa o loop em outra thread, sem travar o jogo
		else
			print("[Pumpkin] Desligado.")
		end
	end
end)

print("[Pumpkin] Script carregado! Aperte " .. tostring(Tecla) .. " para ligar/desligar")
Como funciona cada parte
