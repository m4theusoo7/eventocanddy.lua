-- CONFIGURAÇÕES PARA BLOX FRUITS
local NOME_ABOBORA = "Pumpkin" -- Nome padrão usado pelo jogo para as abóboras
local VELOCIDADE_VOAR = 60      -- Velocidade de locomoção entre as ilhas

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser") -- Serviço usado para simular cliques/ataques
local localPlayer = Players.LocalPlayer
local farmAtivo = false

-- 1. FUNÇÃO PARA VOAR ATÉ A ABÓBORA
local function moverPara(destinoCFrame)
	local character = localPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end
	
	local distancia = (rootPart.Position - destinoCFrame.Position).Magnitude
	local tempo = distancia / VELOCIDADE_VOAR
	
	local tweenInfo = TweenInfo.new(tempo, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = destinoCFrame})
	
	tween:Play()
	tween.Completed:Wait()
end

-- 2. FUNÇÃO QUE FICA CLICANDO/ATACANDO
local function atacar()
	-- Simula um clique na tela para acionar o ataque (M1) da sua fruta/espada equipada
	VirtualUser:CaptureController()
	VirtualUser:ClickButton1(Vector2.new(50, 50)) 
end

-- 3. LOOP PRINCIPAL DO FARM
local function iniciarFarm()
	farmAtivo = true
	print("Auto-Farm de Abóboras com Ataque ATIVADO!")
	
	while farmAtivo do
		local aboboraAchada = false
		
		for _, objeto in pairs(workspace:GetDescendants()) do
			if not farmAtivo then break end
			
			-- Verifica se o nome do objeto contém "Pumpkin"
			if string.find(objeto.Name:lower(), "pumpkin") then
				local parteAlvo = objeto:IsA("BasePart") and objeto or objeto:FindFirstChildWhichIsA("BasePart")
				
				if parteAlvo and parteAlvo.Parent then
					aboboraAchada = true
					
					-- Repete o ataque enquanto a abóbora ainda existir no mapa
					while farmAtivo and parteAlvo and parteAlvo:IsDescendantOf(workspace) do
						-- Posiciona o jogador levemente acima ou na frente da abóbora para o golpe acertar
						moverPara(parteAlvo.CFrame * CFrame.new(0, 1, 2)) 
						
						atacar()          -- Executa o clique de ataque
						task.wait(0.1)    -- Velocidade do clique (ajuste se estiver rápido/lento demais)
					end
				end
			end
		end
		
		-- Se limpou o mapa ou não achou nenhuma, aguarda o respawn
		if not aboboraAchada then
			task.wait(2)
		end
	end
end

-- 4. CONTROLE PELO CHAT (!farm para ligar/desligar e !stop para parar)
localPlayer.Chatted:Connect(function(mensagem)
	if mensagem:lower() == "!farm" then
		if not farmAtivo then 
			task.spawn(iniciarFarm) 
		else 
			farmAtivo = false 
			print("Auto-Farm DESATIVADO!")
		end
	elseif mensagem:lower() == "!stop" then
		farmAtivo = false
		print("Auto-Farm PARADO!")
	end
end)
