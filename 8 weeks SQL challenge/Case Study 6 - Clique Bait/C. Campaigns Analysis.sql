SELECT *
FROM event_identifier

SELECT *
FROM campaign_identifier

SELECT *
FROM events

SELECT *
FROM page_hierarchy

SELECT *
FROM users

------------------------C. Campaigns Analysis------------------------

/*Generate a table that has 1 single row for every unique visit_id record and has the following columns:

user_id
visit_id
visit_start_time: the earliest event_time for each visit
page_views: count of page views for each visit
cart_adds: count of product cart add events for each visit
purchase: 1/0 flag if a purchase event exists for each visit
campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date 
               and end_date
impression: count of ad impressions for each visit
click: count of ad clicks for each visit
(Optional column) cart_products: a comma separated text value with products added to the cart sorted 
by the order they were added to the cart (hint: use the sequence_number)*/

WITH visit_summary AS (
    SELECT e.visit_id,
           u.user_id,
           MIN(e.event_time) AS visit_start_time,
           SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_views,
           SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_adds,
           MAX(CASE WHEN e.event_type = 3 THEN 1 ELSE 0 END) AS purchase,
           SUM(CASE WHEN e.event_type = 4 THEN 1 ELSE 0 END) AS impression,
           SUM(CASE WHEN e.event_type = 5 THEN 1 ELSE 0 END) AS click
    FROM events AS e
    JOIN users AS u ON e.cookie_id = u.cookie_id
    GROUP BY e.visit_id, u.user_id
),
cart_products_cte AS (
    SELECT e.visit_id,
           STRING_AGG(p.page_name, ', ' ORDER BY e.sequence_number) AS cart_products
    FROM events AS e
    JOIN page_hierarchy AS p ON e.page_id = p.page_id
    WHERE e.event_type = 2 -- Only cart additions
    GROUP BY e.visit_id
)
SELECT vs.user_id,
       vs.visit_id,
       vs.visit_start_time,
       vs.page_views,
       vs.cart_adds,
       vs.purchase,
       c.campaign_name,
       vs.impression,
       vs.click,
       COALESCE(cp.cart_products, '') AS cart_products
FROM visit_summary AS vs
LEFT JOIN campaign_identifier AS c ON vs.visit_start_time BETWEEN c.start_date AND c.end_date
LEFT JOIN cart_products_cte AS cp ON vs.visit_id = cp.visit_id
ORDER BY vs.user_id, vs.visit_start_time;

/*Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare 
a single A4 infographic that the team can use for their management reporting sessions, be sure to 
emphasise the most important points from your findings.
Some ideas you might want to investigate further include:

Identifying users who have received impressions during each campaign period and 
comparing each metric with other users who did not have an impression event
Does clicking on an impression lead to higher purchase rates?
What is the uplift in purchase rate when comparing users who click on a campaign impression versus
users who do not receive an impression? What if we compare them with users who just an impression
but do not click?
What metrics can you use to quantify the success or failure of each campaign compared to eachother?*/