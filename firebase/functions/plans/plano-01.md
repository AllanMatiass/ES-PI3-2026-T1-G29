# Iteração 01: Infraestrutura de Cálculo e Constantes

Esta iteração foca em criar a base matemática para a variação de preços, sem alterar o fluxo de transações ainda.

## Tarefas

- [ ] **Criar `src/startups/shared/constants.ts`**:
  - Definir `MARKET_SENSITIVITY_K = 0.5`.
  - Definir `PRIMARY_MARKET_TRACTION_K = 0.1`.
- [ ] **Criar `src/startups/shared/priceService.ts`**:
  - Implementar `calculateSecondaryMarketPrice`: Recebe preço atual, preço da oferta, quantidade de tokens, e total de tokens. Retorna o novo preço.
  - Implementar `calculatePrimaryMarketPrice`: Recebe preço atual, quantidade de tokens comprados da startup, e total de tokens. Retorna o novo preço.
- [ ] **Exportar as funções** para uso nos serviços de exchange.

## Objetivo

Ter um serviço puro e testável que isola a lógica matemática das fórmulas.
