# Implementation Plan: CLI de Instalacao de Agents

**Branch**: `001-installer-cli` | **Date**: 2026-07-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-installer-cli/spec.md`

## Summary

CLI de terminal, estilo skills.sh, para instalar, listar, atualizar e remover agentes do
repositorio em qualquer projeto, com suporte aos alvos Codex, Claude e OpenCode. Abordagem:
script POSIX sh unico com helpers em sh, instalacao dirigida por manifesto por agente,
rastreamento de estado por lockfile no projeto e deteccao de conflito em duas fases (planejar
depois aplicar) para garantir idempotencia e nao destruicao. Sem dependencia de runtime alem
de sh e git.

## Technical Context

**Language/Version**: POSIX sh (portavel entre dash/bash/zsh em modo POSIX)

**Primary Dependencies**: Git (clone/atualizacao do catalogo). Nenhuma outra dependencia de runtime.

**Storage**: Sistema de arquivos. Catalogo em `agents/` (Git); estado instalado em `.agents/lock` por projeto.

**Testing**: Scripts POSIX sh com helper de assercao minimo, rodando em diretorio temporario que simula um projeto alvo.

**Target Platform**: Ambientes POSIX (Linux, macOS).

**Project Type**: CLI (ferramenta de terminal, single project).

**Performance Goals**: Instalar um agente em menos de 1 minuto interativo (SC-001); operacoes locais de I/O, sem meta de throughput.

**Constraints**: Apenas sh e git em runtime (Principio II); idempotencia e nao destruicao obrigatorias (Principio III); zero alteracao nas dependencias do projeto alvo (FR-016).

**Scale/Scope**: Catalogo na ordem de dezenas a centenas de agentes; instalacao por projeto local.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Portabilidade Multi-Agente**: PASS. O instalador copia arquivos declarados por alvo no manifesto, sem bifurcar logica por alvo. Alvos suportados sao declarados no manifesto (`targets`).
- **II. Instalacao via Terminal sem Atrito**: PASS. Comando unico, apenas sh + git, instala em qualquer projeto sem alterar suas dependencias. Comandos install/update/remove/list explicitos.
- **III. Idempotencia e Nao Destruicao**: PASS. Lockfile + planejamento antes de aplicar + deteccao de conflito + remocao exata restauram o estado anterior; nunca sobrescreve arquivo do usuario sem consentimento.
- **IV. Contrato de Agente Explicito**: PASS. Descoberta, listagem, validacao e instalacao derivam do `manifest`; manifesto invalido/ausente rejeita o agente antes de escrever.
- **V. Simplicidade e Minimo de Dependencias**: PASS. Um script sh + helpers, manifesto e lock parseaveis em sh puro, sem jq/toolchains/frameworks. Destinos por alvo como dado (`targets.conf`), sem abstracao especulativa.

Resultado: nenhuma violacao. Complexity Tracking vazio.

## Project Structure

### Documentation (this feature)

```text
specs/001-installer-cli/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── cli-commands.md
└── tasks.md             # Phase 2 output (/speckit-tasks)
```

### Source Code (repository root)

```text
bin/
└── agents                 # entrypoint POSIX sh (dispatch de comandos)

lib/
├── manifest.sh            # parse e validacao do manifesto
├── targets.sh             # deteccao de alvo e resolucao de destinos (le targets.conf)
├── lock.sh                # leitura/escrita atomica do .agents/lock
├── plan.sh                # planejamento de escrita e deteccao de conflito
└── commands/
    ├── install.sh
    ├── update.sh
    ├── remove.sh
    └── list.sh

targets.conf               # mapa target -> dest_default, marker

agents/                    # catalogo (uma pasta por agente)
└── <name>/
    ├── manifest
    └── <arquivos por alvo>

install.sh                 # bootstrap: obtem o repo via git e poe `agents` no PATH

tests/
├── assert.sh              # helper minimo de assercao
├── test_install.sh
├── test_list.sh
├── test_update.sh
├── test_remove.sh
└── test_conflict.sh
```

**Structure Decision**: Single project CLI. O entrypoint `bin/agents` faz dispatch para
`lib/commands/*`; a logica compartilhada (manifesto, alvos, lock, planejamento) fica em
`lib/*.sh` carregada via source. Catalogo versionado em `agents/`. Destinos por alvo isolados
em `targets.conf` como calibration knob, confirmados contra a documentacao vigente de cada
ferramenta no inicio da Story 1.

**Escopo (fronteira com renderizadores)**: esta feature apenas instala, lista, atualiza e
remove arquivos ja organizados por alvo no manifesto. A geracao desses arquivos a partir de
uma fonte unica (renderizadores, Principio I) e feature separada e esta fora do escopo aqui.

## Complexity Tracking

> Nenhuma violacao da constituicao. Secao intencionalmente vazia.
