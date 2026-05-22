# Grupo 29

## Integrantes

| Nome                          | RA       |
| ----------------------------- | -------- |
| Allan Giovanni Matias Paes    | 25008211 |
| Giovanna Bonfim Portela Souza | 25005958 |
| Murilo Rigoni                 | 25006049 |
| Pedro Vinícius Romanato       | 25004075 |
| Vinícius Castro de Oliveira   | 25002026 |

# MesclaInvest

O **MesclaInvest** é uma plataforma de investimento em startups que simula um ecossistema real de Venture Capital e Mercado de Capitais. O projeto permite que usuários invistam em startups através da compra de **tokens**, participem de rodadas primárias, negociem no mercado secundário e acompanhem a valorização de seu portfólio em tempo real.

---

## 🏛️ Arquitetura e Padrões

### Backend (Firebase Functions + TypeScript)

- **Repository Pattern**: Abstração da camada de dados para facilitar testes e manutenção (ex: `startupRepository.ts`).
- **Service Layer**: Lógica de negócio isolada (ex: `valuationService.ts`, `pricingEngine.ts`).
- **Middleware de Erros (`withCallHandler`)**: Padronização de respostas da API.
- **Atomicidade**: Uso extensivo de **Firestore Transactions** para garantir integridade em operações financeiras.

### Frontend (Flutter + Dart)

- **Service Pattern**: Chamadas de API centralizadas em `BaseService`.
- **Global State Management**: Uso de `ChangeNotifier` (ex: `UserState`) para dados do usuário.
- **Atomic Design Principles**: Componentização modular (Cards, Tiles, Modais).
- **Consistência Visual**: Widgets de estado para Loading (`Shimmer`), Erro e Vazio.

---

## 🛠️ Funções do Backend (Cloud Functions)

### 🔐 Autenticação (Auth)

- `signup`: Realiza o cadastro de novos investidores no sistema.

### 📈 Mercado e Negociação (Exchange)

- `buyTokensFromStartup`: **Mercado Primário**. Compra direta da startup, impactando o preço via oferta e demanda.
- `createOffer`: Cria uma oferta de venda no **Mercado Secundário**.
- `acceptOffer`: Executa a compra de uma oferta existente de outro investidor.
- `cancelOffer`: Remove uma oferta de venda do mercado.
- `getOffers` / `getMyOffers`: Listagem de oportunidades de investimento.
- `expireOffer`: Processo automático de expiração de ofertas antigas.

### 🚀 Startups

- `listStartups`: Catálogo completo com filtros e busca.
- `getStartupDetails`: Agrega métricas de risco, retorno esperado e dados institucionais.
- `getStartupPriceHistory`: Dados históricos para geração de gráficos.
- `getStartupQuestions` / `createStartupQuestion`: Sistema de Q&A entre investidores e founders.
- `seedStartupCatalog`: Ferramenta de carga inicial de dados.

### 👤 Usuário e Carteira (User)

- `getUser`: Detalhes do perfil, saldo e posições custodiadas.
- `getUserTokenValuations`: Histórico de evolução do patrimônio (NAV).
- `createDeposit`: Adição de saldo fictício (BRL).
- `createWithdraw`: Retirada de fundos da carteira.

---

## 🧮 Fórmulas e Lógica de Negócio

### 1. NAV (Net Asset Value) - Valorização de Portfólio

O valor total do patrimônio do usuário é calculado em tempo real:
`Patrimônio = Saldo em Conta + Σ (Quantidade de Tokens_i * Preço Atual_i)`

A função `getUserTokenValuations` reconstrói o histórico do NAV "desfazendo" transações passadas a partir do estado atual para gerar o gráfico evolutivo.

### 2. Pricing Engine (Motor de Preço)

O preço dos tokens não é estático. Ele reage a cada negociação:

- **Segurança (Safety Lock)**: Nenhuma negociação pode alterar o preço em mais de **±5%** (Delta Max) de uma única vez.
- **Mercado Primário**:
  `P_novo = P_atual * (1 + (Q_comprada / Total_Tokens * K_primario))`
- **Mercado Secundário**:
  `P_novo = P_atual * (1 + ((P_oferta - P_atual) / P_atual * Q_negociada / Total_Tokens * K_secundario))`
- **Mercado Terciário (Eventos)**:
  `P_novo = P_atual * (1 + Delta_Evento)`

### 3. Investment Metric Service (Risco e Retorno)

O risco de cada startup (0-10) é calculado com base em pesos:

- **Estágio (Stage)**: Startups "novas" possuem risco maior que "em expansão".
- **Equipe (Team)**: Founders solo aumentam o risco; múltiplos founders reduzem.
- **Complexidade**: Tags como "DeepTech" ou "IoT" aumentam a pontuação de risco.
- **Mentoria**: Presença de conselheiros reduz o risco.

---

## 🛡️ Tratamento de Erros e Segurança

### `withCallHandler`

Todas as funções são envolvidas por este wrapper, que garante:

1. **Logs centralizados**: Erros são registrados no Firebase Logger com contexto (UID, dados).
2. **Resposta Padronizada**: A resposta segue sempre o modelo:
   ```json
   {
     "success": boolean,
     "data": T,
     "error": { "code": string, "message": string, "status": number }
   }
   ```
3. **Mapeamento Automático**: Converte `HttpsError` para status codes HTTP correspondentes (400, 401, 403, 404, etc).

### Por que usar Transactions?

As **Transactions do Firestore** são cruciais no MesclaInvest para evitar **Race Conditions**:

- **Consistência de Saldo**: Garante que o usuário não gaste mais do que possui se clicar no botão "Comprar" várias vezes rapidamente.
- **Integridade de Estoque**: Impede que o mesmo token seja vendido para dois compradores simultâneos no Mercado Secundário.
- **Sincronismo**: Atualiza o preço da startup, cria o registro da transação e altera o saldo do usuário como uma única operação atômica. Se uma parte falhar, nada é persistido.

---

## 🚀 Como rodar o projeto

### Setup Backend

`cd firebase/functions`

1. `npm install`
2. Configure o Firebase CLI e selecione o projeto.
3. `npm run build`
4. `firebase emulators:start` (para teste local) ou `firebase deploy`

### Setup Frontend (Flutter)

`cd frontend`

1. `flutter pub get`
2. Crie o arquivo `.env` com as chaves do Firebase.
3. Coloque o arquivo `google-services.json` em `frontend/android/app`
4. `flutter run`

---

# Licença

Este projeto foi desenvolvido exclusivamente para fins **acadêmicos** na disciplina **Projeto Integrador 3** da **PUC-Campinas**.
