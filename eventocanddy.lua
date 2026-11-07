local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player.Character:FindFirstChild("HumanoidRootPart").Parent:WaitForChild("HumanoidRootPart"):FindFirstChild("HumanoidRootPart") -- Correção para encontrar a raiz do personagem

-- Configurações
local TargetName = "Pumpkin" -- Nome do objeto (pode ser Pumpkin, Pumpkin_01, etc.)
local Range = 25 -- Distância máxima para detectar a abóbora
local Speed = 16 -- Velocidade de movimento (quanto maior, mais rápido)

-- Função principal
local function FindAndInteract()
    local Character = Player.Character or Player.CharacterAdded:Wait()
    
    -- Espera o personagem ter uma raiz (HumanoidRootPart)
    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    if not RootPart then return end

    -- Procura objetos com "Pumpkin" no nome na área ao redor
    local Target = nil
    
    for _, obj in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if string.find(obj.Name, TargetName) and obj:IsA("Model") or obj:IsA("Part") then
            -- Verifica se está dentro da distância
            if RootPart:DistanceTo(obj.Position) <= Range then
                Target = obj
                break
            end
        end
    end

    if Target then
        print("[Auto-Pumpkin] Encontrado! Movendo para a posição...")
        
        -- Move o personagem até o objeto
        local function MoveTowards()
            if not RootPart or not Target then return end
            
            local CurrentPos = RootPart.Position
            local TargetPos = Target.PrimaryPart and Target.PrimaryPart.Position or Target.Position
            
            if (CurrentPos - TargetPos).Magnitude < 5 then
                print("[Auto-Pumpkin] Chegou perto! Interagindo...")
                
                -- Tenta clicar no objeto para quebrar/interagir
                local Clicked = Mouse:FireAtTarget(Target)
                if Clicked then
                    print("[Auto-Pumpkin] Quebrado!")
                end
                
                -- Pequeno delay antes de procurar outra
                task.wait(2)
            else
                RootPart.CFrame = CFrame.new(CurrentPos + (TargetPos - CurrentPos).Unit * 5, CurrentPos.Y) -- Move um pouco para frente
                task.wait(0.1)
            end
            
            -- Loop contínuo
            if Target then
                task.delay(0.1, MoveTowards)
            else
                FindAndInteract() -- Tenta encontrar outra abóbora se esta for quebrada
            end
        end
        
        MoveTowards()
    else
        print("[Auto-Pumpkin] Procurando...")
        task.wait(1)
        FindAndInteract()
    end
end

-- Inicia o script
task.delay(2, FindAndInteract)
