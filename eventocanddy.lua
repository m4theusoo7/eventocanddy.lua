task.spawn(function()
    print("Auto-Farm de Candy Carregado!")
    
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local localPlayer = Players.LocalPlayer
    
    _G.FarmAtivo = true

    while _G.FarmAtivo do
        local achouItem = false
        
        for _, obj in pairs(workspace:GetDescendants()) do
            if not _G.FarmAtivo then break end
            
            if string.find(obj.Name:lower(), "pumpkin") or string.find(obj.Name:lower(), "candy") then
                local parte = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                
                if parte and parte.Parent and parte:IsDescendantOf(workspace) then
                    achouItem = true
                    
                    -- Loop para bater na abóbora até ela sumir do mapa
                    while _G.FarmAtivo and parte and parte:IsDescendantOf(workspace) do
                        -- Garante ferramenta equipada
                        local char = localPlayer.Character
                        if char and not char:FindFirstChildWhichIsA("Tool") then
                            local mochila = localPlayer:FindFirstChild("Backpack")
                            local tool = mochila and mochila:FindFirstChildWhichIsA("Tool")
                            if tool then tool.Parent = char end
                        end
                        
                        -- Move o jogador colado no item
                        local root = char and char:FindFirstChild("HumanoidRootPart")
                        if root then
                            local dist = (root.Position - parte.Position).Magnitude
                            local tempo = dist / 70
                            local info = TweenInfo.new(tempo, Enum.EasingStyle.Linear)
                            TweenService:Create(root, info, {CFrame = parte.CFrame * CFrame.new(0, 0.5, 0)}):Play()
                        end
                        
                        -- Simula o ataque M1 de forma direta
                        local ferramenta = char and char:FindFirstChildWhichIsA("Tool")
                        if ferramenta then ferramenta:Activate() end
                        
                        task.wait(0.1)
                    end
                end
            end
        end
        
        if not achouItem then task.wait(2) end
    end
end)
