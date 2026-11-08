-- Serviços do Roblox
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configurações
local FarmAboboraAtivo = false
local TeclaAtivacao = Enum.KeyCode.E
local VelocidadeTween = 350 -- Velocidade segura igual farm de baús

-- Função para anular a gravidade e mover sem bugar ou prender no cenário
local function teleportarPara(posicaoAlvo)
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not humanoidRootPart or not humanoid then return end

    -- Desativa a física de queda temporariamente para não bugar o Tween
    local originalPlatform = humanoid.PlatformStand
    humanoid.PlatformStand = true
    
    local antigoAnchored = humanoidRootPart.Anchored
    
    -- Calcula tempo baseado na distância
    local distancia = (humanoidRootPart.Position - posicaoAlvo.p).Magnitude
    local tempo = distancia / VelocidadeTween
    
    -- Executa o movimento suave até o item
    local tweenInfo = TweenInfo.new(tempo, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = posicaoAlvo})
    tween:Play()
    tween.Completed:Wait()
    
    -- Restaura o estado normal do personagem ao chegar
    humanoid.PlatformStand = originalPlatform
end

-- Função de Ataque com Hitbox Físico Real (Evita o bug de não dar dano)
local function baterNaAbobora()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local tool = Character:FindFirstChildWhichIsA("Tool")
    
    -- Auto-Equip garantido do Estilo de Luta (Melee)
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
    
    -- Força a ativação física do soco para criar o hitbox de dano no bloco
    if tool then
        tool:Activate()
    end
end

-- Loop Principal do Farm de Abóboras do Chão
task.spawn(function()
    while true do
        task.wait(0.2)
        
        if FarmAboboraAtivo then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                -- Varre o Workspace procurando as abóboras
                for _, obj in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not FarmAboboraAtivo then break end
                    
                    if obj:IsA("Model") and string.find(string.lower(obj.Name), "pumpkin") then
                        local rootPart = obj:FindFirstChildWhichIsA("BasePart")
                        
                        if rootPart and rootPart.Parent then
                            -- Define a posição grudada na abóbora
                            local alvo = rootPart.CFrame * CFrame.new(0, 1.2, 0)
                            
                            -- Move até ela sem bugar no ar
                            teleportarPara(alvo)
                            
                            -- Ataca continuamente enquanto o objeto físico existir no mapa
                            while FarmAboboraAtivo and obj and obj.Parent and rootPart and rootPart.Parent do
                                task.wait(0.05) -- Velocidade rápida de socos
                                
                                -- Trava a posição em cima do item enquanto bate para não ser empurrado
                                if humanoidRootPart and rootPart then
                                    humanoidRootPart.CFrame = rootPart.CFrame * CFrame.new(0, 1.2, 0)
                                end
                                
                                baterNaAbobora()
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Ativador por tecla (E)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == TeclaAtivacao then
        FarmAboboraAtivo = not FarmAboboraAtivo
        if FarmAboboraAtivo then
            print("=== FARM ATIVADO ===")
        else
            print("=== FARM DESATIVADO ===")
            -- Garante que se o farm desligar, o personagem volta a andar normal
            local humanoid = Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.PlatformStand = false end
        end
    end
end)
