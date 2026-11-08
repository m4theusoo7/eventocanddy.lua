-- Serviços do Roblox
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configurações do Farm
local FarmAboboraAtivo = false
local TeclaAtivacao = Enum.KeyCode.E -- Tecla para Ativar/Desativar

-- Função de Auto-Clicker Avançado (Força o dano via Remotes do Blox Fruits)
local function deitarSoco()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local tool = Character:FindFirstChildWhichIsA("Tool")
    
    -- Se não estiver segurando nada, equipa o estilo de luta atual automaticamente
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
    
    -- Ativa a ferramenta visualmente
    if tool then
        tool:Activate()
    end
    
    -- BYPASS DE DANO: Força o envio do hit direto para o servidor do Blox Fruits
    pcall(function()
        local net = ReplicatedStorage:FindFirstChild("Net") or ReplicatedStorage:FindFirstChild("Remotes")
        if net then
            -- Tenta os dois formatos comuns de Remote de ataque do jogo
            local registerAttack = net:FindFirstChild("RegisterAttack") or ReplicatedStorage:FindFirstChild("RegisterAttack")
            local combatClick = net:FindFirstChild("打") or net:FindFirstChild("CombatClick")
            
            if registerAttack then
                registerAttack:FireServer()
            end
            if combatClick then
                combatClick:FireServer()
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
                -- Varre o Workspace procurando as abóboras de evento
                for _, obj in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not FarmAboboraAtivo then break end
                    
                    -- Filtra objetos que tenham "pumpkin" no nome interno
                    if obj:IsA("Model") and string.find(string.lower(obj.Name), "pumpkin") then
                        local rootPart = obj:FindFirstChildWhichIsA("BasePart")
                        
                        -- Loop de ataque na abóbora atual até ela quebrar e sumir do jogo
                        while FarmAboboraAtivo and obj and obj.Parent and rootPart and rootPart.Parent do
                            task.wait(0.05) -- Delay otimizado para registrar o dano e evitar lag de CFrame
                            
                            -- Garante o teletransporte com distância de hitbox calibrada
                            if humanoidRootPart and rootPart then
                                -- Posiciona você um pouco acima e rotaciona o personagem para baixo encarando o alvo
                                humanoidRootPart.CFrame = rootPart.CFrame * CFrame.new(0, 2.2, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                            end
                            
                            -- Desfere o ataque com bypass de dano
                            deitarSoco()
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
            print("=== FARM DE PUMPKIN COM RE-HIT: ATIVADO ===")
        else
            print("=== FARM DE PUMPKIN COM RE-HIT: DESATIVADO ===")
        end
    end
end)
