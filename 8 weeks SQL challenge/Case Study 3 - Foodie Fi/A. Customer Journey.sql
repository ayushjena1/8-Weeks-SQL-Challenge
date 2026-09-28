ALTER USER postgres SET search_path TO foodie_fi, public;
SET search_path=foodie_fi;

SELECT * FROM plans
SELECT * FROM subscriptions

------------------------A. Customer Journey------------------------

/*Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief 
description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your 
explanations a bit easier!*/

SELECT s.*, p.plan_name
FROM subscriptions AS s
JOIN plans AS p ON p.plan_id= s.plan_id
WHERE s.customer_id IN (1,14,28,90,137,180,421,503);

/*
1.  Customer 1: Started a 7-day trial on August 1, 2020, and automatically converted to the basic 
monthly plan when the trial ended on August 8, 2020.   
2.  Customer 14: Started a 7-day trial on September 22, 2020, and converted to the basic monthly plan 
on September 29, 2020.   
3.  Customer 28: Started a 7-day trial on June 30, 2020, and immediately upgraded directly to the pro
annual plan on July 7, 2020.   
4.  Customer 90: Followed a full upgrade path: started a trial on November 25, 2020 then downgraded to
basic monthly on December 2, 2020 then upgraded to pro monthly on March 28, 2021 then upgraded to
pro annual on April 28, 2021.   
5.  Customer 137: Started a 7-day trial on August 12, 2020, and converted directly to the pro monthly 
plan on August 19, 2020.   
6.  Customer 180: Started a trial on October 31, 2020 then converted to basic monthly on November 7, 2020 
then upgraded to pro monthly on January 17, 2021.   
7.  Customer 421: Started a 7-day trial on March 23, 2020, and converted directly to the pro monthly plan 
on March 30, 2020.   
8.  Customer 503: Started a 7-day trial on September 8, 2020, and converted directly to the pro monthly 
plan on September 15, 2020.  
*/
