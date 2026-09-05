# EAPACaderno

O caderno de análise do ecossistema EAPA: o projeto-modelo de análise de dados
em R, feito para ser copiado no começo de cada análise nova. A ideia é simples:
uma planilha entra, um documento faz tudo, um relatório em Word sai. Nada de
framework; só pastas com nomes claros, o pacote `here`, um documento Quarto
e um pouco de disciplina.

## A estrutura

```
EAPACaderno/
│
├── EAPACaderno.Rproj   abra o projeto por aqui (define a raiz para o here)
├── README.md                      este arquivo: o que é o projeto e como rodar
│
├── dados/
│   ├── brutos/                    a planilha original. SOMENTE LEITURA: nunca editar à mão
│   └── processados/               a base tratada em .csv, gerada pelo relatório, para o Excel
│
├── R/
│   ├── analise.R                  O CÓDIGO, comentado passo a passo: é aqui que se edita
│   └── funcoes.R                  só DEFINIÇÕES de funções próprias (não roda nada)
│
├── imagens/                       fotos, esquemas e mapas que NÃO vêm do código (começa vazia)
│
└── relatorios/
    ├── relatorio.qmd              O RELATÓRIO: o texto e o código (copiado de analise.R)
    ├── custom-reference.docx      modelo de página do Word (fonte, margens, sumário)
    ├── ocean.scss                 cores e fontes do caderno HTML (identidade Ocean do EAPA)
    ├── referencias.bib            as obras citadas no texto
    ├── abnt.csl                   estilo ABNT das citações e da lista de referências (padrão)
    ├── apa.csl                    estilo APA, alternativo (troque a linha csl: no YAML)
    ├── relatorio.docx             o relatório para o leitor (gerado)
    └── relatorio.html             o caderno do pesquisador, com o código (gerado)
```

A separação que importa é entre **o que entra** (`dados/brutos/`, `imagens/`),
**o que a gente escreve** (`R/analise.R`, `relatorios/relatorio.qmd`,
`R/funcoes.R`) e **o que
o código gera** (`dados/processados/`, o `relatorio.docx`). Tudo da terceira
categoria pode ser apagado e refeito com um Render. Uma foto em `imagens/`
entra no relatório com `![legenda](../imagens/foto.jpg){#fig-foto}`, e o
Quarto a numera junto com as figuras feitas em código.

## A ideia: um documento que conta e faz

O `relatorio.qmd` é o projeto inteiro. Ele segue a ordem natural de uma
análise, e cada etapa é um chunk com nome que diz o que faz:

| Etapa      | Chunk                 | Trechos de `R/analise.R` que ele reúne                  | No Word? | No HTML? |
|------------|-----------------------|--------------------------------------------------------|----------|----------|
| manter     | `codigo-do-script`, `atualizar` | conferem (no Render) e copiam (à mão) o código do script | não | não |
| instalar   | `instalar`            | instala pacotes que faltam; roda uma vez (`eval: false`) | não | não |
| pacotes    | `pacotes`             | `library()`, `source(funcoes.R)` e opções gerais        | não | não |
| importar   | `importar-e-conferir` | `importar`, `conferir-importacao`: lê a planilha como veio e mostra os tipos | não | código |
| tratar     | `preparo`             | `tratar`, `tratar-biometria`, `tratar-agua`, `conferir-dados`, `exportar-dados`: nomes, tipos, variáveis derivadas, conferência e `.csv` | não | código |
| explorar   | `explora-*` (4)       | um trecho por exploração: resumos e gráficos para olhar antes de testar | não | código e gráficos |
| analisar   | `analise`             | `analisar`, `analisar-pressupostos`, `analisar-tukey`, `analisar-tendencia`, `preparar-resultados-texto` | não | código |
| diagnosticar | `diagnostico-*` (3) | um trecho por pressuposto do modelo, com seu gráfico   | não | código e gráficos |
| comunicar  | `tbl-*`, `fig-*` e o texto | tabelas, figuras numeradas e a narrativa            | **sim** | **sim** |

Cada trecho do script abre com um cabeçalho que diz o **objetivo**, a
**entrada**, o que ele **produz**, de que trecho **depende** e, nos de
exploração e diagnóstico, **o que conferir** no resultado. Assim dá para
entender uma etapa sem ler o arquivo inteiro. Quando várias etapas se seguem
sem texto entre elas (importar e conferir; as cinco de preparo; as cinco de
análise), o relatório as reúne num chunk só, para o código não ficar picado.

Isso é *literate programming*: o código e o texto vivem no mesmo lugar, na
ordem em que a análise é pensada. O mesmo arquivo gera **dois documentos**:

