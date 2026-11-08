-- Configurações e Serviços
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Variável de estado do Farm (Começa DESATIVADO)
local FarmAtivo = false
local TeclaAtivacao = Enum.KeyCode.E -- Mude aqui se quiser outra tecla

-- Função para equipar a arma e atacar diretamente pelo código
local function atacarAbobora()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local tool = Character:FindFirstChildWhichIsA("Tool")
    
    -- Se não estiver segurando nada, procura na Mochila e equipa
    if not tool then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local combat = backpack and (backpack:FindFirstChild("Combat") or backpack:FindFirstChild("Combate"))
        if combat then
            combat.Parent = Character
            tool = combat
        end
    end
    
    -- Dispara o ataque nativo do estilo de luta (Auto-Clicker real)
    if tool then
        tool:Activate()
    end
end

-- Loop principal do Farm
task.spawn(function()
    while true do
        task.wait(0.1)
        
        if FarmAtivo then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                -- Varre o Workspace procurando as abóboras
                for _, object in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not FarmAtivo then break end -- Para o loop imediatamente se desligar
                    
                    if object:IsA("Model") and string.find(string.lower(object.Name), "pumpkin") then
                        local targetPart = object:FindFirstChildWhichIsA("BasePart")
                        
                        if targetPart then
                            -- Loop de ataque enquanto a abóbora existir e o farm estiver ligado
                            while FarmAtivo and object and object.Parent and targetPart.Parent do
                                task.wait(0.05) -- Velocidade do clique e ajuste de posição
                                
                                -- Teletransporta e cola na abóbora (posição ajustada um pouco para o lado/cima para acertar o hitbox)
                                if humanoidRootPart and targetPart then
                                    humanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 1.5, 0)
                                end
                                
                                -- Executa o ataque direto
                                atacarAbobora()
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Sistema de Liga / Desliga por Tecla
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end -- Ignora se você estiver digitando no chat
    
    if input.KeyCode == TeclaAtivacao then
        FarmAtivo = not FarmAtivo
        if FarmAtivo then
            print("=== FARM DE ABÓBORA: ATIVADO ===")
        else
            print("=== FARM DE ABÓBORA: DESATIVADO ===")
        end
    end
end)
