-- =====================================================================
-- EXPERT BLOX FRUITS PUMPKIN FARM SOURCE CODE (PRO ARCHITECTURE)
-- =====================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configurações Globais
_G.FarmPumpkins = false
local TeclaToggle = Enum.KeyCode.E
local VelocidadeFarm = 300 -- Velocidade exata calibrada para evitar anti-cheat

-- Cache de Remotes oficiais do Blox Fruits para registrar DANO REAL
local NetRemote = ReplicatedStorage:FindFirstChild("Net") or ReplicatedStorage:FindFirstChild("Remotes")
local AttackRemote = NetRemote and (NetRemote:FindFirstChild("RegisterAttack") or NetRemote:FindFirstChild("CombatClick") or NetRemote:FindFirstChild("打"))

-- [MÉTODO DE TWEEN AVANÇADO]: Evita que o personagem treba, caia ou bugue no cenário
local function ExecutarTweenProfissional(posicaoAlvoCFrame)
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    -- Remove temporariamente o estado de queda e física de gravidade nativa
    local antigoState = humanoid.PlatformStand
    humanoid.PlatformStand = true
    
    -- Cria uma força invisível contra o "balanço" do personagem durante o voo
    local bV = hrp:FindFirstChild("FarmVelocity") or Instance.new("BodyVelocity")
    bV.Name = "FarmVelocity"
    bV.Velocity = Vector3.new(0, 0, 0)
    bV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bV.Parent = hrp

    local distancia = (hrp.Position - posicaoAlvoCFrame.p).Magnitude
    local tempo = distancia / VelocidadeFarm

    local tween = TweenService:Create(hrp, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = posicaoAlvoCFrame})
    tween:Play()
    tween.Completed:Wait() -- Garante a chegada milimétrica antes de começar a bater

    -- Limpa a força ao chegar para evitar travamentos permanentes
    if bV then bV:Destroy() end
    humanoid.PlatformStand = antigoState
end

-- [FAST ATTACK NATIVO]: Ignora ferramentas e força o servidor a computar o dano do soco
local function DispararDanoBypass()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    
    -- Auto-Equip do Estilo de Luta sem quebrar animação
    local tool = Character:FindFirstChildWhichIsA("Tool")
    if not tool then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in pairs(backpack:GetChildren()) do
                if item:IsA("Tool") and (item.ToolTip == "Melee" or item.Name == "Combat" or item.Name == "Combate") then
                    item.Parent = Character
                    tool = item
                    break
                end
            end
        end
    end

    -- Ativa visualmente
    if tool then tool:Activate() end

    -- Bate direto no Servidor usando a assinatura interna do jogo (Evita cliques nulos)
    if AttackRemote then
        pcall(function()
            AttackRemote:FireServer()
        end)
    end
end

-- [LOOP CRÍTICO DE FARM]: Varre e limpa as abóboras
task.spawn(function()
    while true do
        task.wait(0.1)
        
        if _G.FarmPumpkins then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not _G.FarmPumpkins then break end
                    
                    -- Detecção correta do Modelo da abóbora no mapa
                    if v:IsA("Model") and string.find(string.lower(v.Name), "pumpkin") then
                        local partAlvo = v:FindFirstChildWhichIsA("BasePart")
                        
                        if partAlvo and partAlvo.Parent then
                            -- Posição milimétrica: 2 studs acima da abóbora, com a câmera do personagem virada para baixo
                            local cframeSeguro = partAlvo.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                            
                            -- Move até lá usando a física limpa
                            ExecutarTweenProfissional(cframeSeguro)
                            
                            -- Ataca em alta frequência enquanto o objeto existir fisicamente no jogo
                            while _G.FarmPumpkins and v and v.Parent and partAlvo and partAlvo.Parent do
                                task.wait(0.01) -- Velocidade Fast Attack calibrada para não ignorar hitboxes
                                
                                if hrp and partAlvo then
                                    hrp.CFrame = partAlvo.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                                end
                                
                                DispararDanoBypass()
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Gerenciador de ativação via Input seguro
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TeclaToggle then
        _G.FarmPumpkins = not _G.FarmPumpkins
        print("[!] SCRIPT EXPERT - Farm de Abóboras:", _G.FarmPumpkins and "LIGADO" or "DESLIGADO")
        
        -- Garante restauração da física em caso de desligamento manual abrupto
        if not _G.FarmPumpkins then
            Character = LocalPlayer.Character
            local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
            if humanoid then humanoid.PlatformStand = false end
            if hrp and hrp:FindFirstChild("FarmVelocity") then hrp.FarmVelocity:Destroy() end
        end
    end
end)