- **`relatorio.docx`, para o leitor.** Estrutura de artigo científico
  (Resumo, Introdução, Material e métodos, Resultados, Discussão, Conclusão,
  Referências), só com texto, tabelas e figuras. As seções de exploração e o
  diagnóstico dos resíduos são removidos (`content-visible when-format="html"`).
- **`relatorio.html`, o caderno do pesquisador.** Tudo o que está no Word, mais
  o código de cada chunk, dobrado (clique em "Código" para abrir, ou use o menu
  no canto superior para mostrar tudo), e as seções de exploração com seus
  gráficos.

E, fora dos dois, o pesquisador vê qualquer passo rodando o chunk no RStudio
(Ctrl+Shift+Enter), com a saída no console como sempre.

## Por que um arquivo, duas saídas?

Um aluno logo pergunta: por que existe um `.qmd` só, e como um arquivo gera um
Word e um HTML diferentes? A resposta cabe numa imagem: **é a mesma receita,
servida de dois jeitos.** O Word é o prato pronto na mesa, para quem vai comer
(o leitor: resultados e método, no formato de um artigo). O HTML é a cozinha
aberta, para quem quer ver como se fez (o pesquisador: todo o código, a
exploração, o diagnóstico). A receita é uma só; muda quem está olhando.

O script é a fonte do código; o `.qmd` reúne esse código e o texto, e é dele
que saem as duas impressões. O Word e o HTML não são dois arquivos que você
mantém à mão; são gerados no Render e descartáveis. Se você editasse um
`.docx` e um `.html` separados, eles logo divergiriam, e ninguém saberia qual
é o certo. Com um `.qmd` só, essa dúvida não existe.

E o Quarto sabe para qual formato está gerando: durante o Render ele carrega um
formato de cada vez e o documento se adapta sozinho, por três mecanismos que já
estão no arquivo:

- **`echo`** — global vale `false` (o Word não mostra código), mas o bloco
  `html` reescreve para `echo: true`. O mesmo chunk aparece dobrado no HTML e
  some no Word.
- **`content-visible when-format="html"`** — as seções de Exploração e de
  Diagnóstico existem só no HTML; no Word o Quarto as remove antes de gerar.
- **`output: false` / `include: false`** — valem para os dois formatos, porque
  são trabalho de bastidor em qualquer caso. Os chunks de exploração e de
  diagnóstico não levam nenhuma das duas: mostram tudo, mas só existem no
  HTML, pela cerca do item anterior.

Rodar chunk a chunk, aliás, não depende de formato nenhum: é o modo interativo
do RStudio, e vale para o `.qmd` inteiro, esteja ele mirando Word ou HTML.

## Onde o código mora: o script e o relatório

O código aparece em dois lugares, mas só se **escreve** em um. Em
`R/analise.R` ele vem com os comentários que explicam cada passo: por que
`skip = 3`, por que o tanque 19 está sem sobrevivência, o que conferir em
cada gráfico. No `relatorio.qmd` ele vem limpo, só as linhas que fazem
alguma coisa, para que o caderno HTML mostre o que se fez sem a aula no meio,
e para que qualquer chunk possa ser rodado linha a linha no RStudio.

A ligação entre os dois é a primeira linha de cada chunk:

```r
# fonte: tratar, tratar-biometria, tratar-agua, conferir-dados, exportar-dados
```

Ela diz de quais trechos do script (os marcados com `## ---- nome ----`) o
chunk é feito. A regra que sustenta tudo: **o código se edita no script,
nunca no relatório.** Depois de editar, rode o chunk `atualizar`, logo no
começo do `.qmd`: ele copia o código novo para os chunks, sem as linhas de
comentário (um comentário no fim de uma linha de código, como em
`library(readxl)  # planilhas`, fica), e diz quais mudaram. Se alguém
esquecer, o Render para na primeira linha com a mensagem "o código do
relatório está diferente de analise.R em: ..." e o nome do chunk. Assim os
dois nunca divergem em silêncio. Um chunk R escrito direto no `.qmd`, sem a
linha `# fonte:`, fica fora dessa conferência; o Render avisa no log quais
são, para que isso seja uma escolha e não um esquecimento.

Quem prefere estudar no script, estuda no script (o menu de seções do
RStudio, Ctrl+Shift+O, lista os trechos). Quem prefere o caderno, lê o
caderno e abre o script na seção de mesmo nome quando quer saber o porquê.

## A aparência das duas saídas

Cada saída tem o seu arquivo de estilo, e o `.qmd` não sabe de nenhum dos dois:

- **Word:** `custom-reference.docx`, o mesmo modelo de página da CatalyseR,
  com cara de artigo (Times New Roman 12, A4, margens ABNT, títulos numerados,
  sem sumário). Para mudar fonte, margem ou estilo de título, edite os estilos
  desse arquivo no Word, salve, e o próximo Render usa o novo.
- **HTML:** `ocean.scss`, um arquivo pequeno com as cores e as fontes do
  ecossistema (azul-marinho nos títulos, azul-petróleo nos links, Cambria e
  Calibri). Para mudar uma cor, mude uma variável no topo dele.

O YAML do `.qmd` só aponta para os dois (`reference-doc` e `theme`) e define
o que é de cada formato: no Word, tamanho e resolução das figuras; no HTML, a
faixa de título, o índice à esquerda (no alto, ao lado do Resumo), o código
dobrado e os botões de copiar.
As legendas saem como "Tabela 1 – ..." e "Figura 1 – ..." nos dois, no padrão
da ABNT (`crossref: title-delim`).

## Mudar o texto, inserir imagens

O `.qmd` é seu para escrever. O texto entre os chunks é a prosa do relatório:
mude a Introdução, a Discussão, o que quiser, do mesmo jeito que escreveria num
editor. O que estiver em `` `r ... ` `` puxa um número do código (por exemplo
`` `r fmt(coef_tend, 3)` ``) e se atualiza sozinho no próximo Render; o resto é
texto comum.

Para inserir uma foto ou um esquema que não vem do código (uma imagem do
experimento, um mapa da área de coleta), guarde o arquivo em `imagens/` e
chame-o assim, onde quiser que ele apareça:

```
![Vista dos tanques-rede no início do experimento.](../imagens/tanques.jpg){#fig-tanques}
```

O `#fig-tanques` dá um rótulo à figura; no texto, `@fig-tanques` vira "Figura N"
com o número certo, lado a lado com as figuras feitas em código. O `../` sobe de
`relatorios/` para a raiz e desce em `imagens/`. Uma foto assim aparece nas duas
saídas, no Word e no HTML.

## Mostrar algo só no caderno (ou só no Word)

As seções de Exploração e de Diagnóstico existem apenas no HTML. Quem faz isso
é uma **cerca de dois-pontos** em volta do trecho, com a condição nas chaves:

```
::: {.content-visible when-format="html"}

## Exploração

O que estiver aqui dentro (texto, chunks, figuras) só aparece no caderno.

:::
```

A cerca de fechamento é uma linha só com `:::`. Para o contrário, use
`.content-hidden when-format="docx"`: o trecho vale para todos os formatos,
menos o Word.

Uma regra a lembrar quando houver caixa dentro de caixa (por exemplo, um
*callout* dentro da seção): **a cerca de fora precisa de mais dois-pontos que a
de dentro**. Por isso, no `relatorio.qmd`, a seção usa `::::` e o callout,
`:::`. É assim que o Pandoc sabe qual fechamento pertence a qual abertura.

No editor visual do RStudio, o caminho é **Insert → Div**; a caixa aparece com
as etiquetas `.content-visible` e `when-format="html"` no canto, e clicar nelas
abre a edição. No editor de código, é só escrever as cercas.

## As citações

As citações usam `[@chave]` no texto e as obras ficam em `referencias.bib`;
o Quarto monta a lista de referências no fim, no estilo do arquivo `.csl`
indicado no YAML. Vêm dois estilos prontos: ABNT (o padrão) e APA (`apa.csl`,
basta trocar a linha `csl:`). Qualquer outro se baixa do repositório de
estilos CSL (github.com/citation-style-language/styles).

No caderno HTML, as seções de Exploração e de Diagnóstico do modelo têm um
chunk por verificação, e o trecho correspondente em `R/analise.R` diz o que
conferir e o que seria sinal de problema. É a lista de pressupostos da
análise, no lugar onde ela se confere.

## Como rodar

1. Abra o arquivo `.Rproj` no RStudio (ou abra a pasta no VS Code/Positron).
   Isso define o diretório de trabalho na raiz do projeto, que é o que o
   `here()` usa para montar os caminhos.
2. Abra `relatorios/relatorio.qmd`. Em computador novo, rode o chunk
   `instalar` uma vez (Ctrl+Shift+Enter com o cursor nele): ele instala só o
   que falta. Faça isso antes do primeiro Render, porque o relatório usa o
   pacote `here` logo na primeira linha.
