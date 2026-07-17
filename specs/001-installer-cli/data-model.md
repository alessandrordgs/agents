# Data Model: CLI de Instalacao de Agents

**Feature**: 001-installer-cli | **Date**: 2026-07-17

## Entidade: Agente

Unidade instalavel do catalogo. Representada por um diretorio em `agents/<name>/`.

| Campo | Tipo | Regras |
|-------|------|--------|
| name | string | Obrigatorio, unico no catalogo, kebab-case, corresponde ao nome do diretorio |
| version | string | Obrigatorio, versionamento semantico (MAJOR.MINOR.PATCH) |
| description | string | Obrigatorio, uma linha |
| targets | lista de Alvo | Obrigatorio, ao menos um; define quais alvos o agente suporta |

## Entidade: Manifesto do Agente

Arquivo `agents/<name>/manifest`. Fonte de verdade para descoberta, validacao e instalacao (Principio IV).

Formato (linha a linha):

```text
name: <name>
version: <version>
description: <one line>
target: <target-id>
  dest: <caminho relativo de destino no projeto alvo>
  file: <caminho do arquivo de origem relativo ao repo>
  file: <mais arquivos do mesmo alvo>
target: <outro-target-id>
  ...
```

Regras de validacao (aplicadas antes de qualquer escrita, FR-014):

- `name`, `version`, `description` presentes e nao vazios.
- Ao menos um bloco `target`.
- Cada `target-id` deve constar em `targets.conf` (alvo conhecido).
- Cada `target` tem ao menos um `file`; todo `file` referenciado existe no repo.
- `dest` opcional; se ausente, usa o default do alvo em `targets.conf`.
- Manifesto ausente, ilegivel ou violando qualquer regra: agente rejeitado, projeto inalterado.

## Entidade: Alvo

Ferramenta de destino suportada. Configuracao em `targets.conf`.

| Campo | Tipo | Regras |
|-------|------|--------|
| id | string | Um de: `claude`, `codex`, `opencode` |
| dest_default | string | Caminho relativo padrao de instalacao no projeto alvo |
| marker | string | Diretorio cuja presenca indica o alvo em uso (ex.: `.claude`) |

Deteccao: alvo explicito (`--target`) tem precedencia sobre deteccao por marcador (FR-003).

## Entidade: Instalacao (registro no lock)

Arquivo `.agents/lock` no projeto alvo. Uma linha por arquivo instalado.

Formato: `name<TAB>version<TAB>target<TAB>relpath`

| Campo | Tipo | Regras |
|-------|------|--------|
| name | string | Nome do agente instalado |
| version | string | Versao instalada daquele agente |
| target | string | Alvo no qual foi instalado |
| relpath | string | Caminho, relativo a raiz do projeto, do arquivo escrito |

Regras:

- Escrita atomica (temp + `mv`).
- Remocao apaga exatamente as linhas (e arquivos) do agente; nunca toca em arquivos ausentes do lock (FR-013).
- Reinstalacao da mesma versao e no-op se as linhas ja constam e os arquivos batem (FR-005).

## Transicoes de estado (por agente, em um projeto)

```text
NAO_INSTALADO --install--> INSTALADO(v)
INSTALADO(v)  --install(v mesma)--> INSTALADO(v)      (no-op, idempotente)
INSTALADO(v)  --update(v'>v)--> INSTALADO(v')          (reporta v -> v')
INSTALADO(v)  --update(sem versao nova)--> INSTALADO(v) (no-op)
INSTALADO(v)  --remove--> NAO_INSTALADO                (restaura estado anterior)
NAO_INSTALADO --remove--> NAO_INSTALADO                (nada a fazer)
```

Conflito de arquivo em qualquer transicao de escrita: operacao abortada antes de escrever, estado permanece o anterior (FR-007, FR-008).
