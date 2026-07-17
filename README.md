# agents

Instale agentes de IA em qualquer projeto com um comando, direto do terminal.
Voce escreve o agente uma vez; ele e instalado de forma nativa no **Claude**, no
**Codex** ou no **OpenCode**. No estilo do skills.sh. As unicas dependencias sao
shell POSIX e Git.

---

## Instalacao

```sh
curl -fsSL https://raw.githubusercontent.com/alessandrordgs/agents/main/install.sh | sh
```

O bootstrap clona o repositorio em `~/.local/share/agents` e cria o comando `agents`
em `~/.local/bin`. Se esse diretorio nao estiver no seu PATH, o script mostra a linha
do `export PATH` para colar no `~/.bashrc` ou `~/.zshrc`. Rodar de novo so atualiza.

Variaveis opcionais:

| Variavel | Default | Para que serve |
|----------|---------|----------------|
| `AGENTS_REPO` | repo oficial | URL do repositorio a clonar |
| `AGENTS_HOME` | `~/.local/share/agents` | onde o repositorio fica |
| `AGENTS_BINDIR` | `~/.local/bin` | onde o comando `agents` e criado |

---

## Primeiros passos

Entre no projeto onde quer os agentes (o que tem `.claude/`, `.codex/` ou `.opencode/`)
e escolha da lista:

```sh
cd meu-projeto
agents list        # ve o catalogo
agents install     # abre o seletor e instala o que voce marcar
```

Pronto: os arquivos do agente aparecem no lugar certo do seu alvo, prontos para uso.

---

## Comandos

| Comando | O que faz |
|---------|-----------|
| `agents install` | Seletor interativo: escolha da lista o que instalar |
| `agents install <nome> [<nome>...]` | Instala um ou mais agentes pelo nome |
| `agents install <nome> --target claude` | Forca o alvo (em vez de detectar) |
| `agents list` | Lista o catalogo; marca com `*` os instalados no projeto |
| `agents list --installed` | Lista so os instalados no projeto atual |
| `agents update <nome>` | Atualiza um agente para a versao mais nova do catalogo |
| `agents remove <nome>` | Remove um agente, restaurando o estado anterior |
| `agents --update` | Atualiza o proprio agents e re-renderiza os instalados aqui |
| `agents --help` | Ajuda |

Todos os comandos agem sobre o diretorio atual. Rode-os na raiz do projeto.

---

## Seletor interativo

`agents install` sem nome abre um seletor de setas:

```text
Selecione os agentes:  setas/jk move · espaco marca · a todos · enter confirma · q cancela
> [x] ui-design-strategist  Diretor de design senior que faz descoberta...
  [ ] frontend-dev          Desenvolvedor frontend senior (Next.js/RN)...
  [x] example-agent         Agente de exemplo usado como fixture de testes
```

Setas (ou `j`/`k`) movem, espaco marca, `a` alterna todos, Enter confirma, `q`/Esc
cancela. Fora de um terminal (pipe, CI) ele vira uma lista numerada que aceita `1,3`,
`1 3` ou `all`.

---

## Deteccao de alvo

O alvo e escolhido pela presenca de `.claude/`, `.codex/` ou `.opencode/` no projeto.
Havendo exatamente um, ele e usado sozinho. Com nenhum ou varios, informe `--target`,
que sempre tem precedencia:

```sh
agents install ui-design-strategist --target codex
```

---

## Atualizacao

```sh
agents --update
```

Puxa a versao nova do catalogo e re-renderiza os agentes ja instalados no projeto
atual (atualiza conteudo e versao). Rodando em um terminal, o agents tambem avisa no
maximo uma vez por dia quando ha versao nova, e so quando ha de fato. Desligue com
`AGENTS_NO_UPDATE_CHECK=1`.

---

## Como um agente vira nativo de cada alvo

Uma unica fonte por agente (`agent.md`, formato Claude) e transformada na instalacao:

| Alvo | Onde e instalado | Formato gerado |
|------|------------------|----------------|
| claude | `.claude/agents/<nome>.md` | copia direta da fonte |
| codex | `.codex/agents/<nome>.toml` | TOML com `name`, `description`, `developer_instructions` |
| opencode | `.opencode/agent/<nome>.md` | markdown com frontmatter (`description`, `mode: subagent`) + corpo |

Na versao atual, o modelo e as restricoes de ferramentas declarados na fonte nao sao
propagados para os artefatos; eles herdam a sessao do alvo.

---

## Garantias

- **Idempotente**: instalar ou atualizar de novo, com o mesmo estado, nao muda nada.
- **Nao destrutivo**: nunca sobrescreve arquivo seu. Em conflito, aborta sem alterar nada.
- **Reversivel**: `remove` apaga apenas o que consta em `.agents/lock`, voltando ao estado anterior.

---

## Adicionar um agente ao catalogo

Um agente e uma pasta em `agents/<nome>/` com dois arquivos: a fonte canonica e o manifesto.

**1. A fonte** `agents/meu-agente/agent.md`, no formato de agente do Claude:

```markdown
---
name: meu-agente
description: descricao em uma linha do que o agente faz
---

# Papel

Instrucoes do agente. Este corpo vira o system prompt em todos os alvos.
```

**2. O manifesto** `agents/meu-agente/manifest`:

```text
name: meu-agente
version: 1.0.0
description: descricao em uma linha do que o agente faz
source: agent.md
targets: claude codex opencode
```

Regras: `name`, `version`, `description` e `source` sao obrigatorios; `name` bate com o
nome da pasta; `source` aponta para um arquivo existente; `targets` lista alvos que
constam em `targets.conf`. Manifesto ausente ou invalido faz o agente ser rejeitado
antes de qualquer escrita.

**3. Teste** num projeto descartavel:

```sh
mkdir -p /tmp/proj/.codex && cd /tmp/proj
AGENTS_HOME=/caminho/do/repo /caminho/do/repo/bin/agents install meu-agente --target codex
cat .codex/agents/meu-agente.toml
```

---

## Referencia

### Codigos de saida

| Codigo | Significado |
|--------|-------------|
| 0 | Sucesso ou nada a fazer |
| 2 | Uso invalido (argumento faltando ou desconhecido) |
| 3 | Conflito com arquivo existente do usuario |
| 4 | Agente desconhecido, manifesto invalido ou alvo nao suportado |
| 5 | Alvo nao detectado ou desconhecido |

### Alvos suportados (`targets.conf`)

Formato `target|dest_default|marker|min_version|ext`:

| Alvo | Destino padrao | Marcador | Versao minima | Artefato |
|------|----------------|----------|---------------|----------|
| claude | `.claude/agents` | `.claude` | 1.0 | `.md` |
| codex | `.codex/agents` | `.codex` | 0.1 | `.toml` |
| opencode | `.opencode/agent` | `.opencode` | 0.1 | `.md` |

### Estrutura do repositorio

```text
bin/agents      entrypoint (dispatch dos comandos)
lib/            nucleo: manifest, targets, lock, plan, render, tui, selfupdate
lib/commands/   install, list, update, remove
targets.conf    matriz de alvos suportados
agents/<nome>/  catalogo: agent.md (fonte canonica) + manifest
install.sh      bootstrap de instalacao da CLI
tests/          testes em POSIX sh
```

### Testes

```sh
for t in tests/test_*.sh; do sh "$t" || exit 1; done
```

Rodam em diretorios temporarios que simulam projetos; nao tocam no seu ambiente.
