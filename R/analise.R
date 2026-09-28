# EAPACaderno — a análise, comentada ------------------------------------------|

# COMO RODAR

# Este roteiro é o passo seguinte à CatalyseR: o que lá você fez no mouse,
# aqui você vê e roda como código. Reinicie o R (Session > Restart R) para
# começar com o ambiente limpo e execute as linhas em ordem, com Ctrl+Enter;
# o resultado aparece no Console, no Plots ou no Viewer. Ctrl+Shift+O abre o
# menu de seções e lista todos os trechos, para você se localizar.

# SCRIPT E RELATÓRIO

# O código se edita no script, nunca no relatório. Depois de editar, rode o
# chunk "atualizar" do relatório: ele copia o código, sem os comentários, para
# os chunks; se algo ficar diferente, o Render para e avisa qual chunk está
# defasado.

# Pequeno vocabulário ---------------------------------------------------------|

# <- guarda um resultado em um objeto.
# |> passa o resultado anterior à próxima função.
# mutate() cria ou transforma colunas; rename() troca seus nomes.
# select() escolhe/ordena colunas; filter() escolhe linhas.
# ~ especifica uma relação em modelos; $ acessa um componente nomeado.
# NA indica ausência de dado, não zero.

# As funções do projeto estão em R/funcoes.R: consulte suas definições
# para aprofundar resumir_grupo(), fmt(), formatar_p() e flextable_ocean().

# ──────────────────────────────────────────────────────────────────────-------|
## ---- instalar ----

# Instala só os pacotes que ainda faltam. Rode uma única vez, ao preparar um
# computador novo, antes do primeiro Render (o relatório precisa do here logo
# no início). No relatório o chunk é eval: false, então nunca instala no Render.

pacotes <- c(
  "here", "readxl", "readr", "dplyr", "tidyr", "ggplot2",
  "car", "multcompView", "flextable"
)

faltando <- pacotes[!pacotes %in% rownames(installed.packages())]

if (length(faltando)) {
  install.packages(faltando)
}

# ──────────────────────────────────────────────────────────────────────-------|
## ---- pacotes ----

# Carrega os pacotes, as funções próprias e as opções gerais do R. Rode antes
# de qualquer etapa da análise.

# here() monta os caminhos a partir da raiz do projeto (onde está o .Rproj),
# para o mesmo arquivo funcionar em computadores diferentes.

library(here)
library(readxl)        # Leitura de planilhas Excel
library(readr)         # Exportação de CSV no padrão brasileiro
library(dplyr)         # Manipulação de dados
library(tidyr)         # Reorganização de dados
library(ggplot2)       # Construção dos gráficos
library(car)           # Teste de Levene
library(multcompView)  # Letras dos grupos após o teste de Tukey
library(flextable)     # Tabelas formatadas para o Word

# Funções próprias: resumos, formatação numérica, tema e tabelas.

source(here("R", "funcoes.R"))

# Três algarismos significativos deixam as saídas exploratórias mais limpas.
# As tabelas finais usam fmt() e formatar_p() e não dependem desta opção.

options(digits = 3)

# ──────────────────────────────────────────────────────────────────────-------|
## ---- importar ----

# Importa as planilhas exatamente como vieram do campo, sem tratar nada ainda.
# Entra dados/brutos/crescimento_tilapia.xlsx; saem biometria_bruta e agua_bruta.

# skip = 3 pula as três primeiras linhas antes de ler o cabeçalho. Confira esse
# valor se o layout da planilha mudar.

arquivo <- here("dados", "brutos", "crescimento_tilapia.xlsx")

# Conferir as abas é uma medida simples contra erros no nome das planilhas.

excel_sheets(arquivo)

biometria_bruta <- read_excel(arquivo, sheet = "biometria", skip = 3)
agua_bruta <- read_excel(arquivo, sheet = "agua")

# ──────────────────────────────────────────────────────────────────────-------|
## ---- conferir-importacao ----

# Confere como o R interpretou cada coluna. Tipo errado aqui pode comprometer
# toda a análise adiante.

# "Peso final (g)" veio como texto (chr) porque existe um valor escrito com
# vírgula; os trechos de tratamento corrigem isso.
# glimpse() mostra uma coluna por linha, com o tipo ao lado do nome.

glimpse(biometria_bruta)
glimpse(agua_bruta)

# ──────────────────────────────────────────────────────────────────────-------|
## ---- tratar ----

# ETAPA 1 — padronizar os nomes das colunas, criando nomes curtos e seguros
# para usar no código.

