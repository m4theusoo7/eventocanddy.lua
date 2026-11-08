--[[
    ======================================================
    FRUIT FARM BOT - Blox Fruits Lua Script
    Executor: Delta v2.745 (Compatível Luau)
    Objetivo: Coletar automaticamente frutas (itens laranja/vermelhos) do chão próximo ao jogador.
    Autor: [Seu Nome / IA Expert]
    ======================================================
]]

-- 1. Referências Essenciais
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Pega o jogador local (o usuário que está executando o script)
local LocalPlayer = Players.LocalPlayer

-- Verifica se o jogador existe antes de continuar
if not LocalPlayer then
    warn("[FRUIT FARM BOT] Erro: Jogador não encontrado no Workspace!")
    return -- Para a execução do script se o jogador não estiver carregado
end

-- Pega o Character (o modelo do personagem)
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Pega a parte principal do personagem (HumanoidRootPart - onde a física está ancorada)
local RootPart = Character:FindFirstChild("HumanoidRootPart")

if not RootPart then
    warn("[FRUIT FARM BOT] Erro: HumanoidRootPart não encontrado no personagem!")
    return
end

-- 2. Configurações do Farm Bot
local MAX_DISTANCE = 10 -- Distância máxima (em studs) para o script procurar itens. Ajuste se necessário.
local CHECK_INTERVAL = 0.1 -- Intervalo de checagem em segundos (quanto menor, mais rápido e mais CPU consome).

-- Função principal que realiza a coleta do item
local function CollectItem(itemPart: BasePart)
    -- Verifica se o item já está anexado ou é parte do próprio personagem
    if itemPart.Parent == Character or itemPart.Name == "HumanoidRootPart" then
        return false -- Não precisa coletar, ele já está em algum lugar
    end

    print(`[FRUIT FARM BOT] Item encontrado! Coletando...`)

    -- 1. Anexa o item ao personagem (Parenting)
    itemPart.Parent = Character

    -- 2. Posiciona o item na mão do jogador ou ligeiramente à frente dele
    local targetCFrame = RootPart.CFrame * CFrame.new(0, 0, -3) -- Posição: 3 studs à frente do centro do personagem
    itemPart:SetPrimaryPartCFrame(targetCFrame)

    -- Opcional: Se o item for um modelo complexo (e não apenas uma Part), você deve usar SetPrimaryPartCFrame no MODELO.
    -- Exemplo: local ItemModel = itemPart.Parent; ItemModel:SetPrimaryPartCFrame(targetCFrame)

    return true -- Coleta bem-sucedida
end


-- 3. Loop Principal de Farming (Execução Contínua)
print("=============================================")
print("[FRUIT FARM BOT] Iniciado! Procurando frutas no chão...")
print(`[FRUIT FARM BOT] Distância Máxima: {MAX_DISTANCE} studs | Intervalo: {CHECK_INTERVAL}s`)
print("=============================================")

while task.wait(CHECK_INTERVAL) do
    local bestTarget = nil
    local shortestDistance = MAX_DISTANCE + 1 -- Começa com uma distância maior que o máximo permitido

    -- Itera sobre todos os objetos no Workspace (pode ser otimizado, mas é robusto)
    for _, object in ipairs(Workspace:GetChildren()) do
        -- Verifica se o objeto é um modelo ou parte e tem a propriedade de nome "Fruit"
        if object:IsA("BasePart") and object.Name == "Fruit" then
            local part = object :: BasePart

            -- Calcula a distância entre o RootPart do jogador e este item
            local distance = (RootPart.Position - part.Position).Magnitude

            -- Verifica se está dentro da área de busca E se é mais próximo que o alvo atual
            if distance <= MAX_DISTANCE and distance < shortestDistance then
                bestTarget = part
                shortestDistance = distance
            end
        elseif object:IsA("Model") and object.Name == "Fruit" then
             -- Se for um modelo, pegamos a parte principal (PrimaryPart) dele para cálculo de distância
            local primaryPart = object.PrimaryPart
            if primaryPart then
                local distance = (RootPart.Position - primaryPart.Position).Magnitude

                if distance <= MAX_DISTANCE and distance < shortestDistance then
                    bestTarget = object -- Armazena o modelo inteiro
                    shortestDistance = distance
                end
            end
        end
    end

    -- Se um alvo foi encontrado, coleta ele!
    if bestTarget then
        local success = CollectItem(bestTarget)
        
        -- Opcional: Adicionar uma pequena pausa após a coleta para evitar spam de coleta no mesmo frame.
        if success then
            task.wait(0.05) 
        end
    end

end -- Fim do loop while
