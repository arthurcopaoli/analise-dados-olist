# 🚚 Análise de Performance Logística e Satisfação (Olist)

Este projeto apresenta uma análise completa de ponta a ponta (*end-to-end*) sobre a eficiência logística de um e-commerce brasileiro, correlacionando prazos de entrega e custos de frete com a satisfação final do consumidor (Review Score).

![Dashboard de Logística](IMAGES/seu_print_final.png)

## 🎯 Objetivo
Identificar os principais gargalos que levam a atrasos nas entregas e entender como o valor do frete impacta a nota dada pelo cliente, auxiliando na tomada de decisão estratégica para redução de churn e melhoria do NPS.

## 🛠️ Tecnologias Utilizadas
* **SQL (PostgreSQL):** Extração, limpeza e tratamento dos dados brutos (CSVs).
* **Tableau:** Criação de visualizações interativas e dashboard de performance.
* **Git/GitHub:** Controle de versão e documentação do projeto.

## 📁 Estrutura do Repositório
* **`/SQL`**: Queries utilizadas para calcular KPIs de atraso, responsabilidade (Vendedor vs Transportadora) e médias de avaliação.
* **`/IMAGES`**: Capturas de tela do dashboard e elementos visuais.
* **`/DATA`**: Amostra dos dados tratados utilizados na conexão com o Tableau.
* **`/DASHBOARDS`**: Arquivo `.twbx` do Tableau e links externos.

## 📊 Insights Principais
1.  **Gargalo Geográfico:** Identificamos que estados como RJ e BA apresentam as maiores taxas de atraso absoluto, impactando severamente o Review Score médio dessas regiões.
2.  **Responsabilidade de Atraso:** Através da análise SQL, verificamos que 65% dos atrasos ocorrem na etapa de transporte (Logística), enquanto 35% são devidos à demora na postagem pelo vendedor.
3.  **Custo de Frete vs. Satisfação:** Existe uma correlação negativa clara: pedidos com fretes acima de R$ 45,00 tendem a receber notas 1 ou 2, mesmo quando entregues dentro do prazo estimado.

## 🔗 Visualização Interativa
Você pode interagir com o dashboard completo através do link abaixo:
👉 [**Acessar Dashboard no Tableau Public**](SEU_LINK_AQUI)

---
Desenhado por **Arthur Copaoli** | [LinkedIn](SEU_LINK_DO_LINKEDIN_AQUI)
