# Feature Specification: CLI de Instalacao de Agents

**Feature Branch**: `001-installer-cli`

**Created**: 2026-07-17

**Status**: Draft

**Input**: User description: "CLI de instalacao de agents via terminal estilo skills.sh, com comandos install, update, remove e list, suportando os alvos Codex, Claude e OpenCode em qualquer projeto"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Instalar um agente em um projeto (Priority: P1)

Um desenvolvedor esta em um projeto qualquer e quer usar um agente do repositorio. Ele roda um unico comando no terminal informando o nome do agente. A ferramenta detecta qual alvo esta em uso no projeto (Codex, Claude ou OpenCode), ou aceita o alvo informado explicitamente, e instala o agente no local correto daquele alvo, deixando-o pronto para uso imediato sem edicao manual.

**Why this priority**: E a razao de existir do produto. Sem instalar, nada mais tem valor. Entrega o MVP sozinha: um agente instalado e funcional em um alvo.

**Independent Test**: Em um projeto limpo, rodar o comando de instalacao de um agente conhecido e verificar que os arquivos do agente aparecem no local esperado do alvo e que o agente esta disponivel na ferramenta.

**Acceptance Scenarios**:

1. **Given** um projeto sem o agente instalado e um alvo suportado presente, **When** o usuario roda o comando de instalacao informando o nome do agente, **Then** o agente e instalado no local correto do alvo e a operacao reporta sucesso.
2. **Given** um projeto onde o mesmo agente ja esta instalado na mesma versao, **When** o usuario roda o comando de instalacao novamente, **Then** o estado final e identico e nenhuma alteracao adicional e feita (idempotencia).
3. **Given** um agente que declara suporte a um alvo, **When** o usuario instala nesse alvo, **Then** o agente funciona sem qualquer edicao manual de arquivos.
4. **Given** um arquivo do usuario que colidiria com um arquivo do agente, **When** o usuario roda a instalacao, **Then** o conflito e reportado e a operacao e interrompida sem sobrescrever, salvo consentimento explicito.

---

### User Story 2 - Listar agentes disponiveis e instalados (Priority: P2)

O usuario quer descobrir quais agentes existem no repositorio e quais ja estao instalados no projeto atual. Ele roda um comando de listagem e ve o catalogo com nome, descricao, versao e alvos suportados, alem de uma indicacao de quais estao instalados localmente.

**Why this priority**: Descoberta e pre requisito pratico para instalacao consciente, mas o produto ja entrega valor sem ela se o usuario souber o nome do agente.

**Independent Test**: Rodar o comando de listagem e verificar que o catalogo do repositorio e exibido com os campos obrigatorios do manifesto e a marcacao de instalados.

**Acceptance Scenarios**:

1. **Given** o repositorio com varios agentes, **When** o usuario roda o comando de listagem, **Then** cada agente e exibido com nome, descricao, versao e alvos suportados.
2. **Given** um projeto com alguns agentes instalados, **When** o usuario lista, **Then** os agentes instalados sao claramente diferenciados dos apenas disponiveis.

---

### User Story 3 - Atualizar um agente instalado (Priority: P3)

O usuario tem um agente instalado e quer leva lo a uma versao mais nova disponivel no repositorio. Ele roda o comando de atualizacao e o agente e substituido pela nova versao de forma idempotente, preservando o restante do projeto.

**Why this priority**: Manutencao de valor ao longo do tempo, mas depende de instalacao ja existente.

**Independent Test**: Instalar uma versao antiga, rodar a atualizacao e verificar que os arquivos passam para a versao nova sem afetar arquivos alheios ao agente.

**Acceptance Scenarios**:

1. **Given** um agente instalado em versao anterior a disponivel, **When** o usuario roda a atualizacao, **Then** o agente passa para a versao mais nova e a operacao reporta a mudanca de versao.
2. **Given** um agente ja na versao mais nova, **When** o usuario roda a atualizacao, **Then** nenhuma alteracao e feita e isso e reportado.

---

### User Story 4 - Remover um agente do projeto (Priority: P4)

O usuario quer retirar um agente que instalou. Ele roda o comando de remocao e todos os arquivos daquele agente sao retirados, restaurando o projeto ao estado anterior a instalacao, sem tocar em arquivos que nao pertencem ao agente.

**Why this priority**: Completa o ciclo de vida e sustenta a garantia de nao destruicao, mas e a acao menos frequente.

**Independent Test**: Instalar um agente, remover, e verificar que o projeto volta ao estado pre instalacao e nenhum arquivo residual do agente permanece.

**Acceptance Scenarios**:

1. **Given** um agente instalado, **When** o usuario roda a remocao, **Then** todos os arquivos do agente sao retirados e a operacao reporta sucesso.
2. **Given** um agente que nao esta instalado, **When** o usuario tenta remover, **Then** a ferramenta informa que nao ha nada a remover e nao altera o projeto.

---

### Edge Cases

