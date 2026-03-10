{\rtf1\ansi\ansicpg1252\cocoartf2639
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red31\green161\blue255;\red51\green51\blue51;\red209\green210\blue202;
\red32\green32\blue32;\red114\green255\blue80;\red255\green255\blue98;}
{\*\expandedcolortbl;;\cssrgb\c11800\c70000\c100000;\cssrgb\c26000\c26000\c26000;\cssrgb\c85500\c85500\c83100;
\cssrgb\c17000\c17000\c17000;\cssrgb\c50000\c100000\c38400;\cssrgb\c100000\c100000\c45500;}
\paperw11900\paperh16840\margl1440\margr1440\vieww28600\viewh15020\viewkind0
\deftab722
\pard\pardeftab722\pardirnatural\partightenfactor0

\f0\fs30 \cf2 \cb3 SELECT\cf4  * \cf2 FROM\cf4  customers \cf2 LIMIT\cf4  10;\
\cf2 SELECT\cf4  * \cf2 FROM\cf4  order_items \cf2 LIMIT\cf4  10;\
\cf2 SELECT\cf4  * \cf2 FROM\cf4  orders \cf2 LIMIT\cf4  10;\
\cf2 SELECT\cf4  * \cf2 FROM\cf4  products \cf2 LIMIT\cf4  10;\
\cf2 SELECT\cf4  * \cf2 FROM\cf4  order_reviews \cf2 LIMIT\cf4  10;\
\cb5 \
\cf6 \cb3 -- 2. IDENTIFICA\'c7\'c3O DE PEDIDOS COM QUEBRA DE PRAZO\cf4 \
\cf6 -- Objetivo: Listar pedidos onde a data de entrega real superou a data estimada.\cf4 \
\cf6 -- Crit\'e9rio T\'e9cnico: Foi utilizado o operador ::DATE para ignorar diferen\'e7as de horas/minutos, \cf4 \
\cf6 -- focando apenas em atrasos que ultrapassaram o dia prometido (calend\'e1rio).\cf4 \
\cb5 \
\cf2 \cb3 SELECT\cf4  \
	order_id,\
	order_estimated_delivery_date,\
	order_delivered_customer_date\
\cf2 FROM\cf4  orders\
\cf2 WHERE\cf4  order_delivered_customer_date::DATE > order_estimated_delivery_date::DATE;\
\cb5 \
\
\cf6 \cb3 -- 3. MENSURA\'c7\'c3O DA SEVERIDADE DO ATRASO (EM DIAS)\cf4 \
\cf6 -- Objetivo: Calcular a diferen\'e7a exata de dias entre o prometido e o entregue.\cf4 \
\cf6 -- Valor do dado: Permite separar pequenos atrasos operacionais de falhas log\'edsticas graves \cf4 \
\cf6 -- (outliers), fornecendo a base para futuras correla\'e7\'f5es com a insatisfa\'e7\'e3o do cliente.\cf4 \
\cb5 \
\cf2 \cb3 SELECT\cf4  \
	order_id,\
	order_estimated_delivery_date,\
	order_delivered_customer_date,\
	\cf2 EXTRACT\cf4 (\cf2 DAY\cf4  \cf2 FROM\cf4  order_delivered_customer_date - order_estimated_delivery_date) \cf2 AS\cf4  days_late\
\cf2 FROM\cf4  orders\
\cf2 WHERE\cf4  order_delivered_customer_date::DATE > order_estimated_delivery_date::DATE \
	\cf2 AND\cf4  \cf2 EXTRACT\cf4 (\cf2 DAY\cf4  \cf2 FROM\cf4  order_delivered_customer_date - order_estimated_delivery_date) != 0;\
\cb5 	\
	\
\cf6 \cb3 -- 4. AN\'c1LISE DE PERFORMANCE LOG\'cdSTICA POR ESTADO\cf4 \
\cf6 -- Objetivo: Agrupar e ordenar a m\'e9dia de dias de atraso por unidade federativa.\cf4 \
\cf6 -- Valor do dado: A ordena\'e7\'e3o decrescente (DESC) destaca imediatamente os estados com \cf4 \
\cf6 -- maior criticidade log\'edstica, permitindo identificar gargalos regionais.\cf4 \
\cb5 \
\cf2 \cb3 SELECT\cf4  \
	c.customer_state,\
	ROUND(AVG(\cf2 EXTRACT\cf4 (\cf2 DAY\cf4  \cf2 FROM\cf4  o.order_delivered_customer_date - o.order_estimated_delivery_date))) \cf2 AS\cf4  avg_days_late,\
	COUNT(\cf2 DISTINCT\cf4  o.order_id) \cf2 AS\cf4  total_orders_late\
\cf2 FROM\cf4  orders o \
\cf2 INNER\cf4  \cf2 JOIN\cf4  customers c\
\cf2 ON\cf4  o.customer_id = c.customer_id\
\cf2 WHERE\cf4  o.order_delivered_customer_date > o.order_estimated_delivery_date\
	\cf2 AND\cf4  \cf2 EXTRACT\cf4 (\cf2 DAY\cf4  \cf2 FROM\cf4  o.order_delivered_customer_date - o.order_estimated_delivery_date) != 0\
\cf2 GROUP\cf4  \cf2 BY\cf4  1\
\cf2 ORDER\cf4  \cf2 BY\cf4  avg_days_late \cf2 DESC\cf4 ;\
\cb5 \
\
\cf6 \cb3 -- 5. IMPACTO DO STATUS DE ENTREGA NA SATISFA\'c7\'c3O DO CLIENTE\cf4 \
\cf6 -- Objetivo: Comparar a percep\'e7\'e3o de qualidade (review_score) entre pedidos atrasados, antecipados e no prazo.\cf4 \
\cf6 -- Insight: Demonstra o impacto direto da pontualidade log\'edstica na reputa\'e7\'e3o da marca e \cf4 \
\cf6 -- valida se a antecipa\'e7\'e3o da entrega gera um ganho real na percep\'e7\'e3o do cliente.\cf4 \
\cb5 \
\cf2 \cb3 SELECT\cf4 \
	\cf2 CASE\cf4  \
		\cf2 WHEN\cf4  o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE \cf2 THEN\cf4  \cf7 'Pedido Atrasado'\cf4 \
		\cf2 WHEN\cf4  o.order_delivered_customer_date::DATE < o.order_estimated_delivery_date::DATE \cf2 THEN\cf4  \cf7 'Pedido Antecipado'\cf4 \
		\cf2 ELSE\cf4  \cf7 'Pedido no Prazo'\cf4 \
	\cf2 END\cf4  \cf2 AS\cf4  status_entrega,\
	ROUND(AVG(review_score), 2) \cf2 AS\cf4  avg_review_score,\
	COUNT(\cf2 DISTINCT\cf4  o.order_id) total_orders\
\cf2 FROM\cf4  orders o\
\cf2 INNER\cf4  \cf2 JOIN\cf4  order_reviews o_r\
\cf2 ON\cf4  o.order_id = o_r.order_id\
\cf2 WHERE\cf4  o.order_status = \cf7 'delivered'\cf4 \
	\cf2 AND\cf4  o.order_delivered_customer_date \cf2 IS\cf4  \cf2 NOT\cf4  \cf2 NULL\cf4 \
\cf2 GROUP\cf4  \cf2 BY\cf4  1;\
\cb5 \
\
\cf6 \cb3 -- 6. IMPACTO DO ATRASO POR CATEGORIA DE PRODUTO\cf4 \
\cf6 -- Objetivo: Identificar quais categorias de produtos t\'eam a pior percep\'e7\'e3o de qualidade quando ocorre um atraso.\cf4 \
\cf6 -- Insight: Permite priorizar a efici\'eancia log\'edstica para categorias cr\'edticas onde o cliente \'e9 menos tolerante a falhas no prazo.\cf4 \
\cb5 \
\cf2 \cb3 SELECT\cf4 \
	\cf2 COALESCE\cf4 (p.product_category_name, \cf7 'N\'e3o Informado'\cf4 ),\
	ROUND(AVG(review_score), 2) avg_review_score,\
	COUNT(\cf2 DISTINCT\cf4  o.order_id) total_orders,\
	ROUND(AVG(o_i.freight_value), 2) \cf2 AS\cf4  avg_freight_value,\
	\cf2 CASE\cf4  \
		\cf2 WHEN\cf4  o.order_delivered_carrier_date > o_i.shipping_limit_date \cf2 THEN\cf4  \cf7 'Atraso do Vendedor (POSTAGEM)'\cf4 \
		\cf2 ELSE\cf4  \cf7 'Atraso da Transportadora (LOGISTICA)'\cf4 \
	\cf2 END\cf4  \cf2 AS\cf4  responsabilidade_atraso\
