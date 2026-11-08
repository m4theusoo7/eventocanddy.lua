-- =========================================
-- 🎃 CONFIGURAÇÕES DO FARMER DE PUMPKINS
-- =========================================

local listaDePumpkins = {
    { nome = "Pumpkin A", vida = 100, localizacao = "(10, 5)" },
    { nome = "Pumpkin B", vida = 80, localizacao = "(25, 12)" },
    { nome = "Pumpkin C", vida = 120, localizacao = "(30, 8)" },
}

local DANO_POR_GOLPE = 15 -- Dano por golpe
local TEMPO_ATACAR = 1     -- Tempo de espera entre ataques (em segundos)
local TEMPO_PAUSA_ENTRE_ALVOS = 2.5 -- Pausa antes de ir para o próximo Pumpkin

-- Função que simula o ataque e diminui a vida do Pumpkin
function atacar(pumpkin)
    pumpkin.vida = pumpkin.vida - DANO_POR_GOLPE
    -- Garante que a vida nunca fique negativa
    if pumpkin.vida < 0 then
        pumpkin.vida = 0
    end
    print("   -> Atacando " .. pumpkin.nome .. "! Vida restante: " .. pumpkin.vida)
end

-- Função principal para farmar um único Pumpkin até ele sumir (Vida <= 0)
function farmarPumpkin(pumpkin)
    print("----------------------------------------")
    print("🎃 INICIANDO FARM: " .. pumpkin.nome)
    print("📍 Localização: " .. pumpkin.localizacao)

    -- Loop de ataque: continua enquanto a vida for maior que zero
    while pumpkin.vida > 0 do
        atacar(pumpkin)
        wait(TEMPO_ATACAR) -- Espera o tempo definido antes do próximo golpe
    end

    print("✅ FARM CONCLUÍDO: " .. pumpkin.nome .. " foi destruído!")
    return pumpkin -- Retorna o Pumpkin já farmado
end

-- Função principal que gerencia a fila e garante que todos os Pumpkins sejam atacados em sequência
function iniciarFarm()
    print("=========================================")
    print("🚀 INICIANDO O BOT DE FARMING DE PUMPKINS!")
    print("=========================================")

    for i, pumpkin in ipairs(listaDePumpkins) do
        -- Chama a função que fará o ataque até sumir e espera ela terminar
        farmarPumpkin(pumpkin)

        -- Pausa entre um Pumpkin e outro (simula movimento no jogo)
        print("\n--- Movendo para o próximo alvo (" .. i .. "/" .. #listaDePumpkins .. ")... ---\n")
        wait(TEMPO_PAUSA_ENTRE_ALVOS)
    end

    print("=========================================")
    print("🎉 TODOS OS PUMPKINS FORAM FARMADOS COM SUCESSO!")
    print("=========================================")
end

-- Executa o script principal!
iniciarFarm()
