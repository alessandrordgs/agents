# Feature Specification: Renderizadores por Alvo

**Feature Branch**: `002-target-renderers`

**Created**: 2026-07-17

**Status**: Draft

**Input**: User description: "Renderizadores por alvo: transformar a definicao unica de um agente (arquivo Claude .md com frontmatter name/description/tools/model e corpo) nos formatos especificos de cada alvo no momento da instalacao, substituindo a necessidade de arquivos por alvo escritos a mao. Codex: gerar .codex/agents/<nome>.toml. OpenCode: gerar .opencode/agent/<nome>.md. Claude: passthrough. Na v1 o modelo nao e traduzido e restricoes de ferramentas nao sao traduzidas. Inclui corrigir o destino do codex de .codex/prompts para .codex/agents."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Instalar em Codex a partir da fonte unica (Priority: P1)

Um usuario instala um agente que tem apenas a definicao canonica (formato Claude: metadados e corpo) num projeto Codex. A ferramenta gera, no momento da instalacao, o artefato nativo do Codex a partir dessa fonte unica, sem que ninguem tenha escrito um arquivo Codex a mao.

**Why this priority**: E a prova central do conceito de renderizador e o alvo cujo formato mais difere da fonte (TOML vs markdown). Entrega sozinha o valor: um agente definido uma vez roda no Codex.

**Independent Test**: Num projeto com `.codex/`, instalar um agente que so tem a definicao canonica; conferir que surge um TOML valido em `.codex/agents/<nome>.toml` com nome, descricao e o corpo do agente como instrucoes.

**Acceptance Scenarios**:

1. **Given** um agente com definicao canonica e suporte declarado a codex, **When** o usuario instala no alvo codex, **Then** e gerado `.codex/agents/<nome>.toml` valido com name, description e developer_instructions vindos da fonte.
2. **Given** o corpo do agente com aspas e multiplas linhas, **When** renderizado para TOML, **Then** o arquivo continua sendo um TOML valido (escaping correto).
3. **Given** um nome de agente com hifens, **When** renderizado para o campo name do Codex, **Then** o identificador gerado e valido para o Codex.

---

### User Story 2 - Instalar em OpenCode a partir da fonte unica (Priority: P2)

O mesmo agente de definicao unica e instalado num projeto OpenCode. A ferramenta gera o markdown nativo do OpenCode a partir da fonte, sem arquivo OpenCode escrito a mao.

**Why this priority**: Segundo alvo em relevancia; formato proximo da fonte (markdown com frontmatter), porem com chaves proprias.

**Independent Test**: Num projeto com `.opencode/`, instalar o agente; conferir `.opencode/agent/<nome>.md` com frontmatter contendo description e `mode: subagent`, e o corpo da fonte como conteudo.

**Acceptance Scenarios**:

1. **Given** um agente com definicao canonica e suporte a opencode, **When** instalado no alvo opencode, **Then** e gerado `.opencode/agent/<nome>.md` com frontmatter (`description`, `mode: subagent`) e o corpo como system prompt.
2. **Given** a fonte sem restricoes traduziveis na v1, **When** renderizado, **Then** o frontmatter nao inclui campos de modelo nem de ferramentas.

---

### User Story 3 - Claude sem regressao e catalogo de fonte unica (Priority: P3)

Agentes de alvo Claude continuam sendo instalados exatamente como antes (a fonte canonica ja e o formato do Claude, entao a instalacao e passthrough). Autores do catalogo passam a manter uma unica definicao por agente, sem escrever variantes por alvo.

**Why this priority**: Garante ausencia de regressao no alvo mais usado e consolida o beneficio de manutencao (uma definicao em vez de tres).

**Independent Test**: Instalar em `.claude/` um agente existente do catalogo e conferir que o arquivo instalado e identico a fonte canonica; confirmar que o agente declara alvos sem precisar de arquivos por alvo escritos a mao.

**Acceptance Scenarios**:

1. **Given** um agente cujo canonico ja e formato Claude, **When** instalado no alvo claude, **Then** o arquivo em `.claude/agents/<nome>.md` e identico a fonte (passthrough).
2. **Given** um agente declarando os tres alvos com uma unica definicao, **When** listado e instalado, **Then** nenhum arquivo por alvo escrito a mao e necessario no catalogo.

---

### Edge Cases

