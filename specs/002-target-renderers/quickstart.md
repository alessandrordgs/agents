# Quickstart: Renderizadores por Alvo

**Feature**: 002-target-renderers

## O que muda

Um agente passa a ter uma unica definicao canonica (`agents/<nome>/agent.md`, formato Claude).
O instalador gera o artefato nativo de cada alvo na hora de instalar. Nao ha mais arquivos por
alvo escritos a mao no catalogo.

## Verificacao por user story

### US1 Codex (P1)

```sh
mkdir -p /tmp/proj/.codex && cd /tmp/proj
agents install ui-design-strategist --target codex
cat .codex/agents/ui-design-strategist.toml   # TOML valido com name/description/developer_instructions
```

### US2 OpenCode (P2)

```sh
mkdir -p /tmp/proj/.opencode && cd /tmp/proj
agents install ui-design-strategist --target opencode
cat .opencode/agent/ui-design-strategist.md   # frontmatter (description, mode: subagent) + corpo
```

### US3 Claude sem regressao (P3)

```sh
mkdir -p /tmp/proj/.claude && cd /tmp/proj
agents install ui-design-strategist --target claude
diff .claude/agents/ui-design-strategist.md ~/.agents/agents/ui-design-strategist/agent.md  # identico
```

## Garantias preservadas

```sh
agents install ui-design-strategist --target codex   # de novo: "nada a fazer" (idempotente)
agents remove ui-design-strategist                    # restaura o projeto
```

## Validacao TOML/YAML

Se houver ferramenta disponivel, validar o artefato:

```sh
# TOML
python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1],"rb"))' .codex/agents/ui-design-strategist.toml
```
