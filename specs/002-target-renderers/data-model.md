# Data Model: Renderizadores por Alvo

**Feature**: 002-target-renderers | **Date**: 2026-07-17

## Entidade: Definicao canonica do agente

Arquivo unico `agents/<nome>/agent.md` no formato de agente do Claude.

| Parte | Conteudo | Regras |
|-------|----------|--------|
| frontmatter | name, description, (opcional) tools, model | name e description obrigatorios |
| corpo | instrucoes do agente (markdown) | usado como instrucoes em todos os alvos |

## Manifesto (novo schema)

Arquivo `agents/<nome>/manifest`. Substitui os blocos por alvo da feature 001.

```text
name: <nome>
version: <semver>
description: <uma linha>
source: agent.md
targets: claude codex opencode
```

Regras de validacao (antes de qualquer escrita, FR-010):

- `name`, `version`, `description`, `source` presentes e nao vazios.
- `source` aponta para um arquivo existente em `agents/<nome>/`.
- `targets` nao vazio; cada alvo listado deve constar em `targets.conf`.

## Entidade: Alvo (targets.conf, novo campo ext)

Formato: `id|dest_default|marker|min_version|ext`

| Campo | Exemplo | Uso |
|-------|---------|-----|
| id | claude / codex / opencode | identificador do alvo |
| dest_default | .claude/agents / .codex/agents / .opencode/agent | destino no projeto |
| marker | .claude / .codex / .opencode | deteccao do alvo |
| min_version | 1.0 / 0.1 / 0.1 | matriz de compatibilidade |
| ext | md / toml / md | extensao do artefato renderizado |

## Entidade: Renderizador de alvo

Regra que transforma a definicao canonica no artefato do alvo. Um por alvo.

| Alvo | Transformacao | Saida |
|------|---------------|-------|
| claude | passthrough (copia a fonte) | `<nome>.md` |
| codex | TOML: name (normalizado), description, developer_instructions (corpo) | `<nome>.toml` |
| opencode | frontmatter (description, mode: subagent) + corpo | `<nome>.md` |

Normalizacao de nome (codex): caracteres fora de `[A-Za-z0-9_]` viram `_`.

## Entidade: Artefato renderizado

Arquivo gerado no formato do alvo, escrito em `<dest>/<nome>.<ext>` no projeto. Registrado no lock (`.agents/lock`) como na feature 001, herdando idempotencia, conflito e remocao exata.

## Transicoes

Iguais as da feature 001 (nao instalado -> instalado -> removido), agora com o artefato sendo o resultado da renderizacao. Idempotencia compara o conteudo renderizado com o instalado.
