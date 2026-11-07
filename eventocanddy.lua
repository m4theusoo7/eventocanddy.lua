local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- CONFIGURAÇÃO - TROCA AQUI
local NomeAlvo = "Pumpkin" -- nome exato da abóbora no Explorer
local VelocidadeTP = 200
local Rodando = false -- começa desligado, liga com E

UIS.InputBegan:Connect(function(input, processado)
	if processado then return end
	if input.KeyCode == Enum.KeyCode.E then
		Rodando = not Rodando
		print("Farm Pumpkin:", Rodando)
	end
end)

local function parteDaAbobora(obj)
	if obj:IsA("BasePart") then
		return obj
	elseif obj:IsA("Model") then
		return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

while true do
	task.wait()

	if Rodando then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if root and hum and hum.Health > 0 then
			local ferramenta = char:FindFirstChildOfClass("Tool") -- Combat

			-- 1. VARRE O MAPA TODO
			for _, obj in ipairs(workspace:GetDescendants()) do
				if not Rodando then break end
				if obj.Name == NomeAlvo then
					local parte = parteDaAbobora(obj)

					if parte and parte.Parent then
						-- 2. TELEPORTA ATÉ ELA
						local destino = parte.CFrame + Vector3.new(0, 3, 0)
						local dist = (destino.Position - root.Position).Magnitude
						local tempo = math.max(dist / VelocidadeTP, 0.05)

						local tween = TweenService:Create(root, TweenInfo.new(tempo, Enum.EasingStyle.Linear), {
							CFrame = destino
						})
						tween:Play()
						tween.Completed:Wait()

						-- 3. ATACA ATÉ QUEBRAR
						while obj.Parent and Rodando do
							-- olha para a abóbora
							root.CFrame = CFrame.lookAt(root.Position, parte.Position)

							if ferramenta then
								ferramenta:Activate()
							end

							task.wait(0.12) -- cooldown do M1
						end
					end
				end
			end
		end
	end
end
