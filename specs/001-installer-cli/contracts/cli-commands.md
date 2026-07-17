# CLI Contract: comandos

**Feature**: 001-installer-cli | **Date**: 2026-07-17

Entrypoint: `agents <command> [args]`. Saida humana no stdout, erros no stderr. Codigo de saida 0 em sucesso ou no-op, diferente de 0 em erro/conflito.

## `agents install <name> [--target <id>]`

Instala o agente `<name>` do catalogo no projeto atual.

- Resolve alvo: `--target` tem precedencia; senao detecta por marcador; ambiguidade -> erro pedindo `--target`.
- Valida manifesto antes de qualquer escrita; manifesto invalido/ausente -> erro, projeto inalterado.
- Recusa se o agente nao declara suporte ao alvo -> erro explicativo.
- Fase de planejamento: calcula destinos; se algum destino existe e nao consta no lock deste agente -> conflito, aborta antes de escrever.
- Aplica: copia arquivos, grava linhas no lock atomicamente.
- Reinstalar mesma versao com arquivos identicos -> no-op, reporta "nada a fazer".

Saidas: sucesso (`instalado <name>@<version> em <target>`), no-op, erro-agente-desconhecido, erro-alvo, erro-manifesto, conflito.

## `agents list [--installed]`

Lista agentes.

- Sem flag: catalogo completo, cada linha com `name`, `version`, `description`, `targets`, e marcacao se instalado no projeto atual.
- `--installed`: apenas os instalados no projeto (lidos do lock).

Saida sempre 0 (lista possivelmente vazia).

## `agents update <name>`

Atualiza um agente instalado para a versao mais nova do catalogo.

- Agente nao instalado -> erro.
- Versao do catalogo <= instalada -> no-op, reporta "ja na versao mais nova".
- Versao mais nova: mesma deteccao de conflito da instalacao; remove arquivos da versao antiga (via lock) e instala a nova, atualizando o lock. Nunca toca arquivos fora do lock (FR-013).

Saidas: sucesso (`atualizado <name> <vOld> -> <vNew>`), no-op, erro-nao-instalado, conflito.

## `agents remove <name>`

Remove um agente instalado.

- Le do lock os arquivos do agente e os apaga; remove as linhas do lock (atomico).
- Nunca apaga arquivo ausente do lock.
- Agente nao instalado -> no-op, reporta "nada a remover".

Saidas: sucesso (`removido <name>`), no-op, erro.

## Regras gerais

- Toda operacao de escrita e planejada e so entao aplicada, para nunca deixar estado parcial (FR-008).
- Mensagens de resultado sempre explicitas: sucesso, nada-a-fazer, erro, conflito (FR-015).
- `agents` sem comando ou com `--help`: imprime uso e sai 0.
