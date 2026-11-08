--[[
    SCRIPT DE AUTOMAÇÃO PARA FARMING DA ABÓBORA NO BLOX FRUITS
    Instruções: Coloque este script em um LocalScript dentro de StarterPlayerScripts.
]]

-- 1. Variáveis Globais (Configurações)
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer -- Pega o jogador que está rodando o script

-- Configuração do tempo de espera entre os cliques (em segundos). 
-- Um valor menor significa farm mais rápido, mas pode sobrecarregar o jogo.
local TEMPO_DE_ESPERA = 0.5 

-- Nome exato da parte/objeto que representa a abóbora no mapa.
-- Se houver várias abóboras, você precisará ajustar este nome ou usar um loop de busca!
local NOME_DA_ABOBORA = "Pumpkin" -- Assumindo que o objeto se chama "Pumpkin"

print("🤖 Script de Farm da Abóbora Iniciado!")

-- 2. Função Principal (O Loop de Farming)
local function farmarAbobora()
    while true do
        -- Tenta encontrar a abóbora no ambiente (Workspace)
        local pumpkinPart = Workspace:FindFirstChild(NOME_DA_ABOBORA)

        if pumpkinPart then
            print("✅ Abóbora encontrada! Iniciando clique...")
            
            -- 3. Ação de Destruição/Coleta (O Clique!)
            -- O método :Click() simula o clique do mouse no objeto, acionando a mecânica do jogo.
            pumpkinPart:Click() 

            print("✨ Abóbora clicada com sucesso! Aguardando...")
        else
            warn("❌ Abóbora não encontrada! Verifique se o nome está correto ou se ela sumiu.")
        end

        -- 4. Espera (O Delay)
        -- O script pausa por TEMPO_DE_ESPERA antes de procurar e clicar novamente.
        wait(TEMPO_DE_ESPERA)
    end
end

-- Inicia a função principal para que o farming comece imediatamente!
farmarAbobora()
