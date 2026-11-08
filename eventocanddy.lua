-- =====================================================================
-- SCRIPT CORRIGIDO: AUTO FARM PUMPKIN (SEA 1 - DANO REAL)
-- =====================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Variáveis de Controle
_G.FarmPumpkinsSea1 = false
local TeclaToggle = Enum.KeyCode.E
local VelocidadeVoo = 350

-- Localização dos Remotes Oficiais de Validação de Hit do Blox Fruits
local Net = ReplicatedStorage:FindFirstChild("Net") or ReplicatedStorage:FindFirstChild("Remotes")
local AttackRemote = Net and (Net:FindFirstChild("RegisterAttack") or Net:FindFirstChild("CombatClick"))
local VerifyRemote = Net and (Net:FindFirstChild("VerifyBlank") or Net:FindFirstChild("VerifyDamage"))

-- Função de Ataque Corrigida (Força o Hitbox Físico e valida no Servidor)
local function computarDanoReal()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local tool = Character:FindFirstChildWhichIsA("Tool")
    
    -- Auto-Equip do Estilo de Luta
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

    -- 1. Ativa a ferramenta localmente para abrir o Hitbox
    if tool then 
        tool:Activate() 
    end

    -- 2. Dispara a assinatura dupla necessária para o servidor aceitar o dano em objetos estáticos
    pcall(function()
        if AttackRemote then 
            AttackRemote:FireServer() 
        end
        if VerifyRemote then 
            -- Passa uma tabela vazia e o soco para validar o hit de colisão
            VerifyRemote:FireServer(tool, "RightClick") 
        end
    end)
end

-- Função de Movimentação Direta (Igual aos scripts de baú de alto desempenho)
local function moverAteAbobora(posAlvo)
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = Character:FindFirstChild("HumanoidRootPart")
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    -- Corta a física de queda para não bugar entre as ilhas do Sea 1
    humanoid.PlatformStand = true
    
    -- Loop de deslocamento direto de CFrame por frame (Substitui o Tween bugado)
    while _G.FarmPumpkinsSea1 and (hrp.Position - posAlvo.p).Magnitude > 5 do
        task.wait()
        local direcao = (posAlvo.p - hrp.Position).Unit
        hrp.Velocity = Vector3.new(0,0,0) -- Zera a gravidade do Roblox
        hrp.CFrame = hrp.CFrame + (direcao * (VelocidadeVoo * task.wait()))
    end
    
    -- Trava exatamente na posição final voltado para o item
    if _G.FarmPumpkinsSea1 then
        hrp.CFrame = posAlvo
    end
end

-- Loop de Varredura do Sea 1
task.spawn(function()
    while true do
        task.wait(0.5)
        
        if _G.FarmPumpkinsSea1 then
            Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                for _, obj in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if not _G.FarmPumpkinsSea1 then break end
                    
                    -- Filtra o modelo exato da abóbora
                    if obj:IsA("Model") and string.find(string.lower(obj.Name), "pumpkin") then
                        local partFisica = obj:FindFirstChildWhichIsA("BasePart")
                        
                        if partFisica and partFisica.Parent then
                            -- Posição calibrada: 1.5 studs acima e rotacionando a câmera do boneco para baixo encarando o alvo
                            local localAlvo = partFisica.CFrame * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                            
                            -- Executa a movimentação limpa
                            moverAteAbobora(localAlvo)
                            
                            -- Loop de Fast Attack: Bate até o objeto físico sumir do Workspace
                            while _G.FarmPumpkinsSea1 and obj and obj.Parent and partFisica and partFisica.Parent do
                                task.wait(0.02) -- Frequência ideal para o servidor processar a quebra
                                
                                if hrp and partFisica then
                                    hrp.CFrame = partFisica.CFrame * CFrame.new(0, 1.5, 0) * CFrame.Angles(math.rad(-90), 0, 0)
                                end
                                
                                computarDanoReal()
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Ativador (Tecla E)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == TeclaToggle then
        _G.FarmPumpkinsSea1 = not _G.FarmPumpkinsSea1
        print("[!] STATUS DO FARM:", _G.FarmPumpkinsSea1 and "ATIVADO" or "DESATIVADO")
        
        -- Restaura o boneco quando o farm é desligado
        if not _G.FarmPumpkinsSea1 then
            Character = LocalPlayer.Character
            local humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if humanoid then 
                humanoid.PlatformStand = false 
            end
        end
    end
end)
