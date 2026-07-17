# agents

Instalador de agentes via terminal, no estilo skills.sh, para qualquer projeto.
Suporta os alvos Codex, Claude e OpenCode. Dependencias de runtime: apenas shell
POSIX e Git.

## Instalacao

Um comando, sem clonar nada a mao:

```sh
curl -fsSL https://raw.githubusercontent.com/alessandrordgs/agents/main/install.sh | sh
```

O bootstrap clona o repositorio em `~/.local/share/agents` e cria o comando
`agents` em `~/.local/bin`. Rodar de novo apenas atualiza (`git pull`). Se voce ja
tem o repo clonado, `sh install.sh` faz o mesmo.

Variaveis de ambiente reconhecidas:

- `AGENTS_REPO`: URL do repositorio a clonar (default: o repo oficial)
- `AGENTS_HOME`: onde o repositorio fica (default: `~/.local/share/agents`)
- `AGENTS_BINDIR`: onde o link `agents` e criado (default: `~/.local/bin`)

Se `AGENTS_BINDIR` nao estiver no seu PATH, o script avisa. O repositorio precisa
ficar em disco porque os agentes sao renderizados de la para o seu projeto; o
`curl | sh` so evita o clone manual. Se o diretorio de destino ja existir e nao for
uma instalacao do agents, o script avisa e nao altera nada.

## Uso

```sh
agents install                   # modo interativo: escolha da lista o que instalar
agents install <nome> [<nome>...] # instala um ou mais agentes pelo nome
agents install <nome> --target claude
agents list                      # catalogo; marca com * os instalados no projeto
agents list --installed          # apenas os instalados no projeto atual
agents update <nome>             # atualiza um agente para a versao mais nova
agents remove <nome>             # remove, restaurando o estado anterior
agents --update                  # atualiza o agents e re-renderiza os instalados aqui
agents --help
```

Todos os comandos operam sobre o diretorio atual (o projeto). Execute-os a partir
da raiz do projeto onde quer instalar o agente.

### Modo interativo

Rodar `agents install` sem informar nome abre um seletor de setas:

```text
Selecione os agentes:  setas/jk move · espaco marca · a todos · enter confirma · q cancela
> [x] ui-design-strategist  Diretor de design senior que faz descoberta...
  [ ] frontend-dev          Desenvolvedor frontend senior (Next.js/RN)...
  [x] example-agent         Agente de exemplo usado como fixture de testes
```

Setas (ou `j`/`k`) movem, espaco marca/desmarca, `a` alterna todos, Enter
confirma, `q` (ou Esc) cancela. Quando a entrada nao e um terminal (pipe, CI), o
comando cai numa lista numerada que aceita `1,3`, `1 3` ou `all`. O alvo e
resolvido uma vez para toda a selecao (detectado pelo projeto ou via `--target`).

### Deteccao de alvo

O alvo e detectado pela presenca de `.claude/`, `.codex/` ou `.opencode/` no
projeto. Se houver exatamente um, ele e usado automaticamente. Se houver mais de
um, ou nenhum, informe `--target`:

```sh
agents install code-reviewer --target codex
```

`--target` sempre tem precedencia sobre a deteccao automatica.

### Garantias

- Idempotente: rodar `install`/`update` de novo com o mesmo estado nao muda nada.
- Nao destrutivo: nunca sobrescreve arquivos que nao sao do agente. Em conflito, a
  operacao aborta sem alterar nada (codigo de saida 3).
- Reversivel: `remove` apaga apenas os arquivos registrados em `.agents/lock`,
  restaurando o projeto ao estado anterior a instalacao.

### Codigos de saida

| Codigo | Significado |
|--------|-------------|
| 0 | Sucesso ou nada a fazer |
| 2 | Uso invalido (argumento faltando/desconhecido) |
| 3 | Conflito com arquivo existente do usuario |
| 4 | Agente desconhecido, manifesto invalido ou alvo nao suportado |
| 5 | Alvo nao detectado/desconhecido |

## Agentes disponiveis

