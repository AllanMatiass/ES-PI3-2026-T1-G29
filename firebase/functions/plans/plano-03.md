# Iteração 03: Integração no Mercado Primário (Compra da Startup)

Ajustar o preço quando a startup vende seus próprios tokens diretamente para investidores.

## Tarefas
- [ ] **Modificar `src/exchange/shared/transactionService.ts` -> `registerTransactionTx`**:
    - Identificar transações onde o `seller.type === "STARTUP"`.
    - Chamar `priceService.calculatePrimaryMarketPrice`.
    - Atualizar o documento da startup no Firestore com o novo preço gerado pela tração de venda primária.
- [ ] **Snapshot de Histórico**:
    - Chamar `saveValuationSnapshot` dentro da transação para que o gráfico de histórico reflita essa subida imediata.

## Objetivo
Simular a valorização da startup conforme ela capta recursos (vende tokens do seu próprio pool).
