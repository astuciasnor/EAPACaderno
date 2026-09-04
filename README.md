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
│   └── funcoes.R                  só DEFINIÇÕES de funções próprias (não roda nada)
│
├── imagens/                       fotos, esquemas e mapas que NÃO vêm do código (começa vazia)
│
└── relatorios/
    ├── relatorio.qmd              O PROJETO: importa, prepara, explora, analisa e escreve
    ├── custom-reference.docx      modelo de página do Word (fonte, margens, sumário)
    ├── referencias.bib            as obras citadas no texto
    ├── abnt.csl                   estilo ABNT das citações e da lista de referências (padrão)
    ├── apa.csl                    estilo APA, alternativo (troque a linha csl: no YAML)
    ├── relatorio.docx             o relatório para o leitor (gerado)
    └── relatorio.html             o caderno do pesquisador, com o código (gerado)
```

A separação que importa é entre **o que entra** (`dados/brutos/`, `imagens/`),
**o que a gente escreve** (`relatorios/relatorio.qmd`, `R/funcoes.R`) e **o que
o código gera** (`dados/processados/`, o `relatorio.docx`). Tudo da terceira
categoria pode ser apagado e refeito com um Render. Uma foto em `imagens/`
entra no relatório com `![legenda](../imagens/foto.jpg){#fig-foto}`, e o
Quarto a numera junto com as figuras feitas em código.

## A ideia: um documento que conta e faz

O `relatorio.qmd` é o projeto inteiro. Ele segue a ordem natural de uma
análise, e cada etapa é um chunk com nome que diz o que faz:

| Etapa      | Chunk(s)              | O que acontece                                         | No Word? | No HTML? |
|------------|-----------------------|--------------------------------------------------------|----------|----------|
| instalar   | `instalar`            | instala pacotes que faltam; roda uma vez (`eval: false`) | não | código |
| pacotes    | `pacotes`             | `library()` e `source(funcoes.R)`                       | não | não |
| importar   | `importar`            | lê a planilha como ela veio, sem mexer em nada          | não | código |
| tratar     | `tratar`              | renomeia, corrige tipos, cria variáveis, grava o `.csv` | não | código |
| explorar   | `explora-*`           | resumos e gráficos para olhar antes de testar           | não | código e gráficos |
| analisar   | `analisar`, `diagnostico` | ANOVA, pressupostos, Tukey, tendência               | não | código e diagnóstico |
| comunicar  | `tbl-*`, `fig-*` e o texto | tabelas, figuras numeradas e a narrativa            | **sim** | **sim** |

Isso é *literate programming*: o código e o texto vivem no mesmo lugar, na
ordem em que a análise é pensada. O mesmo arquivo gera **dois documentos**:

- **`relatorio.docx`, para o leitor.** Estrutura de artigo científico
  (Introdução, Material e métodos, Resultados, Discussão, Conclusão,
  Referências), só com texto, tabelas e figuras. As seções de exploração e o
  diagnóstico dos resíduos são removidos (`content-visible when-format="html"`).
- **`relatorio.html`, o caderno do pesquisador.** Tudo o que está no Word, mais
  o código de cada chunk, dobrado (clique em "Código" para abrir, ou use o menu
  no canto superior para mostrar tudo), e as seções de exploração com seus
  gráficos.

E, fora dos dois, o pesquisador vê qualquer passo rodando o chunk no RStudio
(Ctrl+Shift+Enter), com a saída no console como sempre.

## Por que um arquivo, duas saídas?

Um aluno logo pergunta: por que existe só o `.qmd`, e como um arquivo gera um
Word e um HTML diferentes? A resposta cabe numa imagem: **é a mesma receita,
servida de dois jeitos.** O Word é o prato pronto na mesa, para quem vai comer
(o leitor: resultados e método, no formato de um artigo). O HTML é a cozinha
aberta, para quem quer ver como se fez (o pesquisador: todo o código, a
exploração, o diagnóstico). A receita é uma só; muda quem está olhando.

O `.qmd` é a **fonte única**. O Word e o HTML não são dois arquivos que você
mantém à mão; são duas impressões do mesmo documento, geradas no Render e
descartáveis. Se você editasse um `.docx` e um `.html` separados, eles logo
divergiriam, e ninguém saberia qual é o certo. Com um `.qmd` só, essa dúvida
não existe.

E o Quarto sabe para qual formato está gerando: durante o Render ele carrega um
formato de cada vez e o documento se adapta sozinho, por três mecanismos que já
estão no arquivo:

- **`echo`** — global vale `false` (o Word não mostra código), mas o bloco
  `html` reescreve para `echo: true`. O mesmo chunk aparece dobrado no HTML e
  some no Word.
- **`content-visible when-format="html"`** — as seções de Exploração e de
  Diagnóstico existem só no HTML; no Word o Quarto as remove antes de gerar.
- **`output: false` / `include: false`** — valem para os dois formatos, porque
  são trabalho de bastidor em qualquer caso.

Rodar chunk a chunk, aliás, não depende de formato nenhum: é o modo interativo
do RStudio, e vale para o `.qmd` inteiro, esteja ele mirando Word ou HTML.

**E se eu quiser um script puro?** Peça ao `knitr` que extraia o código dos
chunks, na ordem, para um `.R`:

```r
knitr::purl("relatorios/relatorio.qmd", output = "relatorios/relatorio.R")
```

Cada chunk vira um bloco marcado com o seu nome (`## ----tratar----`), os
chunks com `eval: false` entram comentados, e o texto fica de fora. O `.R` é
um subproduto: a fonte continua sendo o `.qmd`, e um novo `purl()` refaz o
script quando o relatório mudar.

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

As citações usam `[@chave]` no texto e as obras ficam em `referencias.bib`;
o Quarto monta a lista de referências no fim, no estilo do arquivo `.csl`
indicado no YAML. Vêm dois estilos prontos: ABNT (o padrão) e APA (`apa.csl`,
basta trocar a linha `csl:`). Qualquer outro se baixa do repositório de
estilos CSL (github.com/citation-style-language/styles).

No caderno HTML, as seções de Exploração e de Diagnóstico do modelo têm um
chunk por verificação, e os comentários dentro de cada chunk dizem o que
conferir e o que seria sinal de problema. É a lista de pressupostos da
análise, no lugar onde ela se confere.

## Como rodar

1. Abra o arquivo `.Rproj` no RStudio (ou abra a pasta no VS Code/Positron).
   Isso define o diretório de trabalho na raiz do projeto, que é o que o
   `here()` usa para montar os caminhos.
2. Abra `relatorios/relatorio.qmd`. Em computador novo, rode o chunk
   `instalar` uma vez.
3. Reinicie o R (Ctrl+Shift+F10) e clique em **Render**. Saem
   `relatorios/relatorio.docx` e `relatorios/relatorio.html` (a seta ao lado
   do botão Render escolhe um formato só; no Terminal,
   `quarto render relatorios/relatorio.qmd` gera os dois).

Se o Render passa com a memória limpa, a análise é reprodutível.

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
4. Adapte o `relatorio.qmd` chunk a chunk, na ordem. Em geral `importar` e
   `tratar` mudam bastante, `explora-*` um pouco, e `analisar` é onde a
   análise de fato acontece. O chunk `tratar` é onde você anota o que é cada
   coluna (o `rename()` faz o "de-para" com a planilha) e por que cada valor
   faltante está faltando.
5. Reescreva o texto. Os números do texto vêm dos objetos (`` `r fmt(...)` ``),
   nunca digitados à mão.
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

**O relatório faz, as funções definem.** O `relatorio.qmd` executa, de cima
para baixo. O `R/funcoes.R` contém só `nome <- function(...) {...}` e é
carregado uma vez, no chunk `pacotes`. Se um trecho foi copiado e colado
duas vezes no relatório, ele vira função.

**Um chunk, uma etapa.** Cada chunk usa o que o anterior deixou na memória.
Os nomes seguem a ordem da análise: `importar`, `tratar`, `explora-*`,
`analisar`, e depois `tbl-*` e `fig-*` para o que vai ao Word. Quando o
projeto tem mais de uma análise, `analisar` vira um chunk por análise:
`analisar-ganho-peso`, `analisar-sobrevivencia`, e assim por diante.

**O que o leitor vê e o que o pesquisador vê.** Chunks de trabalho (importar,
tratar, analisar) rodam com `output: false`; os de exploração, com
`include: false`. Nada disso entra no Word, mas tudo roda e tudo pode ser
executado no RStudio. Só `tbl-*`, `fig-*` e o texto aparecem no relatório.

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

**Comentários dizem o porquê.** O código já diz o quê. `# converte para
numérico` não ajuda; `# alguém digitou "168,3" com vírgula e a coluna virou
texto` ajuda.

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
