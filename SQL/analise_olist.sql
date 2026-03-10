-- 2. IDENTIFICAÇÃO DE PEDIDOS COM QUEBRA DE PRAZO
-- Objetivo: Listar pedidos onde a data de entrega real superou a data estimada.
-- Critério Técnico: Foi utilizado o operador ::DATE para ignorar diferenças de horas/minutos, 
-- focando apenas em atrasos que ultrapassaram o dia prometido (calendário).

SELECT 
	order_id,
	order_estimated_delivery_date,
	order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date::DATE > order_estimated_delivery_date::DATE;


-- 3. MENSURAÇÃO DA SEVERIDADE DO ATRASO (EM DIAS)
-- Objetivo: Calcular a diferença exata de dias entre o prometido e o entregue.
-- Valor do dado: Permite separar pequenos atrasos operacionais de falhas logísticas graves 
-- (outliers), fornecendo a base para futuras correlações com a insatisfação do cliente.

SELECT 
	order_id,
	order_estimated_delivery_date,
	order_delivered_customer_date,
	EXTRACT(DAY FROM order_delivered_customer_date - order_estimated_delivery_date) AS days_late
FROM orders
WHERE order_delivered_customer_date::DATE > order_estimated_delivery_date::DATE 
	AND EXTRACT(DAY FROM order_delivered_customer_date - order_estimated_delivery_date) != 0;
	
	
-- 4. ANÁLISE DE PERFORMANCE LOGÍSTICA POR ESTADO
-- Objetivo: Agrupar e ordenar a média de dias de atraso por unidade federativa.
-- Valor do dado: A ordenação decrescente (DESC) destaca imediatamente os estados com 
-- maior criticidade logística, permitindo identificar gargalos regionais.

SELECT 
	c.customer_state,
	ROUND(AVG(EXTRACT(DAY FROM o.order_delivered_customer_date - o.order_estimated_delivery_date))) AS avg_days_late,
	COUNT(DISTINCT o.order_id) AS total_orders_late
FROM orders o 
INNER JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date > o.order_estimated_delivery_date
	AND EXTRACT(DAY FROM o.order_delivered_customer_date - o.order_estimated_delivery_date) != 0
GROUP BY 1
ORDER BY avg_days_late DESC;


-- 5. IMPACTO DO STATUS DE ENTREGA NA SATISFAÇÃO DO CLIENTE
-- Objetivo: Comparar a percepção de qualidade (review_score) entre pedidos atrasados, antecipados e no prazo.
-- Insight: Demonstra o impacto direto da pontualidade logística na reputação da marca e 
-- valida se a antecipação da entrega gera um ganho real na percepção do cliente.

SELECT
	CASE 
		WHEN o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE THEN 'Pedido Atrasado'
		WHEN o.order_delivered_customer_date::DATE < o.order_estimated_delivery_date::DATE THEN 'Pedido Antecipado'
		ELSE 'Pedido no Prazo'
	END AS status_entrega,
	ROUND(AVG(review_score), 2) AS avg_review_score,
	COUNT(DISTINCT o.order_id) total_orders
FROM orders o
INNER JOIN order_reviews o_r
ON o.order_id = o_r.order_id
WHERE o.order_status = 'delivered'
	AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1;


-- 6. IMPACTO DO ATRASO POR CATEGORIA DE PRODUTO
-- Objetivo: Identificar quais categorias de produtos têm a pior percepção de qualidade quando ocorre um atraso.
-- Insight: Permite priorizar a eficiência logística para categorias críticas onde o cliente é menos tolerante a falhas no prazo.

SELECT
	COALESCE(p.product_category_name, 'Não Informado'),
	ROUND(AVG(review_score), 2) avg_review_score,
	COUNT(DISTINCT o.order_id) total_orders,
	ROUND(AVG(o_i.freight_value), 2) AS avg_freight_value,
	CASE 
		WHEN o.order_delivered_carrier_date > o_i.shipping_limit_date THEN 'Atraso do Vendedor (POSTAGEM)'
		ELSE 'Atraso da Transportadora (LOGISTICA)'
	END AS responsabilidade_atraso
FROM orders o
JOIN order_reviews o_r ON o.order_id = o_r.order_id
JOIN order_items o_i ON o.order_id = o_i.order_id
JOIN products p ON o_i.product_id = p.product_id
WHERE o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE
	AND EXTRACT(DAY FROM order_delivered_customer_date - order_estimated_delivery_date) != 0
GROUP BY 1, 5
ORDER BY avg_review_score ASC;


-- 7. DIAGNÓSTICO DE RESPONSABILIDADE (VENDEDOR VS TRANSPORTADORA)
-- Objetivo: Identificar o elo da cadeia onde ocorreu a falha que gerou o atraso final.
-- Valor do dado: Esta análise permite agir na causa raiz. Se o atraso é na postagem, 
-- aplica-se sanções aos vendedores; se é na logística, renegocia-se o frete ou transportadora.

SELECT 
	CASE 
		WHEN o.order_delivered_carrier_date > o_i.shipping_limit_date THEN 'Atraso do Vendedor (POSTAGEM)'
		ELSE 'Atraso da Transportadora (LOGISTICA)'
	END AS responsabilidade_atraso,
	ROUND(AVG(o_r.review_score), 2) avg_review_score,
	COUNT(DISTINCT o.order_id) total_orders
FROM orders o 
JOIN order_items o_i ON o.order_id = o_i.order_id
JOIN order_reviews o_r ON o.order_id = o_r.order_id
WHERE o.order_status = 'delivered'
	AND o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE
GROUP BY 1
ORDER BY avg_review_score ASC;


-- 8. ANÁLISE DE CORRELAÇÃO: CUSTO DO FRETE VS. TOLERÂNCIA AO ATRASO
-- Objetivo: Verificar se o valor pago pelo frete e o preço do produto influenciam a nota média em caso de atraso.
-- Insight: Identifica se fretes mais caros geram expectativas maiores e, consequentemente, 
-- maior insatisfação quando o prazo é descumprido, auxiliando na revisão da política de preços de frete.

SELECT 
	CASE
		WHEN o.order_delivered_carrier_date > o_i.shipping_limit_date THEN 'Atraso do Vendedo (POSTAGEM)'
		ELSE 'Atraso da Transportadora (LOGISTICA)'
	END AS responsalibidade_atraso,
	ROUND(AVG(o_r.review_score), 2) avg_review_score,
	ROUND(AVG(o_i.freight_value), 2) avg_freight_value,
	ROUND(AVG(o_i.price), 2) avg_product_price,
	COUNT(DISTINCT o.order_id) AS total_pedidos
FROM orders o 
JOIN order_items o_i ON o.order_id = o_i.order_id
JOIN order_reviews o_r ON o.order_id = o_r.order_id
WHERE o.order_status = 'delivered'
	AND o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE
GROUP BY 1
ORDER BY avg_freight_value;
