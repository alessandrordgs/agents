# agents

Instale agentes de IA em qualquer projeto com um comando, direto do terminal.
Você escreve o agente uma vez; ele é instalado de forma nativa no **Claude**, no
**Codex** ou no **OpenCode**. No estilo do skills.sh. As únicas dependências são
shell POSIX e Git.

---

## Instalação

```sh
curl -fsSL https://raw.githubusercontent.com/alessandrordgs/agents/main/install.sh | sh
```

O bootstrap clona o repositório em `~/.local/share/agents` e cria o comando `agents`
em `~/.local/bin`. Se esse diretório não estiver no seu PATH, o script mostra a linha
do `export PATH` para colar no `~/.bashrc` ou `~/.zshrc`. Rodar de novo só atualiza.

Variáveis opcionais:

| Variável | Padrão | Para que serve |
|----------|--------|----------------|
| `AGENTS_REPO` | repositório oficial | URL do repositório a clonar |
| `AGENTS_HOME` | `~/.local/share/agents` | onde o repositório fica |
| `AGENTS_BINDIR` | `~/.local/bin` | onde o comando `agents` é criado |

---

## Primeiros passos

Entre no projeto onde quer os agentes (o que tem `.claude/`, `.codex/` ou `.opencode/`)
e escolha da lista:

```sh
cd meu-projeto
agents list        # vê o catálogo
agents install     # abre o seletor e instala o que você marcar
```

Pronto: os arquivos do agente aparecem no lugar certo do seu alvo, prontos para uso.

---

## Comandos

| Comando | O que faz |
|---------|-----------|
| `agents install` | Seletor interativo: escolha da lista o que instalar |
| `agents install <nome> [<nome>...]` | Instala um ou mais agentes pelo nome |
| `agents install <nome> --target claude` | Força o alvo (em vez de detectar) |
| `agents list` | Lista o catálogo; marca com `*` os instalados no projeto |
| `agents list --installed` | Lista só os instalados no projeto atual |
| `agents update <nome>` | Atualiza um agente para a versão mais nova do catálogo |
| `agents remove <nome>` | Remove um agente, restaurando o estado anterior |
| `agents --update` | Atualiza o próprio agents e re-renderiza os instalados aqui |
| `agents --help` | Ajuda |

Todos os comandos agem sobre o diretório atual. Rode-os na raiz do projeto.

---

## Seletor interativo

`agents install` sem nome abre um seletor de setas:

```text
Escolha os agentes  setas marca com espaco · a todos · enter confirma · q cancela
 › ● ui-design-strategist  Diretor de design senior que faz descoberta...
   ○ frontend-dev          Desenvolvedor frontend senior (Next.js/RN)...
 1 marcado(s)
```

Setas (ou `j`/`k`) movem, espaço marca, `a` alterna todos, Enter confirma, `q`/Esc
cancela. A linha atual fica destacada e os marcados aparecem com `●` verde. Fora de um
terminal (pipe, CI) ele vira uma lista numerada que aceita `1,3`, `1 3` ou `all`.

---

## Detecção de alvo

O alvo é escolhido pela presença de `.claude/`, `.codex/` ou `.opencode/` no projeto.
Havendo exatamente um, ele é usado sozinho. Com nenhum ou vários, informe `--target`,
que sempre tem precedência:

```sh
agents install ui-design-strategist --target codex
```

---

## Atualização

```sh
agents --update
```

Puxa a versão nova do catálogo e re-renderiza os agentes já instalados no projeto
atual (atualiza conteúdo e versão). Rodando em um terminal, o agents também avisa no
máximo uma vez por dia quando há versão nova, e só quando há de fato. Desligue com
`AGENTS_NO_UPDATE_CHECK=1`.

---

## Como um agente vira nativo de cada alvo

Uma única fonte por agente (`agent.md`, formato Claude) é transformada na instalação:

| Alvo | Onde é instalado | Formato gerado |
|------|------------------|----------------|
| claude | `.claude/agents/<nome>.md` | cópia direta da fonte |
| codex | `.codex/agents/<nome>.toml` | TOML com `name`, `description`, `developer_instructions` |
| opencode | `.opencode/agent/<nome>.md` | markdown com frontmatter (`description`, `mode: subagent`) + corpo |

Na versão atual, o modelo e as restrições de ferramentas declarados na fonte não são
propagados para os artefatos; eles herdam a sessão do alvo.

---

## Garantias

- **Idempotente**: instalar ou atualizar de novo, com o mesmo estado, não muda nada.
- **Não destrutivo**: nunca sobrescreve arquivo seu. Em conflito, aborta sem alterar nada.
- **Reversível**: `remove` apaga apenas o que consta em `.agents/lock`, voltando ao estado anterior.

---

## Adicionar um agente ao catálogo

Um agente é uma pasta em `agents/<nome>/` com dois arquivos: a fonte canônica e o manifesto.

**1. A fonte** `agents/meu-agente/agent.md`, no formato de agente do Claude:

```markdown
---
name: meu-agente
description: descrição em uma linha do que o agente faz
---

# Papel

Instruções do agente. Este corpo vira o system prompt em todos os alvos.
```

**2. O manifesto** `agents/meu-agente/manifest`:

```text
name: meu-agente
version: 1.0.0
description: descrição em uma linha do que o agente faz
source: agent.md
targets: claude codex opencode
```

Regras: `name`, `version`, `description` e `source` são obrigatórios; `name` bate com o
nome da pasta; `source` aponta para um arquivo existente; `targets` lista alvos que
constam em `targets.conf`. Manifesto ausente ou inválido faz o agente ser rejeitado
antes de qualquer escrita.

**3. Teste** num projeto descartável:

```sh
mkdir -p /tmp/proj/.codex && cd /tmp/proj
AGENTS_HOME=/caminho/do/repo /caminho/do/repo/bin/agents install meu-agente --target codex
cat .codex/agents/meu-agente.toml
```

---

## Referência

### Códigos de saída

| Código | Significado |
|--------|-------------|
| 0 | Sucesso ou nada a fazer |
| 2 | Uso inválido (argumento faltando ou desconhecido) |
| 3 | Conflito com arquivo existente do usuário |
| 4 | Agente desconhecido, manifesto inválido ou alvo não suportado |
| 5 | Alvo não detectado ou desconhecido |

### Alvos suportados (`targets.conf`)

Formato `target|dest_default|marker|min_version|ext`:

| Alvo | Destino padrão | Marcador | Versão mínima | Artefato |
|------|----------------|----------|---------------|----------|
| claude | `.claude/agents` | `.claude` | 1.0 | `.md` |
| codex | `.codex/agents` | `.codex` | 0.1 | `.toml` |
| opencode | `.opencode/agent` | `.opencode` | 0.1 | `.md` |

### Estrutura do repositório

```text
bin/agents      entrypoint (dispatch dos comandos)
lib/            núcleo: manifest, targets, lock, plan, render, tui, selfupdate
lib/commands/   install, list, update, remove
targets.conf    matriz de alvos suportados
agents/<nome>/  catálogo: agent.md (fonte canônica) + manifest
install.sh      bootstrap de instalação da CLI
tests/          testes em POSIX sh
```

### Testes

```sh
for t in tests/test_*.sh; do sh "$t" || exit 1; done
```

Rodam em diretórios temporários que simulam projetos; não tocam no seu ambiente.
