# Grupo 29

## Integrantes

| Nome                          | RA       |
| ----------------------------- | -------- |
| Allan Giovanni Matias Paes    | 25008211 |
| Giovanna Bonfim Portela Souza | -        |
| Murilo Rigoni                 | -        |
| Pedro Vinícius Romanato       | 25004075 |
| Vinícius Castro de Oliveira   | -        |

# MesclaInvest

Projeto desenvolvido para a disciplina **Projeto Integrador 3** do curso de **Engenharia de Software da PUC-Campinas (2026)**.

O **MesclaInvest** é uma aplicação mobile que simula uma plataforma de investimento em startups vinculadas ao ecossistema de inovação **Mescla**. A proposta é criar um ambiente digital onde usuários possam visualizar startups, acompanhar informações institucionais e realizar **negociações simuladas de tokens**, representando participações digitais nos projetos.

O objetivo do projeto é proporcionar experiência prática no desenvolvimento de um sistema completo, envolvendo **backend, API, banco de dados e aplicação mobile**, além da aplicação de conceitos de arquitetura de software, modelagem de dados e integração entre serviços.

> ⚠️ Todas as operações financeiras presentes no sistema são **simulações** e não envolvem dinheiro real ou integração com instituições financeiras.

---

# Funcionalidades Principais

- Cadastro e autenticação de usuários
- Catálogo de startups do ecossistema Mescla
- Visualização de informações institucionais das startups
- Sistema de perguntas e interações com empreendedores
- Simulação de compra e venda de tokens
- Carteira digital com saldo fictício
- Dashboard para acompanhamento de valorização dos tokens
- Autenticação multifator (2FA/MFA)

---

# Arquitetura do Sistema

O projeto é dividido em duas principais camadas:

### Backend

Responsável por:

- Regras de negócio
- Autenticação de usuários
- Simulação das negociações de tokens
- APIs para consumo pelo aplicativo mobile
- Persistência de dados

### Mobile (Frontend)

Aplicação mobile responsável por:

- Interface do usuário
- Consumo das APIs
- Visualização de startups
- Interação com o sistema de investimentos simulados

---

# Tecnologias Utilizadas

## Backend

- **Node.js**
- **TypeScript**
- **Firebase Admin SDK**
- **Firebase Authentication**
- **Firebase Firestore**

## Mobile

- **Flutter**
- **Dart**

## Banco de Dados

- **Firebase Firestore**

## Ferramentas de Desenvolvimento

- **Git**
- **GitHub**
- **Visual Studio Code**
- **Android Studio**

---

# Como rodar o projeto

`git clone https://github.com/AllanMatiass/ES-PI3-2026-T1-G29.git`
`cd ES-PI3-2026-T1-G29`

### Setup Backend

`cd backend`

- Criar um arquivo .env ao lado de .env-example e colocar todas as variáveis do exemplo preenchida com dados reais
- Colocar em `/secrets` o arquivo `firebase-service-account.json` disponibilizado aos membros ou pegar um novo json no service account do firebase e renomear o arquivo para `firebase-service-account`

`npm install`
`npm start`

### Setup Frontend (Flutter)

`cd frontend`

- Criar um arquivo .env ao lado de .env.example e colocar todas as variáveis do exemplo preenchida com dados reais

`flutter pub get`
`flutter run`

---

# Licença

Este projeto foi desenvolvido exclusivamente para fins **acadêmicos** na disciplina **Projeto Integrador 3** da **PUC-Campinas**.
