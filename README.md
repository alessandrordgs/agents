# agents

Instalador de agentes via terminal, no estilo skills.sh, para qualquer projeto.
Suporta os alvos Codex, Claude e OpenCode. Dependencias de runtime: apenas shell
POSIX e Git.

## Instalacao

```sh
sh install.sh
```

Isso clona/atualiza o repositorio e cria o comando `agents` em `~/.local/bin`.
Variaveis de ambiente reconhecidas:

- `AGENTS_REPO`: URL do repositorio a clonar (default: o repo oficial)
- `AGENTS_HOME`: onde o repositorio fica (default: `~/.agents`)
- `AGENTS_BINDIR`: onde o link `agents` e criado (default: `~/.local/bin`)

Se `AGENTS_BINDIR` nao estiver no seu PATH, o script avisa.

## Uso

```sh
agents list                      # catalogo; marca com * os instalados no projeto
agents list --installed          # apenas os instalados no projeto atual
agents install <nome>            # detecta o alvo pelo projeto
agents install <nome> --target claude
agents update <nome>             # atualiza para a versao mais nova do catalogo
agents remove <nome>             # remove, restaurando o estado anterior
agents --help
```

Todos os comandos operam sobre o diretorio atual (o projeto). Execute-os a partir
da raiz do projeto onde quer instalar o agente.

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

## Como adicionar um novo agente

Um agente e um diretorio em `agents/<nome>/` contendo um arquivo `manifest` e os
arquivos que serao instalados, organizados por alvo.

### 1. Crie a estrutura

```sh
mkdir -p agents/meu-agente/claude
```

Repita para cada alvo que o agente vai suportar (`codex`, `opencode`). Os
subdiretorios por alvo sao apenas uma convencao de organizacao; o que vale sao os
caminhos declarados no manifesto.

### 2. Adicione os arquivos do agente

Coloque os arquivos que cada ferramenta espera. Exemplo para Claude:

```sh
cat > agents/meu-agente/claude/meu-agente.md <<'EOF'
# Meu Agente

Instrucoes do agente para o Claude.
EOF
```

### 3. Escreva o manifesto

`agents/meu-agente/manifest` (formato linha a linha, sem JSON/YAML):

```text
name: meu-agente
version: 1.0.0
description: descricao em uma linha do que o agente faz
target: claude
  dest: .claude/agents
  file: claude/meu-agente.md
target: codex
  dest: .codex/prompts
  file: codex/meu-agente.md
target: opencode
  dest: .opencode/agent
  file: opencode/meu-agente.md
```

Regras do manifesto:

- `name`, `version` e `description` sao obrigatorios. `name` deve bater com o nome
  do diretorio; `version` segue versionamento semantico (`MAJOR.MINOR.PATCH`).
- Ao menos um bloco `target`. Cada `target` deve constar em `targets.conf`.
- Cada `target` tem ao menos um `file`, com caminho relativo a `agents/<nome>/`.
  Todo `file` referenciado precisa existir.
- `dest` e opcional; se omitido, usa o destino padrao do alvo em `targets.conf`.
- Um manifesto ausente ou invalido faz o agente ser rejeitado antes de qualquer
  escrita no projeto.

### 4. Multiplos arquivos por alvo

Basta repetir `file:` dentro do bloco do alvo:

```text
target: claude
  dest: .claude/agents
  file: claude/meu-agente.md
  file: claude/helper.md
```

Cada arquivo e instalado em `dest/<basename-do-arquivo>`.

### 5. Valide e teste

Instale em um projeto de teste descartavel:

```sh
mkdir -p /tmp/proj/.claude && cd /tmp/proj
AGENTS_HOME=/caminho/para/o/repo /caminho/para/o/repo/bin/agents install meu-agente --target claude
agents list                      # deve aparecer com o *
agents remove meu-agente         # deve restaurar o estado
```

Um manifesto invalido retorna codigo 4 e nao escreve nada.

## Alvos suportados

Os alvos e seus destinos padrao ficam em `targets.conf`
(`target|dest_default|marker|min_version`):

| Alvo | Destino padrao | Marcador | Versao minima testada |
|------|----------------|----------|-----------------------|
| claude | `.claude/agents` | `.claude` | 1.0 |
| codex | `.codex/prompts` | `.codex` | 0.1 |
| opencode | `.opencode/agent` | `.opencode` | 0.1 |

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
lib/                  nucleo (manifest, targets, lock, plan) e lib/commands/
targets.conf          matriz de alvos suportados
agents/<nome>/        catalogo: manifest + arquivos por alvo
install.sh            bootstrap de instalacao da CLI
tests/                testes em POSIX sh
```
