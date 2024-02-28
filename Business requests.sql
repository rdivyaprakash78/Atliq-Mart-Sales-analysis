-- Products with base price higher than 500 and in BOGOF

SELECT 
DISTINCT(retail_events_db.FACTS.base_price) as base_price,
SUBSTRING(retail_events_db.dim_products.product_name,7,CHAR_LENGTH(retail_events_db.dim_products.product_name)) as product_name
FROM retail_events_db.FACTS JOIN retail_events_db.dim_products
ON retail_events_db.FACTS.product_code = retail_events_db.dim_products.product_code
WHERE (retail_events_db.FACTS.promo_type = 'BOGOF') AND
(retail_events_db.FACTS.base_price > 500)
ORDER BY retail_events_db.FACTS.base_price;

-- City wise store count

SELECT COUNT(store_id) as store_count, city FROM dim_stores
GROUP BY city
ORDER BY store_count DESC;

-- Revenue before and after promo

SELECT dim_campaigns.campaign_name, 
CONCAT(FORMAT(SUM(facts.revBpromo)/1000000,2),' M') AS revenue_before_promo, 
CONCAT(FORMAT(SUM(facts.revApromo)/1000000,2),' M') AS revenue_after_promo
FROM facts JOIN dim_campaigns
ON dim_campaigns.campaign_id = facts.campaign_id
GROUP BY dim_campaigns.campaign_name;

-- Ranking product categories based on ISU percent during the diwali campaign

SELECT category, ISU_Percent, 
RANK() OVER (ORDER BY CAST(LEFT(ISU_Percent, char_length(ISU_Percent)-2) AS SIGNED) DESC) as Rank_
FROM
(
	SELECT 
	category,
	CONCAT(FORMAT((ISU/SBP)*100,2), ' %') AS ISU_Percent
	FROM
	(
			SELECT 
			dim_products.category,
			SUM((facts.`quantity_sold(after_promo)` - facts.`quantity_sold(before_promo)`)) as ISU,
			SUM(facts.`quantity_sold(before_promo)`) as SBP
			FROM facts 
            JOIN dim_products ON facts.product_code = dim_products.product_code
            JOIN dim_campaigns ON facts.campaign_id = dim_campaigns.campaign_id
            WHERE dim_campaigns.campaign_name = 'Diwali'
			GROUP BY dim_products.category
	)
	AS Subquery_table
) AS Subquery_table2;


-- Top 5 products with highest Incremental revenue

SELECT 
product_name AS Product,
CONCAT(FORMAT((IR/RBP)*100,2), ' %') AS IR_Percent
FROM
(
	SELECT
	SUM(facts.revApromo - facts.revBpromo) as IR,
    SUM(facts.revBpromo) as RBP,
	SUBSTRING(dim_products.product_name,7,CHAR_LENGTH(dim_products.product_name)) as product_name
	FROM facts JOIN dim_products
	ON Facts.product_code = dim_products.product_code
	GROUP BY product_name
) 
AS SUBQUERY_TABLE
ORDER BY CAST(LEFT(IR_Percent, char_length(IR_Percent)-2) AS SIGNED) DESC
LIMIT 5;

