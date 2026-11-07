-- CONFIGURAÇÕES ADAPTADAS PARA O SEA 1
local NOME_ABOBORA = "Pumpkin" 
local VELOCIDADE_VOAR = 75     -- Um pouco mais rápido para navegar entre as ilhas do Sea 1

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local localPlayer = Players.LocalPlayer
local farmAtivo = false

-- 1. FUNÇÃO PARA GARANTIR QUE A ARMA ESTÁ NA MÃO
local function equiparArma()
	local character = localPlayer.Character
	if not character then return end
	
	-- Se já tiver algo na mão, não faz nada
	if character:FindFirstChildWhichIsA("Tool") then return end
	
	-- Procura a primeira arma/estilo de luta no seu inventário (Backpack) e equipa
	local mochila = localPlayer:FindFirstChild("Backpack")
	if mochila then
		local ferramenta = mochila:FindFirstChildWhichIsA("Tool")
		if ferramenta then
			ferramenta.Parent = character
		end
	end
end

-- 2. FUNÇÃO DE MOVIMENTO (TWEEN)
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

-- 3. FUNÇÃO QUE EXECUTA O CLIQUE M1
local function atacar()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton1(Vector2.new(50, 50)) 
end

-- 4. LOOP PRINCIPAL DO FARM DO EVENTO
local function iniciarFarm()
	farmAtivo = true
	print("Auto-Farm de Abóboras (Sea 1) ATIVADO!")
	
	while farmAtivo do
		local aboboraAchada = false
		
		for _, objeto in pairs(workspace:GetDescendants()) do
			if not farmAtivo then break end
			
			-- Procura o item no mapa
			if string.find(objeto.Name:lower(), "pumpkin") or string.find(objeto.Name:lower(), "candy") then
				local parteAlvo = objeto:IsA("BasePart") and objeto or objeto:FindFirstChildWhichIsA("BasePart")
				
				if parteAlvo and parteAlvo.Parent then
					aboboraAchada = true
					
					-- Loop de ataque na abóbora atual
					while farmAtivo and parteAlvo and parteAlvo:IsDescendantOf(workspace) do
						equiparArma() -- Garante o soco/espada na mão
						
						-- Teleporta exatamente em cima/colado para o soco Combat alcançar
						moverPara(parteAlvo.CFrame * CFrame.new(0, 0.5, 0)) 
						
						atacar()
						task.wait(0.08) -- Cliques rápidos
					end
				end
			end
		end
		
		-- Se não achar abóboras nas ilhas próximas, espera o servidor carregar novas
		if not aboboraAchada then
			task.wait(3)
		end
	end
end

-- CONTROLE NO CHAT
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
