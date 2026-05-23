# 📌 Requisitos do Sistema - MesclaInvest

## 🔧 Requisitos Funcionais (RF)

### 👤 Usuário e Conta

**RF01 - Cadastro de Usuário**  
O sistema deve permitir a criação de contas mediante nome completo, e-mail válido, CPF, telefone e senha.

---

**RF02 - Autenticação**  
O sistema deve validar credenciais, não permitindo acesso anônimo.

---

**RF03 - Recuperação de Senha**  
O sistema deve permitir recuperação de senha via e-mail.

---

**RF04 - Autenticação Multifator (MFA)**  
O sistema deve permitir ativação opcional de MFA.

---

**RF05 - Perfil do Usuário**  
O sistema deve permitir visualização e edição dos dados do usuário.

---

### 📊 Startups e Navegação

**RF06 - Listagem de Startups**  
O sistema deve listar startups com filtros por estágio.

---

**RF07 - Detalhes da Startup**  
O sistema deve exibir:

- Resumo executivo
- Plano de negócios
- Estrutura societária
- Conselho e mentores

---

**RF08 - Mural de Interação**  
O sistema deve permitir perguntas e respostas públicas.

---

**RF09 - Vídeo Promocional**  
O sistema deve permitir visualização de vídeos das startups.

---

**RF10 - Filtros Avançados**  
O sistema deve permitir filtragem por:

- Estágio
- Área de atuação
- Volume de investimento

---

**RF11 - Atualizações de Startup**  
O sistema deve exibir atualizações publicadas pelas startups.

---

### 💰 Mercado e Investimentos

**RF12 - Carteira Digital**  
O sistema deve permitir saldo fictício para operações.

---

**RF13 - Emissão de Tokens**  
Cada startup deve possuir quantidade fixa de tokens.

---

**RF14 - Propriedade de Tokens**  
O sistema deve registrar a posse de tokens por usuário.

---

**RF15 - Compra de Tokens**  
O usuário deve poder comprar tokens utilizando saldo disponível.

---

**RF16 - Venda de Tokens**  
O usuário deve poder vender tokens que possui.

---

**RF17 - Validação de Operações**  
O sistema deve impedir:

- Compra sem saldo suficiente
- Venda sem tokens suficientes

---

**RF18 - Registro de Transações**  
O sistema deve registrar todas as operações realizadas.

---

### 📈 Precificação e Análise

**RF19 - Definição de Preço**  
O preço do token deve ser baseado na última transação realizada.

---

**RF20 - Atualização de Preço**  
O preço deve ser atualizado automaticamente a cada compra ou venda.

---

**RF21 - Variação Percentual**  
O sistema deve calcular a variação percentual do preço.

---

**RF22 - Histórico de Preços**  
O sistema deve armazenar o histórico de preços dos tokens.

---

**RF23 - Dashboard de Valorização**  
O sistema deve exibir gráficos de variação:

- Diário
- Semanal
- Mensal

---

**RF24 - Portfólio do Usuário**  
O sistema deve exibir:

- Tokens adquiridos
- Valor atual
- Preço médio
- Lucro/prejuízo

---

### 🔐 Segurança

**RF25 - Controle de Acesso**  
Apenas usuários autenticados podem realizar operações.

---

**RF26 - Rastreabilidade**  
O sistema deve registrar:

- Usuário
- Data/hora
- Tipo
- Valor

---

**RF27 - Simulação de Mercado Dinâmico**

O sistema deve simular variação de preço baseada nas ações dos usuários:

- Compras aumentam o preço do token
- Vendas reduzem o preço do token
- A intensidade da variação pode ser proporcional à quantidade negociada

> Essa abordagem permite simular comportamento de mercado real sem necessidade de um sistema complexo de livro de ofertas.

---

## ⚙️ Requisitos Não Funcionais (RNF)

**RNF01 - Frontend**  
O sistema deve utilizar Flutter (Dart).

---

**RNF02 - Backend**  
O sistema deve utilizar Node.js (JavaScript ou TypeScript).

---

**RNF03 - Banco de Dados**  
O sistema deve utilizar Firebase Firestore.

---

**RNF04 - Versionamento**  
O código deve ser versionado com Git e GitHub.

---

**RNF05 - Segurança**  
As senhas devem ser armazenadas utilizando hash seguro.

---

**RNF06 - Desempenho**  
Quando a função firebase estiver em estado cold, deve responder em menos de 5 segundos

---

**RNF07 - Usabilidade**  
A interface deve ser intuitiva.

---

**RNF08 - Consistência de Dados**  
Operações financeiras devem manter consistência.

---

**RNF09 - Integridade de Transações**  
Operações devem ser atômicas.

---

**RNF10 - Logs**  
O sistema deve registrar eventos e erros relevantes.

---
