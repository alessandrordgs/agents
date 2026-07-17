---
description: "Task list for Renderizadores por Alvo"
---

# Tasks: Renderizadores por Alvo

**Input**: Design documents from `/specs/002-target-renderers/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/renderers.md

**Tests**: Incluidos (POSIX sh), como na feature 001, mais validacao de TOML/YAML quando houver ferramenta.

**Organization**: Tarefas por user story. Estende a CLI da feature 001; muda o schema do manifesto.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependencia)
- **[Story]**: US1..US3
- Caminhos exatos incluidos

## Path Conventions

Single project CLI, raiz do repositorio (`bin/`, `lib/`, `agents/`, `tests/`), conforme plan.md.

---

## Phase 1: Setup

- [X] T001 [P] Atualizar `targets.conf`: corrigir destino do codex para `.codex/agents` e adicionar coluna de extensao por alvo (claude=md, codex=toml, opencode=md); manter marker e min_version

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Novo schema de manifesto e infraestrutura de renderizacao compartilhada por todas as stories. Muda a base da feature 001.

**⚠️ CRITICAL**: Nenhuma user story pode iniciar antes desta fase

- [X] T002 Reescrever o parse/validacao em `lib/manifest.sh` para o novo schema (`source` + `targets` em vez de blocos por alvo): `manifest_source`, `manifest_targets` lendo a linha `targets:`, `manifest_supports`, e validacao (name/version/description/source presentes, arquivo de source existe, targets nao vazio e conhecidos)
- [X] T003 Criar `lib/render.sh`: extracao do frontmatter da fonte (name, description, corpo separando pelo `---`), normalizacao de nome para identificador (`[^A-Za-z0-9_]`->`_`), helpers de escaping, e dispatcher `render_target <target> <source> <name>` com o alvo claude por passthrough
- [X] T004 Refatorar `lib/commands/install.sh` e `lib/plan.sh`: `install_agent` renderiza a fonte para arquivo temporario via `render_target`, resolve `dest` e `ext` do alvo, calcula `destrel=<dest>/<nome>.<ext>`, reusa deteccao de conflito e lock, e mede idempotencia pelo conteudo renderizado
- [X] T005 Ajustar `lib/commands/list.sh` para exibir `targets` do novo schema (linha `targets:`)
- [X] T006 Migrar o catalogo para fonte canonica: criar `agents/<nome>/agent.md` e reescrever `agents/<nome>/manifest` no novo schema para `example-agent`, `ui-design-strategist` e `frontend-dev`; remover os arquivos por alvo antigos (`claude/`, `codex/`, `opencode/`)
- [X] T007 Atualizar os testes existentes ao novo schema em `tests/test_install.sh`, `tests/test_conflict.sh`, `tests/test_list.sh`, `tests/test_update.sh`, `tests/test_select.sh` (catalogos temporarios com `source`+`targets`; destino/extensao do codex corrigidos)

**Checkpoint**: CLI instala pela fonte unica (claude passthrough) e a suite existente passa

---

## Phase 3: User Story 1 - Codex a partir da fonte unica (Priority: P1) 🎯 MVP

**Goal**: Instalar no alvo Codex gerando `.codex/agents/<nome>.toml` valido a partir da fonte canonica.

**Independent Test**: Em projeto com `.codex/`, instalar um agente e conferir TOML valido com name normalizado, description e developer_instructions (corpo).

### Tests for User Story 1

- [X] T008 [US1] Criar `tests/test_render.sh` com o caso codex: `render_target codex` produz TOML com `name` normalizado, `description` escapada e `developer_instructions` em string literal `'''`, cobrindo corpo com aspas e multiplas linhas

### Implementation for User Story 1

- [X] T009 [US1] Implementar o branch codex em `lib/render.sh` (gerar o TOML conforme contracts/renderers.md)
- [X] T010 [US1] Estender `tests/test_install.sh` com o alvo codex: instala em `.codex/agents/<nome>.toml`, valida idempotencia e (se `python3` disponivel) que o TOML carrega

**Checkpoint**: US1 funcional e testavel (MVP)

---

## Phase 4: User Story 2 - OpenCode a partir da fonte unica (Priority: P2)

**Goal**: Instalar no alvo OpenCode gerando `.opencode/agent/<nome>.md` com frontmatter e corpo.

**Independent Test**: Em projeto com `.opencode/`, instalar e conferir frontmatter (`description`, `mode: subagent`) e o corpo como conteudo.

### Tests for User Story 2

- [X] T011 [US2] Adicionar em `tests/test_render.sh` o caso opencode: frontmatter com `description` escapada e `mode: subagent`, corpo preservado, sem campo de modelo nem de ferramentas

### Implementation for User Story 2

- [X] T012 [US2] Implementar o branch opencode em `lib/render.sh` (conforme contracts/renderers.md)
- [X] T013 [US2] Estender `tests/test_install.sh` com o alvo opencode: instala em `.opencode/agent/<nome>.md`, valida idempotencia

**Checkpoint**: US1 e US2 funcionais de forma independente

---

## Phase 5: User Story 3 - Claude sem regressao e catalogo fonte unica (Priority: P3)

**Goal**: Garantir passthrough identico no Claude e catalogo mantido por uma unica definicao.

**Independent Test**: Instalar no Claude e conferir arquivo identico a fonte; confirmar que os agentes do catalogo declaram alvos sem arquivos por alvo escritos a mao.

### Tests for User Story 3

- [X] T014 [US3] Adicionar em `tests/test_render.sh` o caso claude: saida identica byte a byte a fonte (passthrough)
- [X] T015 [US3] Criar `tests/test_catalog.sh`: cada agente do catalogo tem exatamente um `agent.md` e um `manifest` no novo schema (sem diretorios por alvo), e um agente que declara os tres alvos instala nos tres

**Checkpoint**: Todas as user stories funcionais; zero regressao no Claude

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T016 [P] Rodar shellcheck em `lib/render.sh` e nos arquivos modificados, corrigir apontamentos
- [X] T017 [P] Atualizar `README.md`: novo schema de manifesto (`source`+`targets`), fonte canonica `agent.md`, secao "Como adicionar um novo agente" e tabela de alvos com `.codex/agents`
- [X] T018 Executar o `specs/002-target-renderers/quickstart.md` ponta a ponta, validando os artefatos TOML/YAML gerados

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependencias
- **Foundational (Phase 2)**: depende do Setup; BLOQUEIA todas as stories. T002 e T003 antes de T004; T006 depois de T002; T007 depois de T004/T006
- **US1/US2/US3 (Phases 3-5)**: dependem da Foundational; depois podem seguir em paralelo ou em ordem de prioridade
- **Polish (Phase 6)**: depois das stories desejadas

### Within Each User Story

- Teste do renderizador antes da implementacao do branch
- Branch do renderizador antes de estender o teste de instalacao

### Parallel Opportunities

- T001 (Setup) isolado
- Na Foundational, T005 pode correr em paralelo a T003; T002/T003/T004 sao o caminho critico
- Apos a Foundational, os branches codex (US1) e opencode (US2) sao independentes entre si (mesmo arquivo `lib/render.sh`, entao coordenar a edicao; os testes por alvo sao independentes)

---

## Implementation Strategy

### MVP First (US1 Codex)

1. Setup + Foundational (schema, render infra, install refactor, migracao, testes atualizados)
2. US1: renderizador codex + teste
3. PARAR e VALIDAR: instalar um agente no codex e abrir o TOML
4. Seguir para US2 e US3

### Incremental Delivery

Foundational pronta -> US1 (codex) -> US2 (opencode) -> US3 (claude/regressao) -> Polish.

---

## Notes

- Mudanca de schema quebra os testes da feature 001 ate T007; por isso T007 e foundational.
- `lib/render.sh` e editado por US1 e US2 (branches codex/opencode); coordenar para evitar conflito no mesmo arquivo.
- Ceiling conhecido: corpo do agente contendo a sequencia `'''` quebraria o TOML literal; marcar com comentario ponytail se aparecer.
- Commit apos cada tarefa ou grupo logico.
