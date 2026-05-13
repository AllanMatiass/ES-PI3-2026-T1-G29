# Iteração 04: Histórico, Eventos e Validação Final

Finalização do sistema com persistência de histórico e preparação para eventos externos.

## Tarefas
- [ ] **Consolidar Histórico**:
    - Revisar `startupRepository.ts` para garantir que `saveValuationSnapshot` armazena o motivo da mudança (ex: "TRADE", "PRIMARY_SALE", "EVENT").
- [ ] **Suporte a Eventos Aleatórios**:
    - Criar função `applyGlobalPriceEvent(startupId, percentage, reason)` no `priceService` para permitir que administradores ou gatilhos externos simulem notícias do mercado.
- [ ] **Testes de Stress**:
    - Simular múltiplas compras seguidas de uma startup para validar se o preço sobe conforme o esperado sem estourar limites numéricos.

## Objetivo
Garantir que todos os dados históricos estejam corretos para exibição em dashboards e que o sistema suporte intervenções externas (eventos).
