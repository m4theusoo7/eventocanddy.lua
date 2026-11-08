-- Serviços Básicos do Roblox
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Configurações
local FarmAboboraAtivo = false
local TeclaAtivacao = Enum.KeyCode.E
local VelocidadeTween = 250 -- Velocidade controlada para o Tween terminar sem erros

-- Função de clique simulado na tela (Auto-Clicker direto que funciona com ferramenta)
local function clicarNaTela()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton1(Vector2.new(0, 0))
end

-- Função para equipar o estilo de luta automaticamente
local function equiparEstilo()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    if not Character:FindFirstChildWhichIsA("Tool") then
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in pairs(backpack:GetChildren()) do
                if item:IsA("Tool") and (item.ToolTip == "Melee" or item.Name == "Combat" or item.Name == "Combate") then
                    item.Parent = Character
                    break
                end
            end
        end
    end
end

-- Loop Principal do Farm
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if FarmAboboraAtivo then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                -- Busca as abóboras no Workspace
                for _, obj in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not FarmAboboraAtivo then break end
                    
                    if obj:IsA("Model") and string.find(string.lower(obj.Name), "pumpkin") then
                        local rootPart = obj:FindFirstChildWhichIsA("BasePart")
                        
                        if rootPart and rootPart.Parent then
                            -- 1. Calcula e executa o Tween até o destino
                            local alvoCFrame = rootPart.CFrame * CFrame.new(0, 2, 0)
                            local distancia = (humanoidRootPart.Position - alvoCFrame.p).Magnitude
                            local tempo = distancia / VelocidadeTween
                            
                            local tween = TweenService:Create(humanoidRootPart, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {CFrame = alvoCFrame})
                            tween:Play()
                            tween.Completed:Wait() -- Espera o teletransporte CHEGAR totalmente
                            
                            -- 2. Chegou? Ancora o personagem para a física do jogo não puxar ele para baixo
                            humanoidRootPart.Anchored = true
                            
                            -- 3. Ataca continuamente até a abóbora sumir do jogo
                            while FarmAboboraAtivo and obj and obj.Parent and rootPart and rootPart.Parent do
                                task.wait(0.05) -- Delay dos socos
                                
                                -- Mantém o CFrame cravado na abóbora
                                humanoidRootPart.CFrame = rootPart.CFrame * CFrame.new(0, 2, 0)
                                
                                equiparEstilo()
                                clicarNaTela()
                            end
                            
                            -- 4. A abóbora sumiu? Desancora para poder ir para a próxima
                            humanoidRootPart.Anchored = false
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
        print("Farm de Abóboras:", FarmAboboraAtivo and "ATIVADO" or "DESATIVADO")
        
        -- Garante que se desligar o farm, o personagem não fique travado (ancorado)
        if not FarmAboboraAtivo then
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
        end
    end
end)
