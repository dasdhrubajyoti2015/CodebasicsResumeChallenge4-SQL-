select * from fact_sales_monthly;
#1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region

select distinct(market) from dim_customer where customer="Atliq Exclusive";

#2.What is the percentage of unique product increase in 2021 vs. 2020? The  final output contains these fields,
#unique_products_2020
#unique_products_2021
#percentage_chg

with  X as (select count(distinct product_code) as A,fiscal_year as y1 from fact_sales_monthly  where fiscal_year=2021),
	  Y as (select count(distinct product_code) as B,fiscal_year as y2 from fact_sales_monthly  where fiscal_year=2020)
select A,B,ROUND(((A-B)/B)*100,2) as percentage_chg from X
Cross Join Y;

-- ON X.y1=Y.y2+1;
#3.Provide a report with all the unique product counts for each segment and
#sort them in descending order of product counts. The final output contains 2 fields,
#segment
#product_count

select segment,count(distinct product_code) as product_count  from dim_product 
group by segment
order by product_count DESC;

#4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference
With  X as   (select p.segment,count(distinct p.product_code) as  product_count_2020 from dim_product  p
join fact_sales_monthly f
On p.product_code=f.product_code
where f.fiscal_year=2020
group by p.segment),

Y as (select p.segment,count(distinct p.product_code) as  product_count_2021 from dim_product  p
join fact_sales_monthly f
On p.product_code=f.product_code
where f.fiscal_year=2021
group by p.segment)

select X.segment,X.product_count_2020,Y.product_count_2021,(Y.product_count_2021-X.product_count_2020) as difference from X
Join Y
ON X.segment=Y.segment;

-- 5.Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost
with X as
(select  product_code,manufacturing_cost from fact_manufacturing_cost where manufacturing_cost IN(
(select MAX(manufacturing_cost) from fact_manufacturing_cost),
(select MIN(manufacturing_cost) from fact_manufacturing_cost)
))select X.product_code,product,manufacturing_cost from X 
Join dim_product p
ON X.product_code=p.product_code
order by manufacturing_cost DESC;

#6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the
--  Indian market. The final output contains these fields,
--  customer_code
--  customer
--  fact_pre_invoice_deductionsfact_pre_invoice_deductionsaverage_discount_percentage

                
	with X as (select customer_code,pre_invoice_discount_pct from fact_pre_invoice_deductions 
			where fiscal_year=2021),
		Y as (select customer_code,customer from dim_customer
                where market="India" )
                select X.customer_code,Y.customer,X.pre_invoice_discount_pct from X
                join Y
                on X.customer_code=Y.customer_code
                order by pre_invoice_discount_pct DESC limit 5;
                
#7. Get the complete report of the Gross sales amount for the customer “Atliq 
#Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.
#The final report contains these columns:
#Month
#Year
#Gross sales Amount
With X as 
(Select * from fact_sales_monthly where customer_code=ANY
	(select customer_code from dim_customer where customer="Atliq Exclusive")),
    Y as (select * from  fact_gross_price)
		select CONCAT(monthname(X.date),'(',Year(X.date),')') as Month,X.fiscal_year,SUM(ROUND(X.sold_quantity*Y.gross_price,2)) 
        as gross_sales  from X
        join Y
        on X.product_code=Y.product_code
        group by Month;
    
#8. In which quarter of 2020, got the maximum total_sold_quantity? The final
#output contains these fields sorted by the total_sold_quantity,
#Quarter
#total_sold_quantity
select  concat('[','Q',extract(Quarter from DATE_ADD(date,Interval 4  Month)),']',monthname(date)) as Quarter,
SUM(sold_quantity) as Quantity_Sold from fact_sales_monthly where fiscal_year=2020
group by Quarter;

select  concat('Q',extract(Quarter from DATE_ADD(date,Interval 4  Month))) as Quarter,
SUM(sold_quantity) as Quantity_Sold from fact_sales_monthly where fiscal_year=2020
group by Quarter;

--  Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
--  gross_sales_mln
-- percentage
With cte1 as(
select c.channel,SUM(s.sold_quantity*g.gross_price) as gross_sales
	from fact_sales_monthly s
    join fact_gross_price g  on s.product_code=g.product_code 
    join dim_customer c on s.customer_code=c.customer_code
    where s.fiscal_year=2021
    group by c.channel
    ORDER BY gross_sales DESC)
    select channel,
    round(gross_sales/1000000,2) as sales_Mln,
    Round(gross_sales/(SUM(gross_sales) over() )*100,2) as percentage
    from cte1;
#10. Get the Top 3 products in each division that have a high
#total_sold_quantity in the fiscal_year 2021? The final output contains these
#fields,
#division
#product_code
#product
#total_sold_quantity
#rank_order   

with cte1 AS (select p.product_code,division,concat(p.product,'(',p.variant,')') as product,
SUM(s.sold_quantity) as sold_qty ,
rank() over(partition by division order by SUM(s.sold_quantity) DESC) as rnk
 from fact_sales_monthly s
Join dim_product p
ON s.product_code=p.product_code
where fiscal_year=2021
group by product_code) select *
 from cte1
where rnk<=3;


    
   
			  
            
            
            
            
			  