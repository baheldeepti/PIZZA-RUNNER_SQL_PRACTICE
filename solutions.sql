**Schema (PostgreSQL v13)**

    CREATE SCHEMA pizza_runner;
    SET search_path = pizza_runner;
    
    DROP TABLE IF EXISTS runners;
    CREATE TABLE runners (
      "runner_id" INTEGER,
      "registration_date" DATE
    );
    INSERT INTO runners
      ("runner_id", "registration_date")
    VALUES
      (1, '2021-01-01'),
      (2, '2021-01-03'),
      (3, '2021-01-08'),
      (4, '2021-01-15');
    
    
    DROP TABLE IF EXISTS customer_orders;
    CREATE TABLE customer_orders (
      "order_id" INTEGER,
      "customer_id" INTEGER,
      "pizza_id" INTEGER,
      "exclusions" VARCHAR(4),
      "extras" VARCHAR(4),
      "order_time" TIMESTAMP
    );
    
    INSERT INTO customer_orders
      ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
    VALUES
      ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
      ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
      ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
      ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
      ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
      ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
      ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
      ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
      ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
      ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
      ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
      ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
      ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
      ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');
    
    
    DROP TABLE IF EXISTS runner_orders;
    CREATE TABLE runner_orders (
      "order_id" INTEGER,
      "runner_id" INTEGER,
      "pickup_time" VARCHAR(19),
      "distance" VARCHAR(7),
      "duration" VARCHAR(10),
      "cancellation" VARCHAR(23)
    );
    
    INSERT INTO runner_orders
      ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
    VALUES
      ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
      ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
      ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
      ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
      ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
      ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
      ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
      ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
      ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
      ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');
    
    
    DROP TABLE IF EXISTS pizza_names;
    CREATE TABLE pizza_names (
      "pizza_id" INTEGER,
      "pizza_name" TEXT
    );
    INSERT INTO pizza_names
      ("pizza_id", "pizza_name")
    VALUES
      (1, 'Meatlovers'),
      (2, 'Vegetarian');
    
    
    DROP TABLE IF EXISTS pizza_recipes;
    CREATE TABLE pizza_recipes (
      "pizza_id" INTEGER,
      "toppings" TEXT
    );
    INSERT INTO pizza_recipes
      ("pizza_id", "toppings")
    VALUES
      (1, '1, 2, 3, 4, 5, 6, 8, 10'),
      (2, '4, 6, 7, 9, 11, 12');
    
    
    DROP TABLE IF EXISTS pizza_toppings;
    CREATE TABLE pizza_toppings (
      "topping_id" INTEGER,
      "topping_name" TEXT
    );
    INSERT INTO pizza_toppings
      ("topping_id", "topping_name")
    VALUES
      (1, 'Bacon'),
      (2, 'BBQ Sauce'),
      (3, 'Beef'),
      (4, 'Cheese'),
      (5, 'Chicken'),
      (6, 'Mushrooms'),
      (7, 'Onions'),
      (8, 'Pepperoni'),
      (9, 'Peppers'),
      (10, 'Salami'),
      (11, 'Tomatoes'),
      (12, 'Tomato Sauce');

---

**Query #1**

    SELECT
     date_trunc('week', registration_date) AS
     week_start_date,
     count(distinct runner_id)
     FROM
     pizza_runner.runners
     GROUP BY 1;

| week_start_date          | count |
| ------------------------ | ----- |
| 2020-12-28T00:00:00.000Z | 2     |
| 2021-01-04T00:00:00.000Z | 1     |
| 2021-01-11T00:00:00.000Z | 1     |

---
**Query #2**

    WITH cte AS (
      SELECT
        runner_id,
        CASE
          WHEN duration IS NOT NULL AND duration NOT IN ('null', '') THEN
            CAST(LEFT(duration, 2) AS INTEGER)
          WHEN duration IN ('null', '') OR duration IS NULL THEN
            0
          ELSE
            NULL
        END AS pickup_time_duration
      FROM pizza_runner.runner_orders
    )
    SELECT
      runner_id,
      AVG(pickup_time_duration) AS avg_pickup_time_in_mins
    FROM cte
    GROUP BY runner_id;

| runner_id | avg_pickup_time_in_mins |
| --------- | ----------------------- |
| 3         | 7.5000000000000000      |
| 2         | 20.0000000000000000     |
| 1         | 22.2500000000000000     |

---
**Query #3**

    WITH cte AS (
      SELECT
        a.runner_id,
      case when pickup_time not in ('null','') and pickup_time is not null then 
        EXTRACT(EPOCH FROM (CAST(pickup_time AS TIMESTAMP) - order_time)) / 60 
      else 0
      end AS pickup_time_duration
      FROM pizza_runner.runner_orders a
      right JOIN pizza_runner.customer_orders b ON a.order_id = b.order_id
      
    )
    SELECT
      runner_id,
      ROUND(avg(pickup_time_duration)::numeric, 2)::double precision
    FROM cte
    GROUP BY runner_id
    order by 2 desc;