- O que acontece quando nenhum alvo suportado e detectado no projeto e o usuario nao informou o alvo explicitamente? A ferramenta deve pedir o alvo ou reportar erro claro, sem instalar em local arbitrario.
- O que acontece quando o agente solicitado nao existe no catalogo? A ferramenta reporta que o agente e desconhecido e nao altera o projeto.
- O que acontece quando o agente nao declara suporte ao alvo escolhido? A ferramenta recusa a instalacao com mensagem explicando a incompatibilidade.
- O que acontece quando um arquivo do usuario colide com um arquivo do agente? A operacao para e reporta o conflito, sem sobrescrever, ate haver consentimento explicito.
- O que acontece quando a operacao e interrompida no meio (rede caiu, processo morto)? O projeto nao pode ficar em estado parcial inconsistente; ou a instalacao completa ou nao deixa residuo.
- O que acontece quando o manifesto do agente e invalido ou ausente? O agente e rejeitado antes de qualquer escrita no projeto.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A ferramenta MUST instalar um agente em um projeto a partir de um unico comando no terminal, informando o nome do agente.
- **FR-002**: A ferramenta MUST suportar os alvos Codex, Claude e OpenCode, instalando cada agente no local correto do alvo escolhido.
- **FR-003**: A ferramenta MUST detectar automaticamente o alvo em uso no projeto quando possivel, e MUST aceitar o alvo informado explicitamente pelo usuario, dando precedencia ao valor explicito.
- **FR-004**: A ferramenta MUST recusar a instalacao quando o agente nao declara suporte ao alvo escolhido, com mensagem explicativa.
- **FR-005**: A ferramenta MUST ser idempotente: repetir instalacao ou atualizacao com o mesmo estado de origem produz o mesmo estado final, sem efeitos colaterais adicionais.
- **FR-006**: A ferramenta MUST NOT sobrescrever arquivos preexistentes do usuario sem deteccao previa de conflito e consentimento explicito (politica; comportamento correspondente em FR-007).
- **FR-007**: A ferramenta MUST interromper a operacao ao detectar conflito, reportando o conflito em vez de aplicar mudanca parcial (comportamento que realiza a politica de FR-006).
- **FR-008**: A ferramenta MUST garantir que uma operacao interrompida nao deixe o projeto em estado parcial inconsistente.
- **FR-009**: A ferramenta MUST permitir listar os agentes do catalogo com nome, descricao, versao e alvos suportados.
- **FR-010**: A ferramenta MUST diferenciar, na listagem, os agentes instalados no projeto atual dos apenas disponiveis.
- **FR-011**: A ferramenta MUST permitir atualizar um agente instalado para uma versao mais nova disponivel, reportando a mudanca de versao.
- **FR-012**: A ferramenta MUST permitir remover um agente instalado, retirando todos os seus arquivos e restaurando o projeto ao estado anterior a instalacao.
- **FR-013**: A ferramenta MUST NOT remover ou alterar arquivos que nao pertencem ao agente durante remocao ou atualizacao.
- **FR-014**: A ferramenta MUST rejeitar, antes de qualquer escrita no projeto, agentes cujo manifesto seja ausente ou invalido.
- **FR-015**: A ferramenta MUST reportar de forma clara o resultado de cada operacao (sucesso, nada a fazer, erro, conflito) via texto no terminal.
- **FR-016**: A ferramenta MUST funcionar em qualquer projeto sem exigir alteracao das dependencias do projeto alvo.

### Key Entities *(include if feature involves data)*

- **Agente**: unidade instalavel do repositorio. Possui nome, descricao, versao e o conjunto de alvos suportados. Reune os arquivos que serao entregues no projeto.
- **Manifesto do Agente**: declaracao que descreve o agente (nome, descricao, versao, alvos suportados e arquivos que o compoem). E a fonte de verdade para descoberta, validacao e instalacao.
- **Alvo**: ferramenta de destino suportada (Codex, Claude, OpenCode). Cada alvo tem um local proprio no projeto onde os arquivos do agente sao entregues.
- **Instalacao**: registro do estado de um agente instalado em um projeto, incluindo qual versao e qual alvo, usado para listagem, atualizacao e remocao.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuario consegue instalar um agente em um projeto com um unico comando, em menos de 1 minuto, sem editar arquivos manualmente.
- **SC-002**: 100% das instalacoes de agentes que declaram suporte ao alvo escolhido resultam no agente funcional naquele alvo sem intervencao manual.
- **SC-003**: Repetir a mesma instalacao ou atualizacao nao produz nenhuma alteracao adicional em 100% dos casos (idempotencia verificavel).
- **SC-004**: Em 100% dos casos de conflito com arquivos do usuario, a operacao para sem sobrescrever e reporta o conflito.
- **SC-005**: A remocao de um agente restaura o projeto ao estado pre instalacao em 100% dos casos, sem residuos e sem afetar arquivos alheios ao agente.
- **SC-006**: A instalacao funciona nos tres alvos suportados (Codex, Claude, OpenCode) em projetos que nao passaram por nenhuma configuracao previa.

## Assumptions

- A instalacao e por projeto (escopo local ao diretorio do projeto), coerente com "em qualquer projeto"; instalacao global no nivel do usuario esta fora do escopo desta feature.
- O catalogo de agentes provem do proprio repositorio de agents, obtido via Git, sem servico externo adicional.
- Cada alvo (Codex, Claude, OpenCode) tem um local de instalacao conhecido e estavel dentro do projeto, definido na fase de planejamento.
- A ferramenta opera em ambiente com shell POSIX e Git disponiveis, sem exigir outras dependencias de runtime no projeto alvo.
- Versionamento de agentes segue a versao declarada no manifesto; a comparacao de versoes para atualizacao usa essa declaracao.
- Interacao e exclusivamente via terminal (texto de entrada e saida), sem interface grafica nesta feature.
