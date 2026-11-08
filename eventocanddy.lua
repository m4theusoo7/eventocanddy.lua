-- Serviços do Roblox
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configurações do Farm
local FarmAboboraAtivo = false
local TeclaAtivacao = Enum.KeyCode.E
local VelocidadeTween = 350 -- Velocidade idêntica ao farm de baús seguro

-- Função para calcular e executar o Teletransporte (Igual ao Farm de Baús)
local function teleportarPara(pos)
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local distancia = (humanoidRootPart.Position - pos.p).Magnitude
    local tempo = distancia / VelocidadeTween
    
    local tweenInfo = TweenInfo.new(tempo, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = pos})
    tween:Play()
    tween.Completed:Wait()
end

-- Função de Ataque Avançada (Bypass definitivo de dano do Blox Fruits)
local function causarDanoReal()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local tool = Character:FindFirstChildWhichIsA("Tool")
    
    -- Auto-Equip do estilo de luta
    if not tool then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item.ToolTip == "Melee" or item.Name == "Combat" or item.Name == "Combate") then
                item.Parent = Character
                tool = item
                break
            end
        end
    end
    
    if tool then
        tool:Activate()
    end
    
    -- Dispara os remotes de validação de hit obrigatórios do jogo
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Net") or ReplicatedStorage:FindFirstChild("Remotes")
        if net then
            local registerAttack = net:FindFirstChild("RegisterAttack") or ReplicatedStorage:FindFirstChild("RegisterAttack")
            local verifyBlank = net:FindFirstChild("VerifyBlank") or ReplicatedStorage:FindFirstChild("VerifyBlank")
            
            if registerAttack then
                registerAttack:FireServer()
            end
            if verifyBlank then
                -- O VerifyBlank valida o clique vazio próximo ao hitbox
                verifyBlank:FireServer()
            end
        end
    end)
end

-- Loop Principal do Farm de Abóboras do Chão
task.spawn(function()
    while true do
        task.wait(0.1)
        
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
                            -- Calcula a posição exata (Fica colado igual ao farm de baús)
                            local posicaoAlvo = rootPart.CFrame * CFrame.new(0, 1.5, 0)
                            
                            -- Executa o Tween até o destino
                            teleportarPara(posicaoAlvo)
                            
                            -- Loop focado em quebrar o item com re-hit rápido quando chega perto
                            while FarmAboboraAtivo and obj and obj.Parent and rootPart and rootPart.Parent do
                                task.wait(0.02) -- Velocidade máxima de cliques por segundo
                                
                                -- Mantém o personagem grudado enquanto bate
                                if humanoidRootPart and rootPart then
                                    humanoidRootPart.CFrame = rootPart.CFrame * CFrame.new(0, 1.5, 0)
                                end
                                
                                causarDanoReal()
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Ativador por tecla
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == TeclaAtivacao then
        FarmAboboraAtivo = not FarmAboboraAtivo
        if FarmAboboraAtivo then
            print("=== FARM TWEEN PUMPKIN: ATIVADO ===")
        else
            print("=== FARM TWEEN PUMPKIN: DESATIVADO ===")
        end
    end
end)
