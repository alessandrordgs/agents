<!--
Sync Impact Report
Version change: template (unversioned) -> 1.0.0
Ratification: initial adoption (greenfield project)
Modified principles: none (initial definition)
Added principles:
  I. Portabilidade Multi-Agente
  II. Instalacao via Terminal sem Atrito
  III. Idempotencia e Nao Destruicao
  IV. Contrato de Agente Explicito
  V. Simplicidade e Minimo de Dependencias
Added sections:
  Padroes de Compatibilidade e Distribuicao
  Fluxo de Desenvolvimento e Qualidade
Removed sections: none
Templates status:
  .specify/templates/plan-template.md ok (Constitution Check le os gates dinamicamente)
  .specify/templates/spec-template.md ok (sem referencia a principios especificos)
  .specify/templates/tasks-template.md ok (sem referencia a principios especificos)
Deferred TODOs: none
-->

# Agents Constitution

Repositorio de agentes instalaveis via terminal, no estilo skills.sh, aplicaveis a qualquer
projeto e compativeis com Codex, Claude e OpenCode.

## Core Principles

### I. Portabilidade Multi-Agente

Todo agente possui uma unica fonte de verdade. A definicao e escrita uma vez e adaptada
para cada alvo suportado (Codex, Claude, OpenCode) por meio de renderizadores, nunca por
copias divergentes da logica. Cada agente MUST declarar explicitamente quais alvos suporta.
Um agente que declara suporte a um alvo MUST instalar e funcionar nesse alvo sem edicao
manual. Nao e permitido bifurcar o comportamento do agente por alvo alem do formato exigido
por cada ferramenta.

Justificativa: a proposta do repositorio e ser cross tool. Divergencia de logica por alvo
quebra a promessa central e multiplica a superficie de manutencao.

### II. Instalacao via Terminal sem Atrito

A instalacao ocorre por um unico comando no terminal, no modelo skills.sh, sem etapas
manuais previas de configuracao. O instalador MUST funcionar com shell POSIX e Git como
unicas dependencias obrigatorias de runtime. Qualquer projeto, independentemente de stack,
MUST conseguir instalar um agente sem alterar suas proprias dependencias. Instalacao,
atualizacao e remocao MUST ser expostas como comandos explicitos e documentados.

Justificativa: atrito de instalacao e a principal barreira de adocao de ferramentas de
terminal. A paridade com skills.sh e requisito de produto, nao preferencia.

### III. Idempotencia e Nao Destruicao

Instalar ou atualizar um agente MUST ser idempotente: repetir o comando produz o mesmo
estado final sem efeitos colaterais adicionais. O instalador MUST NOT sobrescrever arquivos
do usuario sem deteccao previa e consentimento explicito. Toda instalacao MUST ser
reversivel por um comando de remocao que restaura o estado anterior. Conflitos MUST ser
reportados e interrompem a operacao em vez de aplicar mudanca parcial.

Justificativa: o agente entra em projetos alheios ja em andamento. Perda de dados ou estado
inconsistente destroi a confianca de forma irrecuperavel.

### IV. Contrato de Agente Explicito

Cada agente MUST possuir um manifesto que declara, no minimo: nome, descricao, versao,
alvos suportados e arquivos que compoem o agente. Descoberta, listagem, validacao e
instalacao MUST derivar do manifesto, nunca de convencoes implicitas de diretorio. Um
agente sem manifesto valido MUST ser rejeitado pela validacao antes da publicacao.

Justificativa: um contrato explicito e legivel por maquina permite ferramentas confiaveis
de descoberta e instalacao e evita comportamento fragil baseado em suposicoes de estrutura.

### V. Simplicidade e Minimo de Dependencias

Prefira shell e ferramentas ja presentes no ambiente antes de introduzir qualquer nova
dependencia. Uma nova dependencia de runtime MUST ser justificada por escrito e aprovada na
revisao. Abstracoes especulativas, camadas de configuracao para valores que nunca mudam e
codigo para necessidades ainda inexistentes MUST NOT ser adicionados (YAGNI). A solucao
correta e a menor que funciona e passa na validacao.

Justificativa: o projeto e uma ferramenta de terminal distribuida amplamente. Cada
dependencia e cada abstracao vira custo de portabilidade e de manutencao para todos os
usuarios.

## Padroes de Compatibilidade e Distribuicao

O repositorio MUST manter uma matriz explicita de alvos suportados (Codex, Claude,
OpenCode) e a versao minima de cada ferramenta com a qual e testado. Adicionar suporte a um
novo alvo MUST incluir um renderizador e testes de instalacao para esse alvo. A remocao de
suporte a um alvo e mudanca incompativel e segue a politica de versionamento da Governanca.
Artefatos de instalacao MUST ser autocontidos e nao depender de servicos externos alem do
transporte necessario para baixar o repositorio.

## Fluxo de Desenvolvimento e Qualidade

Todo agente novo ou alterado MUST passar por validacao de manifesto e por um teste de
instalacao em pelo menos um alvo suportado antes do merge. Logica nao trivial de instalacao
MUST deixar ao menos uma verificacao executavel que falha se a logica quebrar. Mudancas que
afetam a instalacao em qualquer alvo MUST ser testadas nesse alvo. Revisoes MUST verificar
conformidade com os principios desta constituicao; violacoes exigem justificativa registrada
ou correcao antes do merge.

## Governance

Esta constituicao supersede outras praticas do projeto em caso de conflito. Emendas MUST ser
documentadas em pull request, com descricao da mudanca, justificativa e impacto nos
artefatos dependentes, e requerem aprovacao antes do merge.

Versionamento semantico da constituicao:
MAJOR para remocao ou redefinicao incompativel de principios ou governanca;
MINOR para adicao de principio ou expansao material de guia;
PATCH para esclarecimentos e ajustes nao semanticos.

Conformidade MUST ser verificada em toda revisao de pull request. Complexidade adicional
MUST ser justificada frente ao principio de simplicidade. Use o arquivo CLAUDE.md e os
templates em .specify/templates/ como guia operacional de desenvolvimento.

**Version**: 1.0.0 | **Ratified**: 2026-07-17 | **Last Amended**: 2026-07-17
