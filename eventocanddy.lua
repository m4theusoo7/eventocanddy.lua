-- =====================================================================
-- SCRIPT CORRIGIDO: DETECÇÃO FÍSICA SEM DEPENDÊNCIA DE MESH (SEA 1)
-- =====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configurações e Estado do Farm
_G.FarmTotalAboboras = false
local TeclaAtivacao = Enum.KeyCode.E
local VelocidadeVoo = 350 -- Velocidade segura para cruzar o mar no Sea 1

-- Identificação dos canais de ataque e confirmação do jogo
local RemotesFolder = ReplicatedStorage:FindFirstChild("Net") or ReplicatedStorage:FindFirstChild("Remotes")
local AttackEvent = RemotesFolder and (RemotesFolder:FindFirstChild("RegisterAttack") or RemotesFolder:FindFirstChild("CombatClick"))

-- Função de Ataque Físico Puro (Ignora erros de malha)
local function socarObjeto()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local tool = Character:FindFirstChildWhichIsA("Tool")
    
    -- Auto-Equip do Melee (Estilo de Luta)
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

    -- Força o soco físico local (Gera o hitbox real do braço do personagem)
    if tool then 
        tool:Activate() 
    end

    -- Envia o pacote redundante para o servidor registrar
    if AttackEvent then
        pcall(function()
            AttackEvent:FireServer()
        end)
    end
end

-- Sistema de Movimentação por CFrame Direto (Evita travar se a Mesh não carregar)
local function viajarAteAlvo(cframeDestino)
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    -- Desativa estados físicos que fazem o boneco tremer ou cair no oceano
    humanoid.PlatformStand = true
    
    -- Move frame por frame anulando a física nativa do Roblox
    while _G.FarmTotalAboboras and (hrp.Position - cframeDestino.p).Magnitude > 4 do
        task.wait()
        local direcao = (cframeDestino.p - hrp.Position).Unit
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.CFrame = hrp.CFrame + (direcao * (VelocidadeVoo * task.wait()))
    end
    
    -- Garante posicionamento cravado ao chegar
    if _G.FarmTotalAboboras then
        hrp.CFrame = cframeDestino
    end
end

-- Loop de Varredura Absoluta (Procura de uma em uma pelo Sea 1)
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if _G.FarmTotalAboboras then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                -- Varre o mapa ignorando modelos quebrados e focando em BaseParts ativas
                for _, item do map em pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not _G.FarmTotalAboboras then break end
                    
                    -- Filtra apenas itens físicos que contenham "pumpkin" no nome
                    if item:IsA("BasePart") and string.find(string.lower(item.Name), "pumpkin") then
                        -- Ignora se o objeto for apenas uma textura visual quebrada (Mesh/Beam)
                        if not item:IsA("MeshPart") and item.CanCollide == false and item.Size.Magnitude < 1 then
                            continue
                        end
                        
                        -- Ponto de ataque posicionado ligeiramente acima do centro geométrico do bloco
                        local posicaoSegura = item.CFrame * CFrame.new(0, 1.8, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                        
                        -- Executa a viagem linear estável
                        viajarAteAlvo(posicaoSegura)
                        
                        -- Desfere socos até que o bloco seja coletado/destruído e limpo da memória
                        while _G.FarmTotalAboboras and item and item.Parent do
                            task.wait(0.02) -- Cadência do Fast Attack físico
                            
                            -- Mantém o CFrame colado contra puxões do anti-cheat ou rebotes
                            if hrp and item then
                                hrp.CFrame = item.CFrame * CFrame.new(0, 1.8, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                            end
                            
                            socarObjeto()
                        end
                    end
                end
            end
        end
    end
end)

-- Gerenciador da Tecla E para Ativar/Desativar
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TeclaAtivacao then
        _G.FarmTotalAboboras = not _G.FarmTotalAboboras
        print("[!] COORDENADOR DE FARM - Status:", _G.FarmTotalAboboras and "LIGADO" or "DESLIGADO")
        
        -- Devolve os controles físicos do boneco ao desligar
        if not _G.FarmTotalAboboras then
            Character = LocalPlayer.Character
            local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if humanoid then 
                humanoid.PlatformStand = false 
            end
        end
    end
end)