# Por que um objeto novo a cada etapa: cada passo escreve num objeto que ele
# mesmo não lê. Assim, reexecutar um trecho isolado refaz o mesmo resultado,
# em vez de tratar de novo um dado já tratado.

# O de-para explícito registra qual coluna da planilha deu origem a cada
# variável da análise.

biometria_nomes <- biometria_bruta |>
  rename(
    tanque        = `Tanque`,
    densidade     = `Densidade (peixes/m³)`,
    peso_inicial  = `Peso inicial (g)`,
    peso_final    = `Peso final (g)`,
    comprimento   = `Comprimento final (cm)`,
    sobrevivencia = `Sobrevivência (%)`,
    observacoes   = `Observações`
  )

agua_nomes <- agua_bruta |>
  rename(
    tanque      = `Tanque`,
    semana      = `Semana`,
    temperatura = `Temperatura (°C)`,
    oxigenio    = `Oxigênio dissolvido (mg/L)`,
    ph          = `pH`
  )

# ──────────────────────────────────────────────────────────────────────-------|
## ---- tratar-biometria ----

# ETAPA 2 — corrigir os tipos e criar as variáveis da biometria (o fator de
# tratamento e o ganho de peso), deixando a base pronta para a análise.

biometria <- biometria_nomes |>
  mutate(
    # Um valor como "168,3" fez a coluna inteira ser importada como texto.
    # Primeiro trocamos a vírgula por ponto; depois convertemos para número.
    peso_final = as.numeric(sub(",", ".", peso_final, fixed = TRUE)),

    # O sinal "-" usado na planilha vira NA, o padrão do R para dado ausente.
    # Os dois NA da base têm motivo conhecido, e vale registrá-lo aqui:
    # T14 sem comprimento (ictiômetro quebrado) e T19 sem sobrevivência
    # (contagem não realizada). Ver também a aba "leia-me" da planilha.
    sobrevivencia = as.numeric(na_if(sobrevivencia, "-")),
    comprimento = as.numeric(comprimento),

    # Mantemos duas versões da densidade porque cada análise exige uma forma:
    # fator para a ANOVA e número para a regressão de tendência.
    densidade_num = as.numeric(densidade),
    densidade = factor(densidade, levels = c(50, 100, 150, 200)),

    # Variável-resposta principal do estudo.
    ganho_peso = peso_final - peso_inicial
  ) |>
  # A ordem final facilita a leitura: identificação, tratamento e respostas.
  select(
    tanque, densidade, densidade_num, peso_inicial, peso_final,
    ganho_peso, comprimento, sobrevivencia, observacoes
  )

# ──────────────────────────────────────────────────────────────────────-------|
## ---- tratar-agua ----

# ETAPA 3 — corrigir os tipos da água (semana como número inteiro), deixando
# agua pronta para os resumos semanais.

agua <- agua_nomes |>
  mutate(semana = as.integer(semana))

# ──────────────────────────────────────────────────────────────────────-------|
## ---- conferir-dados ----

# ETAPA 4 — conferir a biometria tratada, procurando NA inesperado, valor
# absurdo ou grupo incompleto. Confere só a biometria, não a tabela agua.

glimpse(biometria)
summary(biometria)

# O delineamento prevê seis tanques em cada densidade.

count(biometria, densidade)

# ──────────────────────────────────────────────────────────────────────-------|
## ---- exportar-dados ----

# ETAPA 5 — exportar cópias das bases tratadas (biometria.csv e agua.csv em
# dados/processados/), para abrir no Excel ou em outro programa.

# Esses arquivos são entregas, não fontes da análise: o relatório continua
# usando os objetos biometria e agua que estão na memória do R.

dir.create(here("dados", "processados"), showWarnings = FALSE)

write_csv2(biometria, here("dados", "processados", "biometria.csv"))
write_csv2(agua, here("dados", "processados", "agua.csv"))

# ──────────────────────────────────────────────────────────────────────-------|
## ---- explora-resumo ----

# Compara rapidamente tamanho, centro e dispersão dos grupos.

# O QUE CONFERIR:
#   - são seis tanques por grupo; o n válido pode variar conforme a resposta;
#     sobrevivencia possui NA. Confira como resumir_grupo() calcula n;
#   - compare a distância entre médias com a dispersão dentro dos grupos;
#   - desvios parecidos entre grupos (senão, atenção ao teste de Levene).

resumir_grupo(biometria, ganho_peso, densidade)
resumir_grupo(biometria, sobrevivencia, densidade)

