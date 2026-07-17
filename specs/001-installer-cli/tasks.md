---
description: "Task list for CLI de Instalacao de Agents"
---

# Tasks: CLI de Instalacao de Agents

**Input**: Design documents from `/specs/001-installer-cli/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cli-commands.md

**Tests**: Incluidos. A constituicao (Fluxo de Desenvolvimento e Qualidade) exige verificacao executavel para logica de instalacao nao trivial; os testes sao scripts POSIX sh rodando em diretorio temporario que simula um projeto alvo.

**Organization**: Tarefas agrupadas por user story para implementacao e teste independentes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependencia)
- **[Story]**: User story a que a tarefa pertence (US1..US4)
- Caminhos de arquivo exatos incluidos nas descricoes

## Path Conventions

Single project CLI. `bin/`, `lib/`, `agents/`, `tests/` na raiz do repositorio, conforme plan.md.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Estrutura do projeto e configuracao base

- [X] T001 Criar estrutura de diretorios `bin/`, `lib/`, `lib/commands/`, `agents/`, `tests/` na raiz do repositorio conforme plan.md
- [X] T002 [P] Criar `targets.conf` na raiz com defaults por alvo (claude `.claude/agents` marker `.claude`; codex `.codex/prompts` marker `.codex`; opencode `.opencode/agent` marker `.opencode`) incluindo a versao minima testada de cada ferramenta, atendendo a matriz de compatibilidade exigida pela constituicao
- [X] T003 [P] Criar helper de assercao `tests/assert.sh` (funcoes assert_eq, assert_file_exists, assert_file_absent, assert_exit) usando apenas POSIX sh

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Nucleo compartilhado por todos os comandos. Nenhuma user story pode comecar antes.

**⚠️ CRITICAL**: Nenhuma user story pode iniciar ate esta fase estar completa

- [X] T004 Implementar parse e validacao do manifesto em `lib/manifest.sh` (le `agents/<name>/manifest`, extrai name/version/description/targets e blocos target com dest/file, valida regras de data-model.md, retorna erro antes de qualquer escrita)
- [X] T005 [P] Implementar deteccao de alvo e resolucao de destino em `lib/targets.sh` (le `targets.conf`, detecta alvo por marcador, aplica precedencia de `--target`, resolve dest final com fallback para default)
- [X] T006 [P] Implementar leitura e escrita atomica do lock em `lib/lock.sh` (le/escreve `.agents/lock` formato `name<TAB>version<TAB>target<TAB>relpath`, grava via temp + mv, consultas por agente)
- [X] T007 Implementar planejamento e deteccao de conflito em `lib/plan.sh` (calcula destinos, verifica colisao com arquivos fora do lock do agente, aborta antes de escrever; depende de T004, T005, T006)
- [X] T008 Implementar entrypoint e dispatch em `bin/agents` (roteia install/update/remove/list, imprime uso em `--help`/sem comando, resolve raiz do catalogo a partir do proprio local)
- [X] T009 [P] Criar agente de exemplo em `agents/example-agent/` declarando os tres alvos (claude, codex, opencode) com manifest valido e arquivos por alvo, como fixture de testes que cobre SC-006

**Checkpoint**: Nucleo pronto. Implementacao das user stories pode comecar.

---

## Phase 3: User Story 1 - Instalar um agente (Priority: P1) 🎯 MVP

**Goal**: Instalar um agente do catalogo no projeto atual com um unico comando, idempotente e sem sobrescrever arquivos do usuario.

**Independent Test**: Em projeto com `.claude/`, rodar `agents install example-agent`; conferir arquivos em `.claude/agents/` e linha no `.agents/lock`; rodar de novo sem mudanca.

### Tests for User Story 1

- [X] T010 [P] [US1] Teste de instalacao em `tests/test_install.sh` (instala example-agent nos tres alvos claude, codex e opencode, verifica arquivos no destino e linhas no lock em cada um; reinstala e verifica no-op/idempotencia) cobrindo SC-006
- [X] T011 [P] [US1] Teste de conflito e recusa em `tests/test_conflict.sh` (arquivo do usuario colidindo aborta sem sobrescrever; alvo nao suportado recusa; agente desconhecido erro; manifesto invalido rejeitado antes de escrever; projeto inalterado)

### Implementation for User Story 1

- [X] T012 [US1] Confirmar e ajustar destinos e versoes minimas de `targets.conf` contra a documentacao vigente de Codex, Claude e OpenCode (calibration knob do plano; alimenta a matriz de compatibilidade)
- [X] T013 [US1] Implementar comando de instalacao em `lib/commands/install.sh` (resolve alvo, valida suporte via manifesto, planeja via `lib/plan.sh`, copia arquivos, grava lock; trata no-op idempotente e conflito)
- [X] T014 [US1] Ligar `install` ao dispatch em `bin/agents` com mensagens de resultado (sucesso, no-op, erro-agente, erro-alvo, erro-manifesto, conflito) conforme contracts/cli-commands.md

**Checkpoint**: US1 funcional e testavel de forma independente (MVP)

---

## Phase 4: User Story 2 - Listar agentes (Priority: P2)

**Goal**: Listar o catalogo com nome, versao, descricao e alvos, marcando os instalados no projeto.

**Independent Test**: `agents list` mostra os campos do manifesto e marca instalados; `agents list --installed` mostra apenas instalados.

### Tests for User Story 2

- [X] T015 [P] [US2] Teste de listagem em `tests/test_list.sh` (catalogo com campos obrigatorios e marcacao de instalado; `--installed` filtra corretamente)

### Implementation for User Story 2

- [X] T016 [US2] Implementar comando de listagem em `lib/commands/list.sh` (varre `agents/*/manifest`, le lock para marcar instalados, suporta `--installed`)
- [X] T017 [US2] Ligar `list` ao dispatch em `bin/agents` conforme contracts/cli-commands.md

**Checkpoint**: US1 e US2 funcionam de forma independente

---

## Phase 5: User Story 3 - Atualizar um agente (Priority: P3)

**Goal**: Atualizar um agente instalado para a versao mais nova do catalogo, idempotente e sem tocar arquivos alheios.

**Independent Test**: Instalar versao antiga, rodar `agents update example-agent`; conferir troca de versao e que arquivos fora do lock nao mudaram.

### Tests for User Story 3

- [X] T018 [P] [US3] Teste de atualizacao em `tests/test_update.sh` (versao antiga -> nova reporta v->v'; ja na mais nova e no-op; nao instalado gera erro; arquivos alheios intactos)

### Implementation for User Story 3

- [X] T019 [US3] Implementar comando de atualizacao em `lib/commands/update.sh` (compara versao do catalogo vs lock, remove arquivos da versao antiga via lock e instala a nova, atualiza lock; reutiliza `lib/plan.sh` para conflito)
- [X] T020 [US3] Ligar `update` ao dispatch em `bin/agents` conforme contracts/cli-commands.md

**Checkpoint**: US1, US2 e US3 funcionam de forma independente

---

## Phase 6: User Story 4 - Remover um agente (Priority: P4)

**Goal**: Remover um agente instalado, restaurando o projeto ao estado anterior sem residuos e sem tocar arquivos alheios.

**Independent Test**: Instalar, rodar `agents remove example-agent`; conferir ausencia dos arquivos do agente e projeto restaurado; remover ausente e no-op.

### Tests for User Story 4

- [X] T021 [P] [US4] Teste de remocao em `tests/test_remove.sh` (remove apaga apenas arquivos do lock e as linhas; arquivos alheios intactos; remover nao instalado e no-op)

### Implementation for User Story 4

- [X] T022 [US4] Implementar comando de remocao em `lib/commands/remove.sh` (le arquivos do agente no lock, apaga-os, remove linhas do lock atomicamente; no-op se nao instalado)
- [X] T023 [US4] Ligar `remove` ao dispatch em `bin/agents` conforme contracts/cli-commands.md

**Checkpoint**: Todas as user stories funcionam de forma independente

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Distribuicao, documentacao e verificacao final

- [X] T024 [P] Implementar bootstrap `install.sh` na raiz (obtem/atualiza o repo via git e coloca `agents` no PATH, estilo skills.sh)
- [X] T025 [P] Escrever `README.md` com uso da CLI baseado em quickstart.md
- [X] T026 [P] Rodar shellcheck em `bin/agents`, `lib/**/*.sh`, `install.sh` e corrigir apontamentos
- [X] T027 Executar validacao do `specs/001-installer-cli/quickstart.md` cobrindo as 4 user stories de ponta a ponta, incluindo assercao de que nenhum arquivo de dependencia do projeto alvo e criado ou alterado (FR-016)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependencias, inicia imediatamente
- **Foundational (Phase 2)**: depende do Setup; BLOQUEIA todas as user stories
- **User Stories (Phase 3-6)**: dependem da Foundational; depois podem seguir em paralelo ou na ordem P1->P2->P3->P4
- **Polish (Phase 7)**: depende das user stories desejadas concluidas

### User Story Dependencies

- **US1 (P1)**: apos Foundational, sem dependencia de outras stories
- **US2 (P2)**: apos Foundational; le o lock produzido por US1 mas e testavel de forma independente com lock vazio ou pre populado no teste
- **US3 (P3)**: apos Foundational; reutiliza install/remove via lock, mas testavel de forma independente
- **US4 (P4)**: apos Foundational; testavel de forma independente

### Within Each User Story

- Testes escritos antes e devem falhar antes da implementacao
- `lib/plan.sh`/`lib/lock.sh` (Foundational) antes dos comandos
- Comando implementado antes de ser ligado ao dispatch

### Parallel Opportunities

- Setup: T002 e T003 em paralelo
- Foundational: T005, T006, T009 em paralelo; T004 antes de T007; T007 depois de T004/T005/T006
- Apos Foundational, US1..US4 podem ser desenvolvidas em paralelo por pessoas diferentes
- Testes marcados [P] de uma story rodam em paralelo

---

## Parallel Example: Foundational

```bash
Task: "Implementar lib/targets.sh"     # T005
Task: "Implementar lib/lock.sh"        # T006
Task: "Criar agents/example-agent/"    # T009
# T004 (manifest.sh) em seguida; T007 (plan.sh) depois de T004/T005/T006
```

## Parallel Example: User Story 1

```bash
Task: "Teste de instalacao em tests/test_install.sh"    # T010
Task: "Teste de conflito em tests/test_conflict.sh"     # T011
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1: Setup
2. Phase 2: Foundational (CRITICO, bloqueia tudo)
3. Phase 3: US1 Instalar
4. PARAR e VALIDAR US1 de forma independente
5. Entregar/demonstrar o MVP

### Incremental Delivery

1. Setup + Foundational -> nucleo pronto
2. US1 Instalar -> testar -> MVP
3. US2 Listar -> testar -> entregar
4. US3 Atualizar -> testar -> entregar
5. US4 Remover -> testar -> entregar

---

## Notes

- [P] = arquivos diferentes, sem dependencia
- [Story] mapeia a tarefa a uma user story para rastreabilidade
- Cada user story e completavel e testavel de forma independente
- Verificar que os testes falham antes de implementar
- Commit apos cada tarefa ou grupo logico
- Evitar: tarefas vagas, conflito no mesmo arquivo, dependencia entre stories que quebre a independencia
