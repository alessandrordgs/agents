<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan at:
specs/002-target-renderers/plan.md
<!-- SPECKIT END -->

# Sobre este projeto

CLI de terminal que instala agentes de IA em qualquer projeto, no estilo skills.sh,
com suporte a Claude, Codex e OpenCode. Cada agente tem uma única definição canônica
(`agents/<nome>/agent.md`, formato Claude) que é renderizada para o formato nativo de
cada alvo no momento da instalação.

# Convenções de código

- POSIX sh puro. As únicas dependências de runtime são shell POSIX e Git; não introduza
  outras (nem jq, nem bash-only, nem linguagem nova) sem forte justificativa.
- Rode o shellcheck antes de commitar: `shellcheck -s sh bin/agents lib/*.sh lib/commands/*.sh install.sh tests/*.sh`. Deve ficar limpo.
- Rode a suíte antes de commitar: `for t in tests/test_*.sh; do sh "$t" || break; done`.
- Não adicione comentários ao código, exceto marcações `ponytail:` para simplificações
  deliberadas com o teto conhecido.

# Invariantes (nunca quebrar)

- Idempotência: reinstalar ou atualizar com o mesmo estado não muda nada.
- Não destruição: nunca sobrescreve arquivo do usuário; em conflito, aborta antes de escrever.
- Remoção exata: `remove` apaga apenas o que consta em `.agents/lock`.
- O manifesto é a fonte de verdade; valide antes de qualquer escrita.

# Estilo de comunicação

- Português do Brasil, com acentuação correta.
- Sem emojis. Sem hífens como marcador em texto corrido.
- Direto e crítico: não valide ideia por cortesia; traga o porquê.