# ──────────────────────────────────────────────────────────────────────-------|
## ---- explora-ganho ----

# Visualiza distribuição, dispersão e possíveis valores extremos, num boxplot
# com os tanques individuais.

# O QUE CONFERIR:
#   - caixas de tamanho parecido (variâncias homogêneas);
#   - nenhum ponto muito fora da sua caixa (possível erro de digitação);
#   - a mediana sugere uma tendência? A ANOVA compara médias, não medianas.
#     A aparência do boxplot, sozinha, não determina a significância.

# O boxplot resume a forma da distribuição; os pontos preservam a visão de
# quantos tanques existem e onde cada observação se encontra.

ggplot(biometria, aes(x = densidade, y = ganho_peso)) +
  geom_boxplot(width = 0.5, outlier.shape = NA, colour = "grey50") +
  geom_jitter(width = 0.1, height = 0, size = 2, alpha = 0.7) +
  labs(
    x = "Densidade (peixes/m³)",
    y = "Ganho de peso (g)",
    title = "Exploratório: ganho de peso por densidade"
  ) +
  tema_projeto()

# ──────────────────────────────────────────────────────────────────────-------|
## ---- explora-peso-comprimento ----

# Verifica a coerência biológica entre peso e comprimento.

# O QUE CONFERIR:
#   - os pontos formam uma nuvem crescente e apertada?
#   - algum ponto isolado (peso alto com comprimento baixo, ou o contrário)?
#     Se houver, volte à planilha e confira o tanque.

# A relação serve como verificação de plausibilidade e ajuda a encontrar
# possíveis erros de digitação.

# O T14 não tem comprimento (ver a seção tratar-biometria). Preferimos tirá-lo de
# propósito e dizer quantos ficaram de fora, em vez de deixar o ggplot
# descartar em silêncio.

com_comprimento <- filter(biometria, !is.na(comprimento))

message(
  nrow(biometria) - nrow(com_comprimento),
  " tanque(s) sem comprimento ficaram fora deste gráfico."
)

ggplot(com_comprimento, aes(x = comprimento, y = peso_final)) +
  geom_point(size = 2, alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, colour = "grey40", linewidth = 0.6) +
  labs(
    x = "Comprimento final (cm)",
    y = "Peso final (g)",
    title = "Exploratório: peso × comprimento"
  ) +
  tema_projeto()

# ──────────────────────────────────────────────────────────────────────-------|
## ---- explora-agua ----

# Verifica se a qualidade da água foi semelhante entre os tratamentos.

# O QUE CONFERIR:
#   - as linhas dos quatro tratamentos andam juntas em cada painel?
#   - alguma semana com queda brusca (falha de aeração, chuva)?
#   - oxigênio abaixo de 3 mg/L em algum grupo é sinal de alerta.

# A tabela "agua" está no formato longo (uma linha por tanque × semana).
# Juntamos a densidade de cada tanque e olhamos a média semanal por tratamento.

agua_resumo <- agua |>
  left_join(select(biometria, tanque, densidade), by = "tanque") |>
  pivot_longer(
    c(temperatura, oxigenio, ph),
    names_to = "variavel",
    values_to = "valor"
  ) |>
  group_by(densidade, semana, variavel) |>
  summarise(media = mean(valor, na.rm = TRUE), .groups = "drop")

ggplot(agua_resumo, aes(x = semana, y = media, colour = densidade)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.8) +
  facet_wrap(~ variavel, scales = "free_y", ncol = 1) +
  scale_colour_manual(values = cores_tratamento, name = "Densidade (peixes/m³)") +
  scale_x_continuous(breaks = 1:8) +
  labs(
    x = "Semana",
    y = NULL,
    title = "Exploratório: qualidade de água"
  ) +
  tema_projeto()

# ──────────────────────────────────────────────────────────────────────-------|
## ---- analisar ----

# ETAPA 1 — ajustar a ANOVA para testar se o ganho médio de peso difere entre
# as densidades (densidade como fator, ganho_peso como resposta).

# A ANOVA responde à pergunta global: existe pelo menos uma média diferente?
# Ela ainda não informa quais densidades diferem entre si.

modelo_ganho <- aov(ganho_peso ~ densidade, data = biometria)
tabela_anova <- anova(modelo_ganho)
tabela_anova

# ──────────────────────────────────────────────────────────────────────-------|
## ---- analisar-pressupostos ----

# ETAPA 2 — verificar os pressupostos da ANOVA: normalidade dos resíduos e
# homogeneidade das variâncias.