\cf2 FROM\cf4  orders o\
\cf2 JOIN\cf4  order_reviews o_r \cf2 ON\cf4  o.order_id = o_r.order_id\
\cf2 JOIN\cf4  order_items o_i \cf2 ON\cf4  o.order_id = o_i.order_id\
\cf2 JOIN\cf4  products p \cf2 ON\cf4  o_i.product_id = p.product_id\
\cf2 WHERE\cf4  o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE\
	\cf2 AND\cf4  \cf2 EXTRACT\cf4 (\cf2 DAY\cf4  \cf2 FROM\cf4  order_delivered_customer_date - order_estimated_delivery_date) != 0\
\cf2 GROUP\cf4  \cf2 BY\cf4  1, 5\
\cf2 ORDER\cf4  \cf2 BY\cf4  avg_review_score \cf2 ASC\cf4 ;\
\cb5 \
\
\cf6 \cb3 -- 7. DIAGN\'d3STICO DE RESPONSABILIDADE (VENDEDOR VS TRANSPORTADORA)\cf4 \
\cf6 -- Objetivo: Identificar o elo da cadeia onde ocorreu a falha que gerou o atraso final.\cf4 \
\cf6 -- Valor do dado: Esta an\'e1lise permite agir na causa raiz. Se o atraso \'e9 na postagem, \cf4 \
\cf6 -- aplica-se san\'e7\'f5es aos vendedores; se \'e9 na log\'edstica, renegocia-se o frete ou transportadora.\cf4 \
\cb5 \
\cf2 \cb3 SELECT\cf4  \
	\cf2 CASE\cf4  \
		\cf2 WHEN\cf4  o.order_delivered_carrier_date > o_i.shipping_limit_date \cf2 THEN\cf4  \cf7 'Atraso do Vendedor (POSTAGEM)'\cf4 \
		\cf2 ELSE\cf4  \cf7 'Atraso da Transportadora (LOGISTICA)'\cf4 \
	\cf2 END\cf4  \cf2 AS\cf4  responsabilidade_atraso,\
	ROUND(AVG(o_r.review_score), 2) avg_review_score,\
	COUNT(\cf2 DISTINCT\cf4  o.order_id) total_orders\
\cf2 FROM\cf4  orders o \
\cf2 JOIN\cf4  order_items o_i \cf2 ON\cf4  o.order_id = o_i.order_id\
\cf2 JOIN\cf4  order_reviews o_r \cf2 ON\cf4  o.order_id = o_r.order_id\
\cf2 WHERE\cf4  o.order_status = \cf7 'delivered'\cf4 \
	\cf2 AND\cf4  o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE\
\cf2 GROUP\cf4  \cf2 BY\cf4  1\
\cf2 ORDER\cf4  \cf2 BY\cf4  avg_review_score \cf2 ASC\cf4 ;\
\cb5 \
\
\cf6 \cb3 -- 8. AN\'c1LISE DE CORRELA\'c7\'c3O: CUSTO DO FRETE VS. TOLER\'c2NCIA AO ATRASO\cf4 \
\cf6 -- Objetivo: Verificar se o valor pago pelo frete e o pre\'e7o do produto influenciam a nota m\'e9dia em caso de atraso.\cf4 \
\cf6 -- Insight: Identifica se fretes mais caros geram expectativas maiores e, consequentemente, \cf4 \
\cf6 -- maior insatisfa\'e7\'e3o quando o prazo \'e9 descumprido, auxiliando na revis\'e3o da pol\'edtica de pre\'e7os de frete.\cf4 \
\cb5 \
\cf2 \cb3 SELECT\cf4  \
	\cf2 CASE\cf4 \
		\cf2 WHEN\cf4  o.order_delivered_carrier_date > o_i.shipping_limit_date \cf2 THEN\cf4  \cf7 'Atraso do Vendedo (POSTAGEM)'\cf4 \
		\cf2 ELSE\cf4  \cf7 'Atraso da Transportadora (LOGISTICA)'\cf4 \
	\cf2 END\cf4  \cf2 AS\cf4  responsalibidade_atraso,\
	ROUND(AVG(o_r.review_score), 2) avg_review_score,\
	ROUND(AVG(o_i.freight_value), 2) avg_freight_value,\
	ROUND(AVG(o_i.price), 2) avg_product_price,\
	COUNT(\cf2 DISTINCT\cf4  o.order_id) \cf2 AS\cf4  total_pedidos\
\cf2 FROM\cf4  orders o \
\cf2 JOIN\cf4  order_items o_i \cf2 ON\cf4  o.order_id = o_i.order_id\
\cf2 JOIN\cf4  order_reviews o_r \cf2 ON\cf4  o.order_id = o_r.order_id\
\cf2 WHERE\cf4  o.order_status = \cf7 'delivered'\cf4 \
	\cf2 AND\cf4  o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE\
\cf2 GROUP\cf4  \cf2 BY\cf4  1\
\cf2 ORDER\cf4  \cf2 BY\cf4  avg_freight_value;\
\cb5 \
\
\
}