| runner_id | round |
| --------- | ----- |
| 2         | 19.77 |
| 1         | 15.68 |
| 3         | 5.23  |

---
**Query #4**

    WITH cte AS (
      SELECT
        pizza_id,
      case when pickup_time not in ('null','') and pickup_time is not null then 
        EXTRACT(EPOCH FROM (CAST(pickup_time AS TIMESTAMP) - order_time)) / 60 
      else 0
      end AS prep_time_duration
      FROM pizza_runner.runner_orders a
      right JOIN pizza_runner.customer_orders b ON a.order_id = b.order_id
      
    )
    SELECT
      ROUND((prep_time_duration)::numeric, 2)::double precision,
      count(pizza_id) as pizza_prepared
    FROM cte
    GROUP BY 1
    order by 2 desc;

| round | pizza_prepared |
| ----- | -------------- |
| 29.28 | 3              |
| 21.23 | 2              |
| 15.52 | 2              |
| 0     | 2              |
| 20.48 | 1              |
| 10.47 | 1              |
| 10.03 | 1              |
| 10.53 | 1              |
| 10.27 | 1              |

---
**Query #5**

    WITH cte AS (
      SELECT
        customer_id,
      case when distance not in ('null','') and distance is not null then distance
      else '0'
      end AS distance
      FROM pizza_runner.runner_orders a
      right JOIN pizza_runner.customer_orders b ON a.order_id = b.order_id
    ),
    final as 
    (
      SELECT
      customer_id,
      REPLACE(distance, 'km', '') as distance
     FROM cte)
     SELECT
     customer_id,
     round(avg(distance::numeric),2) as avg_distance
     from final
     group by 1
    order by 2;

| customer_id | avg_distance |
| ----------- | ------------ |
| 104         | 10.00        |
| 101         | 13.33        |
| 102         | 16.73        |
| 103         | 17.55        |
| 105         | 25.00        |

---
**Query #6**

    WITH cte AS (
      SELECT
        b.order_id,
        CASE
          WHEN duration IS NOT NULL AND duration NOT IN ('null', '') THEN
            CAST(LEFT(duration, 2) AS INTEGER)
          WHEN duration IN ('null', '') OR duration IS NULL THEN
            0
          ELSE
            NULL
        END AS pickup_time_duration
      FROM pizza_runner.runner_orders  a
      right JOIN pizza_runner.customer_orders b ON a.order_id = b.order_id
    )
    SELECT
     max(pickup_time_duration) - min(pickup_time_duration) as difference
    FROM cte
    where pickup_time_duration > 0
    ;

| difference |
| ---------- |
| 30         |

---
**Query #7**

    WITH cte AS (
      SELECT
        a.runner_id,
        CASE
          WHEN duration IS NOT NULL AND duration NOT IN ('null', '') THEN
            CAST(LEFT(duration, 2) AS INTEGER)
          WHEN duration IN ('null', '') OR duration IS NULL THEN
            0
          ELSE
            NULL
        END AS pickup_time_duration,
      case when distance not in ('null','') and distance is not null then distance
      else '0'
      end AS distance
      FROM pizza_runner.runner_orders  a
      right JOIN pizza_runner.customer_orders b ON a.order_id = b.order_id
    ),
    final as
    (SELECT
     runner_id,
     pickup_time_duration,
     REPLACE(distance, 'km', '') as distance
    FROM cte)
    SELECT
    runner_id,
    round((sum(cast(distance as numeric))/sum(pickup_time_duration)*60) ,2) as speed
    from final
    group by 1
    order by 2 desc;

| runner_id | speed |
| --------- | ----- |
| 2         | 44.48 |
| 1         | 43.76 |
| 3         | 40.00 |

---
**Query #8**

    WITH cte AS (
      SELECT
        runner_id,
        SUM(CASE WHEN cancellation NOT IN ('null', '') AND cancellation IS NOT NULL THEN 1 ELSE 0 END) AS orders_delivered,
        COUNT(*) AS total_orders
      FROM pizza_runner.runner_orders
      GROUP BY runner_id
    )
    SELECT
      runner_id,
      ROUND(COALESCE(orders_delivered::numeric / NULLIF(total_orders, 0), 0),2)*100 AS order_delivered_percentage
    FROM cte;

| runner_id | order_delivered_percentage |
| --------- | -------------------------- |
| 3         | 50.00                      |
| 2         | 25.00                      |
| 1         | 0.00                       |

---

[View on DB Fiddle](https://www.db-fiddle.com/f/7VcQKQwsS3CTkGRFG7vu98/1910)