# Em ambos os testes, p > 0,05 significa que não há evidência suficiente
# para rejeitar o pressuposto avaliado. Os gráficos de diagnóstico completam
# essa verificação na seção exclusiva do caderno HTML.
# Não rejeitar um pressuposto não é comprovar que ele seja verdadeiro.

# Shapiro usa resíduos; Levene compara a dispersão da resposta entre grupos.

teste_normalidade <- shapiro.test(residuals(modelo_ganho))
teste_levene <- leveneTest(ganho_peso ~ densidade, data = biometria)

teste_normalidade
teste_levene

# ──────────────────────────────────────────────────────────────────────-------|
## ---- analisar-tukey ----

# ETAPA 3 — comparar as médias pelo teste de Tukey, para descobrir quais pares
# de densidade diferem entre si.

# Uma letra compartilhada indica que não se detectou diferença a 5 %;
# isso não demonstra equivalência entre médias. Os p-valores são ajustados.

# Aqui o Tukey é calculado direto. Ao reaproveitar este roteiro, confira antes
# o resultado global da ANOVA e a adequação da análise.

tukey_ganho <- TukeyHSD(modelo_ganho, "densidade")
tukey_ganho

letras <- multcompLetters(tukey_ganho$densidade[, "p adj"])$Letters

resumo_ganho <- resumir_grupo(biometria, ganho_peso, densidade) |>
  mutate(letra = letras[as.character(densidade)]) |>
  arrange(densidade)

resumo_ganho

# ──────────────────────────────────────────────────────────────────────-------|
## ---- analisar-tendencia ----

# ETAPA 4 — resumir a tendência linear, estimando quanto o ganho muda quando a
# densidade aumenta (densidade_num como variável quantitativa).

# A ANOVA compara grupos; esta regressão resume a direção e a intensidade
# média da relação em um único coeficiente.

modelo_tendencia <- lm(ganho_peso ~ densidade_num, data = biometria)
summary(modelo_tendencia)

# ──────────────────────────────────────────────────────────────────────-------|
## ---- preparar-resultados-texto ----

# ETAPA 5 — extrair, uma única vez, os números citados no texto dos Resultados;
# eles entram depois por expressões `r ...` no relatório.

# fmt() e formatar_p(), definidas em R/funcoes.R, aplicam vírgula decimal,
# número de casas e a escrita convencional dos valores de p.

f_valor   <- fmt(tabela_anova$`F value`[1])
gl_trat   <- tabela_anova$Df[1]
gl_res    <- tabela_anova$Df[2]
p_anova   <- formatar_p(tabela_anova$`Pr(>F)`[1], no_texto = TRUE)
p_shapiro <- formatar_p(teste_normalidade$p.value, no_texto = TRUE)
p_levene  <- formatar_p(teste_levene$`Pr(>F)`[1], no_texto = TRUE)
coef_tend <- abs(coef(modelo_tendencia)[2])

# coef_tend usa abs(): guarda a magnitude, não o sinal da inclinação.
# A frase "caiu" no QMD é específica deste exemplo; se os dados mudarem,
# confira o sinal de coef(modelo_tendencia)[2] e revise a interpretação.

# Textos narrativos não se atualizam automaticamente como os números inline.

# ──────────────────────────────────────────────────────────────────────-------|
## ---- diagnostico-variancia ----

# Avalia visualmente a constância da variância e a forma dos resíduos
# (resíduos versus valores ajustados).

# O QUE CONFERIR:
#   - a nuvem de pontos tem a mesma altura em todos os grupos (colunas);
#   - a linha vermelha fica perto de zero, sem curva;
#   - um funil (dispersão crescendo com a média) é sinal de variância
#     heterogênea: investigue sua origem e a adequação de alternativas,
#     como ANOVA de Welch. Kruskal-Wallis não é uma correção automática.

plot(modelo_ganho, which = 1)

# ──────────────────────────────────────────────────────────────────────-------|
## ---- diagnostico-normalidade ----

# Avalia visualmente a normalidade dos resíduos (gráfico quantil-quantil).

# O QUE CONFERIR:
#   - os pontos seguem a linha pontilhada, com pequenos desvios nas pontas;
#   - um "S" ou uma cauda que se descola é sinal de assimetria ou de
#     valor extremo. Com n pequeno (aqui, 24), pequenos desvios são normais.

plot(modelo_ganho, which = 2)

# ──────────────────────────────────────────────────────────────────────-------|
## ---- diagnostico-influencia ----

# Identifica observações que podem influenciar a conclusão (resíduos
# padronizados por nível do fator).

