-- Script de Farm de Abóbora (Pumpkin) para Blox Fruits - Delta Executor
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- Configurações
local FARM_ATIVO = true
local VELOCIDADE_VOO = 250 -- studs por segundo

local function getPumpkin()
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name:lower():find("pumpkin") or obj.Name:lower():find("abobora") then
            if obj:IsA("Model") and obj.PrimaryPart then
                return obj.PrimaryPart
            elseif obj:IsA("BasePart") then
                return obj
            end
        end
    end
    return nil
end

task.spawn(function()
    while FARM_ATIVO do
        task.wait(0.5)
        pcall(function()
            local targetPart = getPumpkin()
            if targetPart and HumanoidRootPart then
                -- Calcula o tempo de viagem baseado na distância
                local distancia = (HumanoidRootPart.Position - targetPart.Position).Magnitude
                local tempo = distancia / VELOCIDADE_VOO
                
                local info = TweenInfo.new(tempo, Enum.EasingStyle.Linear)
                local tween = TweenService:Create(HumanoidRootPart, info, {CFrame = targetPart.CFrame + Vector3.new(0, 5, 0)})
                
                tween:Play()
                tween.Completed:Wait()
                
                -- Simula clique/ataque para coletar
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end)
    end
end)
