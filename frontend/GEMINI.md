# Diretrizes de Desenvolvimento - Mescla Invest

Este documento define os padrões arquiteturais e as melhores práticas para o desenvolvimento do frontend do projeto Mescla Invest.

## 1. Arquitetura de Pastas
- `lib/constants/`: Valores fixos globais (ex: `colors.dart`).
- `lib/models/`: Classes de dados e DTOs.
- `lib/services/`: Lógica de API e gerenciamento de estado global (`user_state.dart`).
- `lib/views/`: Telas principais, focadas em coordenação e navegação (devem ser "magras").
- `lib/widgets/`: Componentes reutilizáveis de interface.
  - `lib/widgets/cards/`: Cards específicos de dados.
  - `lib/widgets/headers/`: Cabeçalhos de seção ou tela.
  - `lib/widgets/animations/`: Widgets com lógica de animação.

## 2. Padrões de Interface (UI)
- **Cores:** NUNCA use cores hardcoded (ex: `Color(0xFF...)`). Use sempre `AppColors` de `lib/constants/colors.dart`.
- **Estados de Tela:** Utilize sempre os widgets genéricos para manter a consistência visual:
  - Carregamento: `ShimmerPlaceholder`.
  - Lista Vazia: `EmptyStateWidget`.
  - Erros: `ErrorStateWidget`.
- **Feedback:** Use `FeedbackModal` para mensagens de sucesso, aviso ou erro ao usuário.

## 3. Melhores Práticas de Código
- **Surgical Extraction:** Ao identificar um widget com mais de 50 linhas dentro de uma `View`, extraia-o para a pasta `lib/widgets/`.
- **Imutabilidade:** Prefira `StatelessWidget` sempre que possível. Use `ValueListenableBuilder` para reagir a mudanças de estado pontuais sem reconstruir toda a tela.
- **Internacionalização:** Formate valores monetários usando a lógica de centavos (int/double) para Real (R$) conforme padronizado nos componentes `AnimatedCurrency`.
- **Documentação:** Mantenha os comentários de autor e a breve descrição da finalidade no topo de cada arquivo.

## 4. Fluxo de Trabalho do Agente
1. **Pesquisa:** Verificar se já existe um widget ou constante que resolva o problema.
2. **Estratégia:** Propor a criação de componentes reutilizáveis antes de codificar lógica específica.
3. **Execução:** Aplicar mudanças cirúrgicas, respeitando as importações centralizadas.
4. **Validação:** Garantir que o código compila e segue o `AppColors` e o `Design System`.
