--[[
    ======================================================
    BLOX FRUITS FARM SCRIPT - JACK O' LANTERN BOT
    Executor: Delta v2.745 (Compatível com API moderna)
    Função: Busca global por "Jack O' Lantern", move o jogador, 
            e causa dano contínuo até que o item desapareça.
    ======================================================
]]

-- CONFIGURAÇÕES DO SCRIPT
local TARGET_NAME = "Jack O' Lantern" -- Nome exato do item no Workspace
local DAMAGE_AMOUNT = 25          -- Quantidade de dano a ser aplicado por ciclo (ajuste conforme necessário)
local MOVE_TOLERANCE = 3           -- Distância máxima em studs para considerar que o jogador chegou ao alvo
local FARMING_INTERVAL = 0.1       -- Tempo de espera entre cada aplicação de dano (em segundos)

-- REFERÊNCIAS DO JOGO
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- VARIÁVEIS DE ESTADO
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local TargetPart = nil -- Armazena a referência da parte alvo atual

print("✅ [JackOLantern Farm Bot] Inicializado com sucesso!")


-------------------------------------------------------------------
-- FUNÇÕES AUXILIARES
-------------------------------------------------------------------

-- Função para encontrar o item mais próximo do jogador
local function FindNearestTarget()
    local nearestTarget = nil
    local minDistance = math.huge -- Começa com a distância máxima possível
    local playerPosition = Character:GetPrimaryPartCFrame().Position

    print("🔍 Buscando todos os alvos de '" .. TARGET_NAME .. "' no Workspace...")

    -- Itera sobre todos os filhos do Workspace (onde os itens geralmente estão)
    for _, child in ipairs(Workspace:GetChildren()) do
        -- Verifica se o nome corresponde ao alvo
        if child.Name == TARGET_NAME then
            local targetPart = child -- Assume que o item é uma Part ou Model contendo a Part principal

            -- Se for um modelo, tenta encontrar a parte principal (PrimaryPart)
            local partToMeasure = targetPart:IsA("Model") and targetPart.PrimaryPart or targetPart
            
            if partToMeasure and partToMeasure:IsA("BasePart") then
                local distance = (playerPosition - partToMeasure.Position).Magnitude

                -- Se este alvo for mais próximo que o atual mínimo, ele se torna o novo alvo
                if distance < minDistance then
                    minDistance = distance
                    nearestTarget = targetPart
                end
            end
        end
    end

    return nearestTarget -- Retorna a referência do modelo/parte mais próxima
end


-- Função principal de combate e farm
local function FarmLoop()
    while true do
        -- 1. BUSCA E SELEÇÃO DO ALVO (Garante que sempre pegamos o alvo mais próximo)
        if not TargetPart or not TargetPart:IsDescendantOf(Workspace) then
            TargetPart = FindNearestTarget()

            if not TargetPart then
                print("⚠️ Nenhum item '" .. TARGET_NAME .. "' encontrado no mapa. Aguardando e tentando novamente...")
                task.wait(5) -- Espera 5 segundos antes de tentar buscar outro alvo
                continue -- Volta para o início do loop principal
            end

            -- Se encontramos um novo alvo, informamos a distância inicial
            local distance = (Character:GetPrimaryPartCFrame().Position - TargetPart.PrimaryPart.Position).Magnitude
            print("🎯 Novo Alvo Selecionado! Distância: " .. math.floor(distance) .. " studs.")
        end

        -- 2. MOVIMENTO PARA O ALVO
        local targetPosition = TargetPart.PrimaryPart.Position
        Humanoid:MoveTo(targetPosition)

        -- Espera o personagem se mover para perto do alvo (usamos um pequeno loop de verificação)
        local distanceCheck = (Character:GetPrimaryPartCFrame().Position - targetPosition).Magnitude
        while Humanoid.MoveToFinished == false and distanceCheck > MOVE_TOLERANCE do
            task.wait(0.1) -- Espera 100ms e verifica novamente
            distanceCheck = (Character:GetPrimaryPartCFrame().Position - targetPosition).Magnitude
        end

        -- Se o movimento falhar ou for muito lento, apenas espera um pouco antes de atacar
        if distanceCheck > MOVE_TOLERANCE * 2 then
             print("💨 Movimento demorado. Tentando ataque mesmo à distância.")
        end


        -- 3. APLICAÇÃO DE DANO (O Loop de Farm)
        local targetPartPrimary = TargetPart.PrimaryPart

        if not targetPartPrimary or not targetPartPrimary:FindFirstChildOfClass("Humanoid") then
            print("❌ Erro na referência do alvo ou falta Humanoid! Tentando buscar novamente...")
            TargetPart = nil -- Força a busca de um novo alvo no próximo ciclo
            task.wait(1)
            continue
        end

        -- Loop de combate contínuo enquanto o item existir
        while TargetPart and TargetPart:IsDescendantOf(Workspace) do
            local currentDistance = (Character:GetPrimaryPartCFrame().Position - targetPartPrimary.Position).Magnitude
            
            -- Se estiver muito longe, move novamente para garantir que não perca o alvo
            if currentDistance > MOVE_TOLERANCE * 3 then
                Humanoid:MoveTo(targetPosition)
                task.wait(0.2) -- Espera um pouco mais antes de atacar de novo
            end

            -- Aplica o dano ao Humanoid do item
            local targetHumanoid = targetPartPrimary:FindFirstChildOfClass("Humanoid")
            if targetHumanoid then
                targetHumanoid:TakeDamage(DAMAGE_AMOUNT)
                print("⚔️ Dano aplicado! Total de vida restante: " .. math.floor(targetHumanoid.Health))
            else
                 -- Se o Humanoid sumiu, mas a Part ainda existe (raro), tenta forçar um novo alvo
                 break 
            end

            task.wait(FARMING_INTERVAL) -- Espera antes do próximo ataque
        end

        print("✨ Alvo destruído! Iniciando busca por um novo Jack O' Lantern...")
    end
end


-------------------------------------------------------------------
-- INÍCIO DA EXECUÇÃO DO SCRIPT
-------------------------------------------------------------------

-- Garante que o personagem e o Humanoid estejam prontos antes de começar a farmar.
if Character and Humanoid then
    FarmLoop()
else
    warn("🚨 [JackOLantern Farm Bot] Falha ao encontrar o Personagem ou Humanoid! Aguardando...")
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    task.wait(1)
    FarmLoop() -- Tenta novamente após a espera
end

