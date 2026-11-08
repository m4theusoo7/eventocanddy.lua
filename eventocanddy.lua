-- Script Atualizado de Teleporte para Itens / Abóboras - Blox Fruits
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local function encontrarItem()
    -- 1. Varre o Workspace principal e pastas comuns de loot/spawn
    for _, obj in pairs(Workspace:GetChildren()) do
        local nome = obj.Name:lower()
        if nome:find("pumpkin") or nome:find("abobora") or nome:find("candy") or nome:find("chest") or nome:find("item") then
            if obj:IsA("Model") and obj.PrimaryPart then
                return obj.PrimaryPart
            elseif obj:IsA("BasePart") then
                return obj
            end
        end
    end
    
    -- 2. Varre subpastas caso o item esteja dentro de um container de evento
    for _, pasta in pairs(Workspace:GetChildren()) do
        if pasta:IsA("Folder") or pasta:IsA("Model") then
            for _, obj in pairs(pasta:GetChildren()) do
                local nome = obj.Name:lower()
                if nome:find("pumpkin") or nome:find("abobora") or nome:find("candy") then
                    if obj:IsA("Model") and obj.PrimaryPart then
                        return obj.PrimaryPart
                    elseif obj:IsA("BasePart") then
                        return obj
                    end
                end
            end
        end
    end
    
    return nil
end

-- Executa o movimento direto até o item encontrado
task.spawn(function()
    print("Procurando item no mapa...")
    while task.wait(0.5) do
        pcall(function()
            local alvo = encontrarItem()
            if alvo and HumanoidRootPart then
                print("Indo em direção ao item...")
                
                -- Desativa o colisor temporariamente para o Tween não bugar nas paredes
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                
                local distancia = (HumanoidRootPart.Position - alvo.Position).Magnitude
                local velocidade = 300 -- Ajuste a velocidade do voo se precisar
                local tempo = distancia / velocidade
                
                local tweenInfo = TweenInfo.new(tempo, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = alvo.CFrame + Vector3.new(0, 5, 0)})
                
                tween:Play()
                tween.Completed:Wait()
                
                -- Pequena pausa ao chegar para garantir a coleta
                task.wait(0.2)
            end
        end)
    end
end)
