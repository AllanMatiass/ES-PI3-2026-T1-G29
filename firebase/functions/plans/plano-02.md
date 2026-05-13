# Iteração 02: Integração no Mercado Secundário (Negociação entre Usuários)

Nesta iteração, o preço da startup passará a reagir às compras feitas entre usuários através de ofertas.

## Tarefas
- [ ] **Modificar `src/exchange/shared/offerService.ts` -> `acceptOffer`**:
    - Adicionar a leitura do documento da Startup (`startupRef`) dentro da transação existente.
    - Chamar `priceService.calculateSecondaryMarketPrice` com os dados da oferta.
    - Calcular o novo `lastValuationCents` (preço novo * total tokens).
    - Executar `tx.update(startupRef, ...)` com o novo preço e timestamp.
- [ ] **Garantir a Consistência**:
    - A atualização do preço da startup deve ser a última operação de escrita na transação para evitar bloqueios desnecessários, mas ainda dentro do `db.runTransaction`.

## Objetivo
Fazer com que o "valor de mercado" da startup mude dinamicamente conforme investidores negociam tokens entre si.