| Agente | Alvos | Descricao |
|--------|-------|-----------|
| `ui-design-strategist` | claude, codex, opencode | Diretor de design senior que faz descoberta antes de propor direcao visual |
| `frontend-dev` | claude, codex, opencode | Desenvolvedor frontend senior (Next.js/React e React Native/Expo) que executa design e correcoes |
| `example-agent` | claude, codex, opencode | Agente de exemplo usado como fixture de testes |

Rode `agents list` para ver a versao e a marcacao de instalados no seu projeto.

## Como adicionar um novo agente

Cada agente tem uma unica definicao canonica no formato de agente do Claude
(frontmatter + corpo). Na instalacao, essa fonte e renderizada para o formato
nativo de cada alvo: Claude por copia direta, Codex vira TOML em `.codex/agents`,
OpenCode vira markdown em `.opencode/agent`. Voce escreve uma vez, instala nos tres.

### 1. Crie a estrutura

```sh
mkdir -p agents/meu-agente
```

### 2. Escreva a fonte canonica

`agents/meu-agente/agent.md`, no formato de agente do Claude (frontmatter YAML com
`name` e `description`, seguido do corpo que sera as instrucoes do agente):

```markdown
---
name: meu-agente
description: descricao em uma linha do que o agente faz
---

# Papel

Instrucoes do agente. Este corpo vira o system prompt em todos os alvos.
```

### 3. Escreva o manifesto

`agents/meu-agente/manifest` (formato linha a linha, sem JSON/YAML):

```text
name: meu-agente
version: 1.0.0
description: descricao em uma linha do que o agente faz
source: agent.md
targets: claude codex opencode
```

Regras do manifesto:

- `name`, `version`, `description` e `source` sao obrigatorios. `name` deve bater
  com o nome do diretorio; `version` segue versionamento semantico.
- `source` aponta para a fonte canonica dentro de `agents/<nome>/` (e precisa existir).
- `targets` lista os alvos suportados (separados por espaco); cada alvo deve constar
  em `targets.conf`.
- Um manifesto ausente ou invalido faz o agente ser rejeitado antes de qualquer
  escrita no projeto.

### 4. Como cada alvo e gerado

- **claude**: a fonte e instalada como esta em `.claude/agents/<nome>.md` (passthrough).
- **codex**: gera `.codex/agents/<nome>.toml` com `name` (normalizado), `description`
  e `developer_instructions` (o corpo).
- **opencode**: gera `.opencode/agent/<nome>.md` com frontmatter (`description`,
  `mode: subagent`) e o corpo como system prompt.

Na v1 o modelo e as restricoes de ferramentas da fonte nao sao propagados para os
artefatos renderizados (herdam a sessao do alvo).

### 5. Valide e teste

```sh
mkdir -p /tmp/proj/.codex && cd /tmp/proj
AGENTS_HOME=/caminho/para/o/repo /caminho/para/o/repo/bin/agents install meu-agente --target codex
cat .codex/agents/meu-agente.toml   # confira o artefato gerado
agents remove meu-agente            # deve restaurar o estado
```

Um manifesto invalido retorna codigo 4 e nao escreve nada.

## Alvos suportados

Os alvos e seus destinos padrao ficam em `targets.conf`
(`target|dest_default|marker|min_version|ext`):

| Alvo | Destino padrao | Marcador | Versao minima | Artefato |
|------|----------------|----------|---------------|----------|
| claude | `.claude/agents` | `.claude` | 1.0 | `.md` |
| codex | `.codex/agents` | `.codex` | 0.1 | `.toml` |
| opencode | `.opencode/agent` | `.opencode` | 0.1 | `.md` |

Para ajustar um destino ou adicionar um novo alvo, edite `targets.conf`.

## Testes

```sh
for t in tests/test_*.sh; do sh "$t" || exit 1; done
```

Os testes rodam em diretorios temporarios que simulam projetos alvo; nao tocam no
seu ambiente.

## Estrutura do repositorio

```text
bin/agents            entrypoint (dispatch dos comandos)
lib/                  nucleo (manifest, targets, lock, plan, render) e lib/commands/
targets.conf          matriz de alvos suportados
agents/<nome>/        catalogo: agent.md (fonte canonica) + manifest
install.sh            bootstrap de instalacao da CLI
tests/                testes em POSIX sh
```