- Corpo do agente contendo aspas, crases ou varias linhas: o artefato TOML gerado precisa permanecer valido (escaping/estrategia de string adequada).
- Nome do agente com caracteres nao permitidos no identificador do Codex: o nome renderizado deve ser normalizado para um identificador valido, sem colidir com outro agente.
- Fonte canonica sem os metadados obrigatorios (nome ou descricao): a renderizacao e recusada antes de qualquer escrita.
- Agente que declara suporte apenas a um alvo: instalar em alvo nao declarado continua sendo recusado.
- Reinstalacao do mesmo agente ja renderizado: nao pode produzir mudanca (idempotencia sobre o artefato gerado).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A ferramenta MUST produzir, no momento da instalacao, o artefato no formato nativo de cada alvo suportado a partir de uma unica definicao canonica do agente.
- **FR-002**: Para o alvo Codex, a ferramenta MUST gerar `.codex/agents/<nome>.toml` contendo ao menos name, description e developer_instructions, onde developer_instructions e o corpo do agente.
- **FR-003**: Para o alvo OpenCode, a ferramenta MUST gerar `.opencode/agent/<nome>.md` com frontmatter contendo description e `mode: subagent`, e o corpo da fonte como conteudo (system prompt).
- **FR-004**: Para o alvo Claude, a ferramenta MUST instalar a definicao canonica sem transformacao (passthrough) em `.claude/agents/<nome>.md`.
- **FR-005**: A ferramenta MUST extrair nome e descricao dos metadados da fonte para alimentar os artefatos de todos os alvos.
- **FR-006**: A ferramenta MUST normalizar o nome para um identificador valido quando o formato do alvo exigir (caso do name do Codex), garantindo unicidade.
- **FR-007**: Na v1, a ferramenta MUST NOT propagar o modelo declarado na fonte para os artefatos renderizados; os artefatos herdam o modelo da sessao do alvo.
- **FR-008**: Na v1, a ferramenta MUST NOT traduzir restricoes de ferramentas da fonte para os artefatos dos alvos.
- **FR-009**: A ferramenta MUST usar `.codex/agents` como destino do alvo Codex, substituindo o destino anterior `.codex/prompts`.
- **FR-010**: A ferramenta MUST validar a fonte antes de renderizar; uma fonte sem os metadados obrigatorios e rejeitada antes de qualquer escrita no projeto.
- **FR-011**: As garantias existentes da CLI (idempotencia, nao destruicao, deteccao de conflito, remocao exata) MUST valer para os artefatos renderizados.
- **FR-012**: A renderizacao MUST ocorrer apenas para alvos que o agente declara suportar.
- **FR-013**: Manter uma unica definicao canonica por agente MUST substituir a necessidade de arquivos por alvo escritos a mao no catalogo.

### Key Entities *(include if feature involves data)*

- **Definicao canonica do agente**: fonte unica de verdade. Contem metadados (nome, descricao e, opcionalmente, modelo e ferramentas) e o corpo (instrucoes do agente). Formato de partida: o markdown de agente do Claude.
- **Renderizador de alvo**: regra que transforma a definicao canonica no artefato nativo de um alvo (Codex, OpenCode, Claude). Um por alvo.
- **Artefato renderizado**: arquivo gerado no formato do alvo e escrito no destino do alvo dentro do projeto.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um agente definido uma unica vez instala corretamente nos tres alvos (Codex, OpenCode, Claude) sem qualquer edicao manual dos artefatos gerados.
- **SC-002**: 100% dos artefatos gerados para Codex sao TOML validos e para OpenCode sao markdown com frontmatter valido.
- **SC-003**: Adicionar um novo agente ao catalogo passa a exigir uma unica definicao, sem nenhum arquivo por alvo escrito a mao.
- **SC-004**: Idempotencia e nao destruicao preservadas para artefatos renderizados em 100% dos casos (reinstalar nao muda nada; conflito aborta; remocao restaura).
- **SC-005**: Zero regressao no alvo Claude: os agentes Claude existentes continuam instalando de forma identica a fonte.

## Assumptions

- A definicao canonica e o arquivo de agente no formato do Claude (frontmatter com nome, descricao, ferramentas e modelo, seguido do corpo). Nao ha migracao dos agentes atuais.
- O corpo do agente e o mesmo texto de instrucoes para todos os alvos; nao ha conteudo especifico por alvo na v1.
- Os destinos por alvo permanecem configuraveis (calibration knob), com Codex corrigido para `.codex/agents`.
- A comparacao de idempotencia leva em conta o artefato renderizado (o resultado da transformacao), nao apenas o arquivo de origem.
- Traducao de modelo e de restricoes de ferramentas fica fora do escopo da v1 e pode ser adicionada depois.
