-- =====================================================================
-- EXPERT PRODUCTION CODE: HIGH-PERFORMANCE PUMPKIN FARM (SEA 1)
-- =====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configurações de Estado
_G.FarmAboboraDefinitivo = false
local TeclaToggle = Enum.KeyCode.E
local VelocidadeVoo = 350

-- [RESOLUÇÃO DO ERRO NIL]: Busca e valida dinamicamente os remotes sem chutar nomes falsos
local NetFolder = ReplicatedStorage:FindFirstChild("Net") or ReplicatedStorage:FindFirstChild("Remotes")
local AttackRemote = nil

if NetFolder then
    -- Procura pelos gatilhos reais de combate ativos na sessão
    for _, child in pairs(NetFolder:GetChildren()) do
        if child:IsA("RemoteEvent") and (string.find(child.Name, "Attack") or string.find(child.Name, "Click") or child.Name == "打") then
            AttackRemote = child
            break
        end
    end
end

-- Se a pasta padrão falhar, busca na raiz do ReplicatedStorage
if not AttackRemote then
    AttackRemote = ReplicatedStorage:FindFirstChild("RegisterAttack") or ReplicatedStorage:FindFirstChild("CombatClick")
end

-- [FAST ATTACK TOTALMENTE SEGURO CONTRA NIL]
local function executarAtaqueServidor()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local tool = Character:FindFirstChildWhichIsA("Tool")
    
    -- Auto-Equip do estilo de luta (Melee)
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

    -- Ativação física local (Gera o Hitbox do braço)
    if tool then 
        tool:Activate() 
    end

    -- Dispara o remote usando o método correto do Roblox (:FireServer) envolto em pcall protetor
    if AttackRemote and AttackRemote:IsA("RemoteEvent") then
        pcall(function()
            AttackRemote:FireServer()
        end)
    end
end

-- [SISTEMA DE CFRAME FLUIDO]: Voa até o destino sem desviar ou bugar a física
local function viajarFisicaLimpa(cframeAlvo)
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    humanid.PlatformStand = true -- Desativa gravidade nativa do jogo
    
    while _G.FarmAboboraDefinitivo and (hrp.Position - cframeAlvo.p).Magnitude > 4 do
        task.wait()
        local direcao = (cframeAlvo.p - hrp.Position).Unit
        hrp.Velocity = Vector3.new(0, 0, 0) -- Força vetor zero para evitar lag de queda
        hrp.CFrame = hrp.CFrame + (direcao * (VelocidadeVoo * task.wait()))
    end
    
    if _G.FarmAboboraDefinitivo then
        hrp.CFrame = cframeAlvo
    end
end

-- [LOOP CRÍTICO DE GRIND DE ABÓBORAS]
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if _G.FarmAboboraDefinitivo then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                for _, obj in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not _G.FarmAboboraDefinitivo then break end
                    
                    -- Localiza objetos físicos válidos do evento que contenham Pumpkin
                    if obj:IsA("BasePart") and string.find(string.lower(obj.Name), "pumpkin") then
                        -- Ignora malhas parciais ou invisíveis para focar na colisão principal
                        if obj.CanCollide == false and obj.Size.Magnitude < 1 then 
                            continue 
                        end
                        
                        -- Alinha o personagem virado para baixo exatamente em cima do hitbox
                        local pontoExato = obj.CFrame * CFrame.new(0, 1.6, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                        
                        -- Executa o movimento frame por frame
                        viajarFisicaLimpa(pontoExato)
                        
                        -- Bate continuamente até que a abóbora suma do jogo
                        while _G.FarmAboboraDefinitivo and obj and obj.Parent do
                            task.wait(0.02)
                            
                            if hrp and obj then
                                hrp.CFrame = obj.CFrame * CFrame.new(0, 1.6, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                            end
                            
                            executarAtaqueServidor()
                        end
                    end
                end
            end
        end
    end
end)

-- Captura de ativador por tecla (E) com limpeza física completa ao desligar
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TeclaToggle then
        _G.FarmAboboraDefinitivo = not _G.FarmAboboraDefinitivo
        print("[!] COORDENADOR INTERNO - Farm Geral:", _G.FarmAboboraDefinitivo and "ATIVADO" or "DESATIVADO")
        
        if not _G.FarmAboboraDefinitivo then
            Character = LocalPlayer.Character
            local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if humanoid then 
                humanoid.PlatformStand = false 
            end
        end
    end
end)
