# Research: CLI de Instalacao de Agents

**Feature**: 001-installer-cli | **Date**: 2026-07-17

## Decisao 1: Linguagem de implementacao

- **Decision**: Script POSIX sh unico como entrypoint, com helpers em sh carregados via `.` (source). Sem dependencia de runtime alem de sh e git.
- **Rationale**: A constituicao (Principio II) obriga funcionar apenas com shell POSIX e Git. skills.sh e um instalador shell. Um script sh instala em qualquer projeto sem tocar nas dependencias do projeto alvo (FR-016).
- **Alternatives considered**: Go/Rust (binario unico, mas exige toolchain de build e distribuicao de binarios por plataforma, viola a promessa de zero dependencia e aumenta atrito); Node/Python (introduz runtime obrigatorio no ambiente, viola Principio II).

## Decisao 2: Formato do manifesto

- **Decision**: Arquivo `manifest` por agente, formato linha a linha, parseavel com awk/sed sem jq. Campos globais (`name`, `version`, `description`) e blocos por alvo com `dest` e `file`.
- **Rationale**: JSON/YAML exigiriam jq ou parser externo (dependencia extra, viola Principio II/V). Formato linha a linha e trivial de ler em sh e humano. Cobre FR-014 (validacao antes de escrever) e Principio IV (contrato explicito).
- **Alternatives considered**: JSON com jq (jq nao e garantido no ambiente); JSON parseado em sh puro (fragil, muito codigo); sourcing de sh (`. manifest`) executa codigo arbitrario, risco de seguranca em catalogo publico.

## Decisao 3: Rastreamento de estado instalado (lock)

- **Decision**: Lockfile por projeto em `.agents/lock`, uma linha por arquivo instalado: `name<TAB>version<TAB>target<TAB>relpath`. Escrito de forma atomica (grava em temp, `mv`).
- **Rationale**: Permite remocao exata (FR-012, FR-013), diferenciar instalados de disponiveis na listagem (FR-010), detectar reinstalacao para idempotencia (FR-005) e garantir que operacao interrompida seja detectavel (FR-008). Formato linha a linha, parseavel em sh.
- **Alternatives considered**: Sem lock, inferindo por presenca de arquivos (nao distingue arquivo do agente de arquivo do usuario, quebra FR-013); lock em JSON (exige jq).

## Decisao 4: Deteccao de conflito e nao destruicao

- **Decision**: Antes de escrever qualquer arquivo, verificar se o destino existe e nao consta no lock como pertencente a este agente. Se existir e nao for do agente, abortar toda a operacao antes de qualquer escrita (dry check em duas fases: planejar depois aplicar).
- **Rationale**: Garante FR-006, FR-007, FR-008 e Principio III. Como o instalador nunca sobrescreve arquivo do usuario, a remocao (que apaga apenas o que consta no lock) sempre restaura o estado anterior sem precisar de backup.
- **Alternatives considered**: Backup de arquivos sobrescritos (complexidade extra desnecessaria, pois a politica e nunca sobrescrever sem consentimento).

## Decisao 5: Deteccao de alvo

- **Decision**: Detectar alvo pela presenca de diretorio marcador no projeto (`.claude/`, `.codex/`, `.opencode/`). Flag explicita `--target` tem precedencia. Ambiguidade (multiplos alvos, nenhum informado) gera erro pedindo `--target`.
- **Rationale**: Atende FR-003 e o edge case de alvo indefinido sem instalar em local arbitrario.
- **Alternatives considered**: Perguntar interativamente sempre (atrito desnecessario quando ha um unico alvo obvio).

## Decisao 6: Locais de instalacao por alvo (calibration knob)

- **Decision**: Destinos padrao por alvo ficam em dados (`targets.conf`, mapeando `target -> dest_padrao`), nao hardcoded em codigo. O `dest` do manifesto tem precedencia sobre o padrao. Defaults iniciais: claude `.claude/agents`, codex `.codex/prompts`, opencode `.opencode/agent`.
- **Rationale**: Os layouts de configuracao de Codex/Claude/OpenCode evoluem. Manter destinos como dado permite ajustar sem alterar codigo. Os defaults acima DEVEM ser confirmados contra a documentacao vigente de cada ferramenta no inicio da implementacao (Story 1).
- **Alternatives considered**: Hardcode dos caminhos (fragil frente a mudancas das ferramentas).

## Decisao 7: Origem do catalogo

- **Decision**: O catalogo e o proprio repositorio de agents (diretorio `agents/` versionado em Git). A CLI resolve o catalogo a partir do local de instalacao dela propria.
- **Rationale**: Coerente com a assuncao da spec e Principio de auto contido; sem servico externo.
- **Alternatives considered**: Registry HTTP dedicado (servico externo, fora de escopo e contraria auto contencao).

## Decisao 8: Testes

- **Decision**: Testes em POSIX sh com um helper minimo de assercao, executaveis em ambiente descartavel (diretorio temporario simulando projeto alvo). Sem framework obrigatorio.
- **Rationale**: Principio V (minimo de dependencias). bats seria dependencia de dev extra sem ganho proporcional para um instalador shell.
- **Alternatives considered**: bats-core (bom mas dependencia adicional; adotar apenas se a assercao propria se mostrar insuficiente).
