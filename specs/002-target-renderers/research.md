# Research: Renderizadores por Alvo

**Feature**: 002-target-renderers | **Date**: 2026-07-17

Formatos verificados em docs oficiais e repos antes do planejamento.

## Decisao 1: Fonte canonica unica por agente

- **Decision**: Cada agente tem um unico arquivo canonico `agents/<nome>/agent.md` no formato de agente do Claude (frontmatter com name/description/tools/model + corpo). O manifesto declara `source` e a lista `targets`.
- **Rationale**: Cumpre o Principio I (fonte unica, adaptada por renderizadores). Elimina os arquivos por alvo escritos a mao do modelo da feature 001.
- **Alternatives considered**: Formato neutro proprio (mais trabalho, sem ganho, ja que o formato Claude carrega tudo que precisamos); manter blocos por alvo no manifesto (duplicacao, era o que queriamos remover).

## Decisao 2: Formato e destino do Codex

- **Decision**: Gerar TOML em `.codex/agents/<nome>.toml` com `name`, `description`, `developer_instructions`. Corrige o destino anterior `.codex/prompts` (que e global e deprecado).
- **Rationale**: Pesquisa confirmou que o subagente por projeto do Codex vive em `.codex/agents/*.toml`; `~/.codex/prompts/` e global e deprecado. Fontes: developers.openai.com/codex/subagents, github.com/openai/codex.
- **String do corpo**: usar TOML multiline literal `'''...'''`, que nao processa escapes, seguro para markdown arbitrario (aspas, barras, crases). Ceiling: corpo contendo a sequencia `'''` quebraria; improvavel em prompt de agente, tratado como limite conhecido.
- **Nome**: normalizar para identificador valido (trocar tudo fora de `[A-Za-z0-9_]` por `_`), ex `ui-design-strategist` -> `ui_design_strategist`. O filename mantem `<nome>.toml`.
- **Alternatives considered**: `.codex/prompts` (errado, global-only e deprecado); multiline basic `"""` (processa escapes, exigiria escapar o corpo).

## Decisao 3: Formato e destino do OpenCode

- **Decision**: Gerar markdown em `.opencode/agent/<nome>.md` com frontmatter `description` e `mode: subagent`, seguido do corpo como system prompt.
- **Rationale**: Pesquisa confirmou, no codigo real do repo sst/opencode, o diretorio singular `.opencode/agent/` (a doc diz plural, mas binario e dogfooding usam singular). Corpo do markdown vira o system prompt. Fonte: opencode.ai/docs/agents, github.com/sst/opencode (.opencode/agent, issue #2970).
- **Description em YAML**: emitir entre aspas duplas com escape de `\` e `"`, porque as descricoes dos agentes contem aspas (ex: "design", "UI"). Evita quebrar o YAML.
- **Alternatives considered**: campo `tools` (deprecado em favor de `permission`, e fora do escopo v1); diretorio plural `.opencode/agents` (nao lido pelo binario).

## Decisao 4: Claude por passthrough

- **Decision**: Para o alvo Claude, escrever a fonte canonica sem transformacao em `.claude/agents/<nome>.md`.
- **Rationale**: A fonte ja e formato Claude; renderizar seria identidade. Garante zero regressao (SC-005).

## Decisao 5: Modelo e ferramentas nao traduzidos (v1)

- **Decision**: Nao propagar `model` nem traduzir restricoes de `tools` da fonte para os artefatos. Artefatos herdam o modelo da sessao do alvo.
- **Rationale**: Alias de modelo do Claude (ex `sonnet`) nao mapeia para id de modelo do Codex nem para `provider/model` do OpenCode; traduzir erraria. Restricao de ferramentas tem modelos muito diferentes por alvo (sandbox_mode no Codex, permission no OpenCode). Escopo v1 fica correto e pequeno; traducao pode vir depois.
- **Alternatives considered**: Mapear modelos por tabela (fragil, alto risco de gerar id invalido); traduzir tools (superficie grande, adiado).

## Decisao 6: Extensao do artefato por alvo

- **Decision**: Guardar a extensao do artefato em `targets.conf` como coluna adicional (claude=md, codex=toml, opencode=md). O filename do artefato e `<nome>.<ext>`.
- **Rationale**: Mantem os detalhes de alvo como dado (calibration knob), coerente com a feature 001.

## Decisao 7: Idempotencia sobre o artefato renderizado

- **Decision**: A comparacao de idempotencia usa o conteudo renderizado (resultado da transformacao), nao o arquivo de origem. Render e deterministico, entao reinstalar gera bytes identicos e o `cmp` detecta no-op.
- **Rationale**: Preserva FR-011/SC-004 mesmo com transformacao no meio.
