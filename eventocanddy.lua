-- Configurações e Serviços
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Variável de estado do Farm (Começa DESATIVADO)
local FarmJackAtivo = false
local TeclaAtivacao = Enum.KeyCode.P -- Pressione P para ligar/desligar

-- Função de Auto-Clicker Nativo
local function atacar()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local tool = Character:FindFirstChildWhichIsA("Tool")
    
    -- Se não estiver segurando o estilo de luta, equipa automaticamente
    if not tool then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local combat = backpack and (backpack:FindFirstChild("Combat") or backpack:FindFirstChild("Combate"))
        if combat then
            combat.Parent = Character
            tool = combat
        end
    end
    
    -- Ataca
    if tool then
        tool:Activate()
    end
end

-- Função para desativar o dano por queda ou empurrão durante o farm
local function estabilizarPersonagem(hrp)
    if hrp and hrp:FindFirstChild("BodyVelocity") == nil then
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Parent = hrp
    end
end

-- Loop Principal de Farm do Boss Jack O' Lantern
task.spawn(function()
    while true do
        task.wait(0.1)
        
        if FarmJackAtivo then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                estabilizarPersonagem(humanoidRootPart)
                
                -- Procura pelo Boss no Workspace (verifica na pasta de Inimigos ou Workspace geral)
                for _, npc in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not FarmJackAtivo then break end
                    
                    -- Verifica se o nome do NPC é Jack O' Lantern ou Dapper Jack
                    if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 and 
                       (string.find(string.lower(npc.Name), "jack") or string.find(string.lower(npc.Name), "lantern")) then
                        
                        local npcHrp = npc:FindFirstChild("HumanoidRootPart")
                        
                        -- Loop de ataque focado no Boss até ele morrer ou o farm ser desligado
                        while FarmJackAtivo and npc and npc.Parent and npc.Humanoid.Health > 0 and npcHrp do
                            task.wait(0.02) -- Velocidade de clique rápida
                            
                            -- Teletransporte seguro: Mantém você 4 studs ACIMA do Boss para ele não te acertar
                            if humanoidRootPart and npcHrp then
                                humanoidRootPart.CFrame = npcHrp.CFrame * CFrame.new(0, 4, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                            end
                            
                            -- Desfere os golpes
                            atacar()
                        end
                    end
                end
            end
        end
    end
end)

-- Sistema Liga/Desliga
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == TeclaAtivacao then
        FarmJackAtivo = not FarmJackAtivo
        if FarmJackAtivo then
            print("=== FARM DO BOSS JACK O' LANTERN: ATIVADO ===")
        else
            print("=== FARM DO BOSS JACK O' LANTERN: DESATIVADO ===")
            -- Remove a estabilização para o personagem andar normal
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp:FindFirstChild("BodyVelocity") then
                hrp.BodyVelocity:Destroy()
            end
        end
    end
end)
