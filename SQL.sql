use product;
create table product_sales (
prod_id varchar(10),
qty int,
price int,
discount int,
member varchar(10),
txn_id varchar(20),
start_txn_time datetime
)
#Q1
#What was the total quantity sold for all products?
select sum(qty)from product_sales;
#What is the total generated revenue for all products before discounts?
select sum(qty*price) from product_sales;
#What was the total discount amount for all products?
select sum(qty*price*discount)/100 from product_sales;

#Q2
#How many unique transactions were there?
select count(distinct (txn_id))from product_sales;
#What is the average unique products purchased in each transaction?
select count(prod_id)/count(distinct(txn_id)) as 'rerata product unique' from product_sales;

#What are the 25th, 50th and 75th percentile values for the revenue per transaction?
with revenue as(select txn_id, sum((qty*price)-(qty*price*discount)/100) as rev,
NTILE(100)over (order by sum((qty*price)-((qty*price*discount)/100))) as percentile
from product_sales
group by txn_id)
select max(rev),percentile
from revenue
where percentile in(25,50,75)
group by percentile;

#What is the average discount value per transaction?
select txn_id,avg((qty*price*discount)/100) as rerataDiscount from product_sales group by(txn_id);

#What is the percentage split of all transactions for members vs non-members?
select member,round(count(distinct(txn_id))/(select count(distinct(txn_id))from product_sales)*100,2) as persentase from product_sales group by member;

#What is the average revenue for member transactions and non-member transactions?
select member,avg((qty*price)-((qty*price*discount)/100))as 'rerata revenue' from product_sales group by member;

#Q3
#What is the percentage split of total revenue by category

with ProductSalesDetail as(select category_name,discount,qty,s.price,txn_id from product_sales s
left join product_details y
on s.prod_id=y.product_id)
select category_name,round(sum((qty*price)-((qty*price*discount)/100))/(select sum(((qty*price)-(qty*price*discount)/100)) from ProductSalesDetail)*100,2) as "persentase revenue" from ProductSalesDetail group by category_name;

#What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

select prod_id,
total_transaction_each_product,
total_transaction_each_product/total_transaction as penetration 
from(select prod_id, count(distinct(txn_id))as total_transaction_each_product
	from product_sales ps
	join product_details pd on ps.prod_id=pd.product_id 
	group by ps.prod_id) as sub_quary
cross join(select count(distinct txn_id) as total_transaction
from product_sales)as total_transaction;

#What is the most common coymbination of at least 1 quantit of any 3 products in a 1 single transaction?
with TransactionProductCombinations as(
	select txn_id,
    group_concat(distinct prod_id order by prod_id) as product_ids,
    count(*) as occurrence
from product_sales
where qty>0
group by txn_id
),
ProductCombinations as (select substring_index(product_ids,',',3)as combination
from TransactionProductCombinations
where char_length(product_ids) - char_length(replace(product_ids,',','')) >=2
),
MostCommonCombinations as(
select combination,
	count(*) as frequency
from ProductCombinations
group by combination 
order by frequency desc
limit 1
)
select mc.combination, mc.frequency
from MostCommonCombinations mc;
 