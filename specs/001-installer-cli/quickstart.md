# Quickstart: CLI de Instalacao de Agents

**Feature**: 001-installer-cli

## Pre requisitos

Shell POSIX (`sh`) e Git. Nenhuma outra dependencia.

## Instalar a CLI (bootstrap estilo skills.sh)

```sh
# clona/atualiza o repositorio de agents e coloca `agents` no PATH
sh install.sh
```

## Uso

```sh
# listar o catalogo (marca os ja instalados)
agents list

# instalar um agente (detecta o alvo pelo projeto)
agents install code-reviewer

# instalar forcando o alvo
agents install code-reviewer --target claude

# atualizar
agents update code-reviewer

# remover (restaura o projeto ao estado anterior)
agents remove code-reviewer

# listar apenas instalados
agents list --installed
```

## Verificacao das user stories

- **US1 Instalar**: em um projeto com `.claude/`, rodar `agents install <name>`; conferir os arquivos em `.claude/agents/` e a linha no `.agents/lock`. Rodar de novo: nenhuma mudanca (idempotencia).
- **US2 Listar**: `agents list` mostra nome, versao, descricao, alvos e marca instalados.
- **US3 Atualizar**: instalar versao antiga, rodar `agents update <name>`; conferir troca de versao e que arquivos alheios nao mudaram.
- **US4 Remover**: `agents remove <name>`; conferir que os arquivos do agente sumiram e o projeto voltou ao estado pre instalacao, sem residuos.

## Conflito (nao destruicao)

Criar um arquivo com o mesmo caminho de destino de um arquivo do agente e rodar `agents install`: a operacao deve abortar reportando o conflito, sem sobrescrever nada.
