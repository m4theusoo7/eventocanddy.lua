-- Serviços do Roblox
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configurações do Farm
local FarmAboboraAtivo = false
local TeclaAtivacao = Enum.KeyCode.E -- Tecla para Ativar/Desativar

-- Função de Auto-Clicker Nativo (Ataca direto na ferramenta)
local function deitarSoco()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local tool = Character:FindFirstChildWhichIsA("Tool")
    
    -- Se não estiver segurando nada, pega o estilo de luta na Mochila
    if not tool then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local combat = backpack and (backpack:FindFirstChild("Combat") or backpack:FindFirstChild("Combate"))
        if combat then
            combat.Parent = Character
            tool = combat
        end
    end
    
    -- Ativa o ataque da ferramenta
    if tool then
        tool:Activate()
    end
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
                            task.wait(0.03) -- Velocidade rápida de posicionamento e soco
                            
                            -- Garante o teletransporte colado na abóbora
                            if humanoidRootPart and rootPart then
                                -- Posiciona você um pouco acima dela para garantir que o soco pegue sem bugar no chão
                                humanoidRootPart.CFrame = rootPart.CFrame * CFrame.new(0, 1.8, 0)
                            end
                            
                            -- Desfere o ataque automático
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
            print("=== FARM DE PUMPKIN (CHÃO): ATIVADO ===")
        else
            print("=== FARM DE PUMPKIN (CHÃO): DESATIVADO ===")
        end
    end
end)
