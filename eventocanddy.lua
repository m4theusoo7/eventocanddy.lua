-- Configurações básicas do farm
local LocalPlayer = game:GetService("Players").LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local VirtualUser = game:GetService("VirtualUser")

-- Função para garantir que o estilo de luta está equipado para atacar
local function equipWeapon()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local combat = backpack and (backpack:FindFirstChild("Combat") or backpack:FindFirstChild("Combate"))
    
    if combat then
        combat.Parent = Character
    end
end

-- Função para simular o clique do mouse e atacar
local function attack()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(0, 0))
end

-- Loop principal do Farm
local function farmPumpkins()
    while true do
        task.wait(0.1) -- Evita travamentos no jogo
        
        -- Atualiza o personagem caso ele morra ou mude de mapa
        Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
        
        if humanoidRootPart then
            -- Procura por abóboras no Workspace
            for _, object in pairs(game:GetService("Workspace"):GetDescendants()) do
                -- Verifica se o nome do objeto contém "pumpkin" e se ele ainda existe
                if object:IsA("Model") and string.find(string.lower(object.Name), "pumpkin") then
                    local targetPart = object:FindFirstChildWhichIsA("BasePart")
                    
                    if targetPart then
                        -- Loop de ataque: continua enquanto a abóbora existir e estiver no mapa
                        while object and object.Parent and targetPart.Parent do
                            task.wait(0.05) -- Frequência de atualização e ataque
                            
                            -- Garante o teletransporte contínuo colado na abóbora
                            if humanoidRootPart and targetPart then
                                humanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 3, 0) -- Fica ligeiramente acima dela
                            end
                            
                            -- Ataca a abóbora
                            equipWeapon()
                            attack()
                        end
                    end
                end
            end
        end
    end
end

-- Inicia o script em uma nova thread paralela
spawn(farmPumpkins)
