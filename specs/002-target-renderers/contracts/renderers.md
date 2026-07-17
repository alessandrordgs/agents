# Contract: renderizadores

**Feature**: 002-target-renderers | **Date**: 2026-07-17

Interface interna de renderizacao usada pelo instalador. Entrada: fonte canonica
(`agents/<nome>/agent.md`) e nome do agente. Saida: conteudo do artefato no stdout.

## render_target <target> <source_file> <name>

Ecoa no stdout o artefato do alvo. Nunca escreve em disco (o instalador cuida da escrita,
do conflito e do lock).

### claude

Passthrough: emite o conteudo de `<source_file>` sem alteracao.

### codex

Emite TOML:

```toml
name = "<name normalizado>"
description = "<description em basic string, escapando \\ e ">"
developer_instructions = '''
<corpo do agente, sem o frontmatter>
'''
```

- `name` normalizado: `[^A-Za-z0-9_]` -> `_`.
- `description`: TOML basic string entre aspas, escape de `\` e `"`.
- `developer_instructions`: TOML multiline literal `'''...'''` (sem processar escapes).

### opencode

Emite markdown:

```markdown
---
description: "<description escapando \\ e ">"
mode: subagent
---
<corpo do agente, sem o frontmatter>
```

- Sem campo de modelo nem de ferramentas na v1.

## Extracao a partir da fonte canonica

- Frontmatter delimitado por `---` na primeira e proxima linha.
- `name`, `description`: lidos do frontmatter (chave: valor).
- corpo: tudo apos o segundo `---`.
- Fonte sem frontmatter valido ou sem name/description: renderizacao recusada (erro), nada escrito.

## Integracao com o instalador

Para o alvo resolvido:
1. `dest` = destino do alvo (targets.conf) ou override do manifesto.
2. `ext` = extensao do alvo (targets.conf).
3. artefato = `render_target <target> <source> <name>` gravado em temp.
4. destrel = `<dest>/<name>.<ext>`.
5. deteccao de conflito, copia e lock seguem a feature 001 (o temp e a origem).
6. idempotencia: compara o artefato renderizado (temp) com o arquivo instalado.
