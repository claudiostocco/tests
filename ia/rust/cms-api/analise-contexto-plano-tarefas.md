# Context window: `plan.md` único vs. `plan.md` + `tasks/taskXX.md`

Resposta curta: **a segunda opção costuma ser melhor — mas numa versão híbrida**. O `plan.md` deve continuar sendo a fonte da verdade sobre *sequência, dependências e critérios de aceite*; os detalhes completos ficam em `tasks/taskXX.md` e são carregados **somente quando a tarefa é executada**.

## Por que separar

O fator limitante não é só o tamanho da janela, é a **densidade de sinal**. Tudo que está no contexto compete pela atenção do modelo a cada inferência. Carregar as descrições completas de 20 tarefas quando você está na tarefa 7 adiciona ruído, aumenta o custo em *todos* os turnos seguintes e aumenta o risco de "context rot" (degradação da resposta quanto mais contexto irrelevante acumula).

O padrão recomendado na literatura atual é **progressive disclosure**: índice primeiro, detalhe sob demanda. O agente enxerga o mapa, busca o arquivo da tarefa atual, executa, descarta e segue para a próxima. Isso é especialmente vantajoso se você usa subagentes — cada um recebe só o seu `taskXX.md`, com janela limpa.

## Quando cada abordagem ganha

| Situação | Melhor escolha |
|---|---|
| Plano curto (< ~1–2k tokens), tarefas muito acopladas | `plan.md` único — mais simples e sem overhead de navegação |
| Plano longo, tarefas heterogêneas ou paralelizáveis | `plan.md` + `tasks/taskXX.md` |
| Tarefas delegadas a subagentes | Separar é claramente melhor |
| Você precisa consultar várias tarefas o tempo todo | Separar perde sentido; mantenha junto |

## Estrutura que costuma funcionar

```
docs/
  plan.md            # ordem, dependências, decisões, links
  tasks/
    task01.md
    task02.md
    task03.md
```

No `plan.md`, deixe entradas curtas e explícitas sobre o carregamento lazy:

```md
# Plano de implementação

## Regras de execução
- Antes de iniciar `Txx`, leia `docs/tasks/taskxx.md`.
- Não carregue as outras tasks; elas serão lidas na sua vez.
- Ao concluir, registre decisões e desvios aqui.

## Sequência
1. T01 — Refatorar autenticação → tasks/task01.md
   - depende: —
   - aceite: testes de login passando
2. T02 — Endpoints de pedido → tasks/task02.md
   - depende: T01
   - aceite: CRUD validado
```

Cada `taskXX.md` deve ser **autocontido**: objetivo, arquivos afetados, passos, critérios de aceite, armadilhas conhecidas e referências. Não dependa de o agente ter lido outra tarefa.

## Armadilhas a evitar

- **Duplicação**: se a descrição completa estiver nos dois lugares, você paga o custo do texto duas vezes e cria divergência. Detalhe só no `taskXX.md`.
- **Carregamento involuntário**: se você referencia todos os `taskXX.md` de um arquivo sempre injetado no contexto (por exemplo um `AGENTS.md` com regras automáticas), o benefício some. O ponteiro precisa ser *preguiçoso*, não automático.
- **Fragmentação excessiva**: 40 arquivos de 3 linhas criam mais custo de navegação do que economia. Agrupe tarefas pequenas relacionadas.
- **Esquecer o estado**: mantenha em `plan.md` o que já foi feito, decisões tomadas e abordagens que falharam. Sem isso, uma janela nova tende a repetir tentativas mortas.

Resumindo: **índice enxuto + detalhes sob demanda** é o melhor ponto de equilíbrio entre economia de contexto e desempenho. Use o arquivo único apenas quando o plano inteiro cabe confortavelmente e as tarefas são poucas e muito interdependentes.

## Referências consultadas

- Anthropic — *Effective context engineering for AI agents*: https://www.anthropic.com/research/effective-context-engineering-for-ai-agents
- *State of Context Engineering in 2026*: https://pub.towardsai.net/state-of-context-engineering-in-2026-cf92d010eab1
- *Progressive Disclosure in AI Agents*: https://www.mindstudio.ai/blog/progressive-disclosure-ai-agents-context-management
- Ardalis — *Optimizing AI Agents with Progressive Disclosure*: https://ardalis.com/optimizing-ai-agents-with-progressive-disclosure/
- Sourcegraph — *Context Engineering for AI Agents*: https://sourcegraph.com/blog/context-engineering
