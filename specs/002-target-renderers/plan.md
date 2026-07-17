# Implementation Plan: Renderizadores por Alvo

**Branch**: `002-target-renderers` | **Date**: 2026-07-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-target-renderers/spec.md`

## Summary

Introduz renderizadores por alvo: cada agente passa a ter uma unica definicao canonica
(`agents/<nome>/agent.md`, formato Claude) e o instalador gera, no momento da instalacao, o
artefato nativo de cada alvo (Codex TOML em `.codex/agents`, OpenCode markdown em
`.opencode/agent`, Claude por passthrough). Substitui o modelo de arquivos por alvo escritos a
mao da feature 001, mantendo idempotencia, nao destruicao e remocao exata. Na v1 modelo e
restricoes de ferramentas nao sao traduzidos.

## Technical Context

**Language/Version**: POSIX sh (mesma base da feature 001)

**Primary Dependencies**: Git; nenhuma nova dependencia de runtime (parsing e geracao com awk/sed).

**Storage**: Sistema de arquivos. Fonte em `agents/<nome>/agent.md`; artefatos gerados no projeto; estado em `.agents/lock`.

**Testing**: Scripts POSIX sh com o helper de assercao existente; validacao de TOML/YAML gerado quando houver ferramenta.

**Target Platform**: Ambientes POSIX (Linux, macOS).

**Project Type**: CLI (single project), estende a feature 001.

**Performance Goals**: Renderizacao local instantanea; instalar em menos de 1 minuto (herdado).

**Constraints**: Apenas sh e git; render deterministico (idempotencia por conteudo); nunca sobrescrever arquivo do usuario.

**Scale/Scope**: Um artefato por alvo por agente na v1 (fonte unica, sem multiplos arquivos por alvo).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Portabilidade Multi-Agente**: PASS e reforcado. Esta feature implementa exatamente a fonte unica adaptada por renderizadores. Fim das copias divergentes por alvo.
- **II. Instalacao via Terminal sem Atrito**: PASS. Continua apenas sh + git; render com awk/sed, sem novas dependencias.
- **III. Idempotencia e Nao Destruicao**: PASS. Render deterministico; idempotencia compara conteudo renderizado; conflito, lock e remocao exata herdados da feature 001.
- **IV. Contrato de Agente Explicito**: PASS. Manifesto continua a fonte de verdade; novo schema declara `source` e `targets`, validado antes de qualquer escrita.
- **V. Simplicidade e Minimo de Dependencias**: PASS. Um `lib/render.sh` com awk/sed; strings robustas via TOML literal e YAML aspado; sem parsers externos. Ceilings marcados (sequencia `'''` no corpo).

Resultado: nenhuma violacao. Complexity Tracking vazio.

## Project Structure

### Documentation (this feature)

```text
specs/002-target-renderers/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── renderers.md
└── tasks.md            # /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── render.sh           # NOVO: render_target + normalizacao + escaping
├── manifest.sh         # MOD: novo schema (source + targets), validacao
├── plan.sh             # MOD: planeja 1 artefato renderizado por alvo
└── commands/
    ├── install.sh      # MOD: renderiza a fonte para temp e instala
    ├── update.sh       # MOD: usa install_agent (herdado)
    └── list.sh         # MOD: exibe targets do novo schema

targets.conf            # MOD: corrige dest do codex; adiciona coluna ext

agents/<nome>/          # MIGRACAO: agent.md canonico; remove arquivos por alvo
├── agent.md
└── manifest            # novo schema

tests/                  # MOD: atualiza catalogos temporarios e assercoes
├── test_render.sh      # NOVO: valida saida por alvo (TOML/YAML/passthrough)
└── ... (install/conflict/list/update/select ajustados ao novo schema)
```

**Structure Decision**: Estende a CLI da feature 001. O novo `lib/render.sh` concentra a
transformacao por alvo; `install_agent` passa a renderizar a fonte para um arquivo temporario
e reutiliza a maquinaria de plano/conflito/lock ja existente (o temp vira a origem da copia).
O schema do manifesto muda de blocos por alvo para `source` + `targets`, e os agentes do
catalogo sao migrados para a fonte canonica unica. `targets.conf` ganha a extensao por alvo e
corrige o destino do Codex.

## Complexity Tracking

> Nenhuma violacao da constituicao. Secao intencionalmente vazia.