# O QUE CONFERIR:
#   - a maioria dos pontos entre -2 e 2;
#   - um ponto além de 3 merece uma volta à planilha: erro de digitação ou
#     um tanque que passou por algo diferente (ver a coluna observacoes).

# Os números junto aos pontos correspondem às linhas da base e permitem
# localizar cada observação suspeita.

plot(modelo_ganho, which = 5)

# ──────────────────────────────────────────────────────────────────────-------|
## ---- tbl-resumo ----

# Apresenta as estatísticas descritivas e os grupos do teste de Tukey, numa
# tabela formatada para as saídas HTML e DOCX.

resumo_ganho |>
  mutate(
    `IC 95 %` = paste0(fmt(ic_inf, 1), " a ", fmt(ic_sup, 1)),
    across(c(media, dp, ep), ~ fmt(.x, 1))
  ) |>
  select(
    `Densidade (peixes/m³)` = densidade,
    n,
    `Média` = media,
    DP = dp,
    EP = ep,
    `IC 95 %`,
    Tukey = letra
  ) |>
  flextable_ocean()

# ──────────────────────────────────────────────────────────────────────-------|
## ---- tbl-anova ----

# Converte a saída da ANOVA numa tabela de artigo científico (HTML e DOCX).

tabela_anova |>
  as.data.frame() |>
  mutate(
    Fonte = c("Densidade", "Resíduo"),
    GL = Df,
    SQ = fmt(`Sum Sq`, 1),
    QM = fmt(`Mean Sq`, 1),
    F = fmt(`F value`),
    p = formatar_p(`Pr(>F)`)
  ) |>
  select(Fonte, GL, SQ, QM, F, p) |>
  # A linha do resíduo não possui F nem p; por isso, deixamos as células vazias.
  mutate(across(c(F, p), ~ ifelse(is.na(.x) | .x == "-", "", .x))) |>
  flextable_ocean()

# ──────────────────────────────────────────────────────────────────────-------|
## ---- fig-ganho ----

# Figura principal da comparação entre densidades, reunindo dados individuais,
# médias, incerteza e o teste de Tukey.

# LEITURA DAS CAMADAS DO GRÁFICO:
#   1. geom_jitter()   -> cada ponto representa um tanque-rede;
#   2. geom_errorbar() -> intervalo de confiança de 95 % da média;
#   3. geom_point()    -> média de cada densidade;
#   4. geom_text()     -> letras do teste de Tukey.

ggplot() +
  geom_jitter(
    data = biometria,
    aes(x = densidade, y = ganho_peso, colour = densidade),
    width = 0.12,
    height = 0,
    size = 2,
    alpha = 0.6
  ) +
  geom_errorbar(
    data = resumo_ganho,
    aes(x = densidade, ymin = ic_inf, ymax = ic_sup),
    width = 0.2,
    linewidth = 0.6
  ) +
  geom_point(
    data = resumo_ganho,
    aes(x = densidade, y = media),
    size = 3,
    shape = 21,
    fill = "white",
    stroke = 1
  ) +
  geom_text(
    data = resumo_ganho,
    aes(x = densidade, y = ic_sup, label = letra),
    vjust = -0.8,
    size = 4
  ) +
  scale_colour_manual(values = cores_tratamento, guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.12))) +
  labs(
    x = "Densidade de estocagem (peixes/m³)",
    y = "Ganho de peso em 8 semanas (g)"
  ) +
  tema_projeto()

# ──────────────────────────────────────────────────────────────────────-------|
## ---- fig-tendencia ----

# Mostra a direção e a intensidade da tendência com a densidade: dispersão dos
# tanques com reta e IC 95 % da regressão linear.

# geom_smooth() estima a reta a partir do mesmo modelo linear resumido em
# analisar-tendencia; geom_point() mantém visíveis as observações originais.

ggplot(biometria, aes(x = densidade_num, y = ganho_peso)) +
  geom_smooth(method = "lm", colour = "grey30", fill = "grey85", linewidth = 0.7) +
  geom_point(aes(colour = densidade), size = 2, alpha = 0.7) +
  scale_colour_manual(values = cores_tratamento, guide = "none") +
  scale_x_continuous(breaks = c(50, 100, 150, 200)) +
  labs(
    x = "Densidade de estocagem (peixes/m³)",
    y = "Ganho de peso em 8 semanas (g)"
  ) +
  tema_projeto()

# ──────────────────────────────────────────────────────────────────────-------|
## ---- fim-do-codigo ----

# (nada além daqui entra no relatório)
