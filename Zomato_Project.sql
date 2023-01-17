USE Food_application;

SELECT * FROM users;
SELECT * FROM sales;
SELECT * FROM product;
SELECT * FROM goldusers_signup;

-- 1. What is the total amount each customer spent on zomato ?

SELECT userid, sum(price) as total_amount FROM 
sales s join product p
on s.product_id = p.product_id
GROUP BY userid ;

-- 2. How many days each customer visited zomato  ?

SELECT userid , COUNT( created_date) as Days_visited
FROM sales 
group by userid
ORDER BY userid;

-- 3. What was the first product purchased by each customer ?

SELECT userid, created_date, product_id FROM 
(SELECT * , row_number()over( partition by userid order by created_date) AS rn FROM sales) A 
WHERE rn = 1;

-- 4. What was the most purchased item and how many times was it purchased by all the customers ? 

SELECT userid , count(*) cnt  FROM sales WHERE product_id = 
(select  product_id from  sales
GROUP BY product_id
ORDER BY count(*) DESC 
LIMIT 1 )
GROUP BY userid ;

SELECT userid, product_id, cnt FROM 
(select userid, product_id, count(product_id) as cnt from sales
GROUP BY userid, product_id) A
WHERE product_id = 2 
GROUP BY userid, product_id;

-- 5. Which item has the most popular for each customer ?

SELECT * FROM 
(SELECT * , RANK() OVER (PARTITION BY userid ORDER BY cnt DESC ) AS rn FROM 
(
SELECT userid, product_id , count(product_id) as cnt from sales
group by userid, product_id
) A ) B
WHERE rn = 1;

-- 6. Which item was purchased first by the customer after they become a member ?
SELECT * FROM (
SELECT gs.userid, gold_signup_date,created_date,product_id , Rank()over(partition by userid order by created_date) as rn
FROM goldusers_signup gs left join sales s on gs.userid = s.userid AND gold_signup_date < created_date
 GROUP BY gs.userid, gold_signup_date,created_date,product_id) A 
WHERE rn = 1 ;

-- 7. Which item was purchased just before a customer became a member ?

SELECT * FROM (
SELECT gs.userid, gold_signup_date,created_date,product_id , Rank()over(partition by userid order by created_date DESC) as rn
FROM goldusers_signup gs left join sales s on gs.userid = s.userid AND gold_signup_date > created_date
 GROUP BY gs.userid, gold_signup_date,created_date,product_id) A 
WHERE rn = 1 ;



-- 8. What is the total orders and amount spent for each member before they became a member ?

select userid , count(created_date) as total_orders, sum(price) as total_amount from  (
select c.* , d.price from (
select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join  goldusers_signup b 
on a.userid = b.userid and created_date<=gold_signup_date
) C inner JOIN product d on c.product_id = d.product_id) E
group by userid;


--  9. If buying each product generates points for eg - 5Rs = 2 voucher point and each product have diff purchasing point 
-- p1 5rs = 1 voucher point 
-- p2 10rs = 5  voucher point
-- p3  5rs = 1 voucher point 
-- Calculate points collected by eacch customer ?
 
SELECT userid , SUM(total_points) points from (
SELECT e.* , amount/Rs total_points from (
SELECT d.* , case when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as Rs from 
(SELECT userid , product_id , sum(price) amount from (
SELECT s.userid , s.product_id, p.price FROM sales s inner join product p on s.product_id = p.product_id) C 
group by userid, product_id) d ) e) f
GROUP BY userid;


-- 10. In the first one year after a customer joins a gold program ( including their join date) irrespective of what the 
-- customer has purchased they earn 5 voucher points for every 10 rs spent who earned more 1 or 3 and what was their 
-- points earnings in their first year ?

SELECT userid , sum(points)*0.5 total_points from (
SELECT T.userid, T.created_date, T.product_id, T.gold_signup_date, (P.price/10)*5 AS points FROM 
(select a.userid, a.created_date, a.product_id, b.gold_signup_date from sales a inner join  goldusers_signup b 
on a.userid = b.userid and created_date >= gold_signup_date and created_date <= date_add(gold_signup_date, interval 1 year)
) T INNER JOIN product P on T.product_id = P.product_id ) K 
group by userid;

-- 11. Rank all the transaction of the customer 

SELECT * , rank()over (partition by userid order by created_date) rnk from sales;

-- 11. Rank all the transaction of each member whenever they are a gold member for every non gold 
-- member transaction mark as na 


select d.*, case when rnk = 0 then 'na' else rnk end as ranks from (
SELECT c.*, cast((case when gold_signup_date is null then 0 
else Rank()over (partition by userid order by created_date DESC) end ) as char) as rnk from
(  
SELECT s.userid, s.created_date, s.product_id , g.gold_signup_date FROM sales s
LEFT JOIN goldusers_signup g ON s.userid = g.userid AND created_date >= gold_signup_date)c)d