3. Reinicie o R (Ctrl+Shift+F10) e clique em **Render**. Saem
   `relatorios/relatorio.docx` e `relatorios/relatorio.html` (a seta ao lado
   do botão Render escolhe um formato só; no Terminal,
   `quarto render relatorios/relatorio.qmd` gera os dois).

Se o Render passa com a memória limpa, a análise é reprodutível.

## Rodar chunk a chunk, sem tropeçar nas cercas

Durante o trabalho você não renderiza a cada mudança: roda um chunk e olha o
console. Três jeitos, do mais seguro para o mais arriscado:

- **O chunk inteiro:** clique no triângulo verde no canto do chunk, ou ponha o
  cursor dentro dele e tecle **Ctrl+Shift+Enter**.
- **Uma linha:** cursor na linha, **Ctrl+Enter**. Com o cursor dentro do chunk,
  o RStudio manda só o código.
- **Selecionar com o mouse e teclar Ctrl+Enter:** é aqui que se erra. Se a
  seleção pegar as linhas de crases (` ``` `) que abrem e fecham o chunk, elas
  vão para o console e o R responde:

  ```
  Erro: tentativa de usar um nome de variável com comprimento zero
  ```

  Não é erro do seu código: o R leu ` ``` ` como um nome entre crases vazio. O
  código da seleção rodou normalmente. Selecione só as linhas de código, ou
  use um dos dois primeiros jeitos.

Uma ordem que ajuda: rode `pacotes`, depois `importar-e-conferir` e
`preparo` (ou, com o cursor num chunk mais abaixo, **Ctrl+Alt+P** roda todos
os anteriores). A partir daí, qualquer chunk de análise encontra os dados na
memória. O mesmo vale no script: os trechos rodam em ordem, com Ctrl+Enter.

## Relação com a CatalyseR

Este projeto é o caminho a pé. O que a CatalyseR faz com cliques (importar,
tratar, analisar, comunicar), aqui se faz à mão, um chunk por etapa. A chegada
é a mesma: um relatório em Word com o mesmo modelo de página
(`custom-reference.docx`), as mesmas cores (Ocean) e o mesmo jeito de escrever
número e tabela (`fmt()`, `formatar_p()`, `flextable_ocean()`). O Projeto R
que a CatalyseR exporta também é um `relatorio.qmd` com a análise dentro.
Quem sai de um deve reconhecer o outro. Este projeto não depende da CatalyseR
nem de nenhum pacote fora do CRAN.

## Como usar em um projeto novo

1. Pegue uma cópia limpa. No GitHub, use **Code → Download ZIP**: o `.zip` já
   vem só com as pastas e os arquivos, sem o histórico do projeto. Se preferir
   copiar a pasta de um computador para outro, apague de dentro da cópia as
   pastas ocultas `.git/` (o histórico deste projeto, que não é o seu) e
   `.Rproj.user/` (as preferências do RStudio de outra pessoa).
2. Renomeie a pasta e o `.Rproj` com o nome do seu estudo. O `here()` não
   depende desses nomes; ele acha a raiz pelo `.Rproj`, qualquer que seja ele.
3. Coloque a(s) planilha(s) em `dados/brutos/`.
4. Adapte o código em `R/analise.R`, trecho a trecho, na ordem. Em geral
   `importar` e `tratar` mudam bastante, `explora-*` um pouco, e `analisar` é
   onde a análise de fato acontece. O trecho `tratar` é onde você anota o que
   é cada coluna (o `rename()` faz o "de-para" com a planilha) e por que cada
   valor faltante está faltando. Trechos novos ganham um marcador
   `## ---- nome ----` e entram na linha `# fonte:` do chunk que os mostra.
5. Rode o chunk `atualizar` do `relatorio.qmd` e reescreva o texto. Os
   números do texto vêm dos objetos (`` `r fmt(...)` ``), nunca digitados à
   mão.
6. Apague os arquivos de exemplo (`crescimento_tilapia.xlsx` e o conteúdo de
   `dados/processados/`).

O `.gitignore` que vem na pasta pode ficar: ele serve a qualquer projeto novo,
dizendo ao git o que não versionar (as saídas do Render, os arquivos do
RStudio, os dados gerados). Só passa a fazer efeito se você criar um
repositório para o seu estudo, o que é uma boa ideia, mas não é obrigatório.

## Convenções

**Caminhos.** Sempre `here("pasta", "arquivo")`. Nunca `setwd()`, nunca
`"C:/Users/fulano/..."`. O `here()` acha a raiz do projeto pelo `.Rproj`, então
o mesmo código roda em qualquer computador e em qualquer pasta.

**O script explica, o relatório faz, as funções definem.** O `R/analise.R`
é onde o código se escreve e se comenta. O `relatorio.qmd` executa, de cima
para baixo, o mesmo código sem os comentários (chunk `atualizar`). O
`R/funcoes.R` contém só `nome <- function(...) {...}` e é carregado uma vez,
no chunk `pacotes`. Se um trecho foi copiado e colado duas vezes, ele vira
função.

**Um chunk, uma etapa.** Cada chunk usa o que o anterior deixou na memória.
Os nomes seguem a ordem da análise, e um sufixo separa as etapas de uma mesma
fase: `tratar-biometria`, `analisar-tukey`. Quando o projeto tem mais de uma
análise, o nome dela entra logo depois do verbo: `analisar-sobrevivencia`,
`analisar-sobrevivencia-tukey`.

**Cada etapa escreve num objeto que ela não lê.** O `tratar` produz
`biometria_nomes`; o `tratar-biometria` lê esse objeto e produz `biometria`.
Parece detalhe, mas é o que permite reexecutar um chunk isolado sem estragar
nada. Se uma etapa sobrescrevesse a própria entrada, rodá-la duas vezes
trataria um dado já tratado: `as.numeric()` sobre um fator já criado, por
exemplo, devolveria 1, 2, 3, 4 no lugar das densidades, e ninguém veria o erro.

**O que o leitor vê e o que o pesquisador vê.** Chunks de trabalho (importar,
preparo, análise) rodam com `output: false`; os de exploração e diagnóstico
mostram tudo, mas ficam dentro da cerca `when-format="html"`. Nada disso
entra no Word, mas tudo roda e tudo pode ser executado no RStudio. Só
`tbl-*`, `fig-*` e o texto aparecem nos dois.

**Dados brutos são intocáveis.** Erro na planilha se corrige com código no
chunk `tratar`, com comentário dizendo o porquê. Assim fica registrado.

**Figuras nascem no relatório.** Um chunk `fig-*` com `fig-cap` é numerado,
legendado e citado (`@fig-ganho`) pelo próprio Quarto. Não é preciso salvar
PNG. Se precisar da figura fora do relatório (um slide, um artigo), um
`ggsave()` no fim do chunk resolve.

**Nomes.** Minúsculas, sem acento, sem espaço, `_` em objetos e arquivos
(`ganho_peso`, `biometria.csv`), `-` em nomes de chunk (`fig-ganho`), e
dizendo o que a coisa é: `fig-ganho-por-densidade`, não `grafico1`.

**Pacotes no topo.** O chunk `pacotes` carrega tudo com `library()`. Dentro
de `funcoes.R` usa-se `pacote::funcao()`.

**Uma cara só.** Todas as figuras usam `tema_projeto()` e `cores_tratamento`;
todas as tabelas do Word, `flextable_ocean()`; todo número no texto passa por
`fmt()` ou `formatar_p()`. Muda-se num lugar, muda em tudo.

**Comentários dizem o porquê, e moram no script.** O código já diz o quê.
`# converte para numérico` não ajuda; `# alguém digitou "168,3" com vírgula e
a coluna virou texto` ajuda. Eles ficam em `R/analise.R`; o relatório recebe
só o código, e a única linha de comentário de cada chunk é a `# fonte:`.

**Não salve o workspace.** Nas opções do RStudio (Tools → Global Options →
General), desmarque *Restore .RData* e ponha *Save workspace* em *Never*. O
`.Rproj` deste modelo já vem assim. Tudo que importa deve nascer do Render.

## Sobre o exemplo

Os dados são fictícios: um experimento de densidade de estocagem de tilápia em
tanques-rede (4 densidades × 6 tanques, DIC). A planilha bruta traz de
propósito os defeitos comuns de planilha de campo (título acima do cabeçalho,
nome de coluna com unidade, valor digitado com vírgula, `-` no lugar de vazio),
para que o chunk `tratar` mostre como se lida com cada um.

## Referências que inspiraram esta estrutura

- Knuth D. (1984). *Literate programming.* The Computer Journal 27(2): 97–111.
- Wilson G. et al. (2017). *Good enough practices in scientific computing.*
  PLOS Comput Biol 13(6): e1005510.
- Wickham H., Çetinkaya-Rundel M., Grolemund G. *R para Ciência de Dados*, 2ª ed.,
  caps. "Fluxo de trabalho: scripts e projetos" e "Quarto" (pt.r4ds.hadley.nz).
- Bryan J. *What They Forgot to Teach You About R*, cap. "Project-oriented
  workflow" (rstats.wtf).
- Manual de R para Epidemiologistas, cap. "R projects" (epirhandbook.com/pt).
