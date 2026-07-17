<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan at:
specs/002-target-renderers/plan.md
<!-- SPECKIT END -->

# Sobre este projeto

CLI de terminal que instala agentes de IA em qualquer projeto, no estilo skills.sh,
com suporte a Claude, Codex e OpenCode. Cada agente tem uma unica definicao canonica
(`agents/<nome>/agent.md`, formato Claude) que e renderizada para o formato nativo de
cada alvo no momento da instalacao.

# Convencoes de codigo

- POSIX sh puro. As unicas dependencias de runtime sao shell POSIX e Git; nao introduza
  outras (nem jq, nem bash-only, nem linguagem nova) sem forte justificativa.
- Rode shellcheck antes de commitar: `shellcheck -s sh bin/agents lib/*.sh lib/commands/*.sh install.sh tests/*.sh`. Deve ficar limpo.
- Rode a suite antes de commitar: `for t in tests/test_*.sh; do sh "$t" || break; done`.
- Nao adicione comentarios ao codigo, exceto marcacoes `ponytail:` para simplificacoes
  deliberadas com o teto conhecido.

# Invariantes (nunca quebrar)

- Idempotencia: reinstalar/atualizar com o mesmo estado nao muda nada.
- Nao destruicao: nunca sobrescreve arquivo do usuario; em conflito, aborta antes de escrever.
- Remocao exata: `remove` apaga apenas o que consta em `.agents/lock`.
- O manifesto e a fonte de verdade; valide antes de qualquer escrita.

# Estilo de comunicacao

- Portugues do Brasil, com acentuacao correta.
- Sem emojis. Sem hifens como marcador em listas de texto corrido.
- Direto e critico: nao valide ideia por cortesia; traga o porque.
