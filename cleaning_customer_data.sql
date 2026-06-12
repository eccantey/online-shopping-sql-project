use Shopping;

-- see what we're working with
select * from Customers;

-- replace null phone values with 'Not Available'
select COALESCE(phone, 'Not Available') as phone
  from Customers;

-- standardize countries
SELECT country, 
       CASE
         WHEN UPPER(country) IN ('USA', 'UNITED STATES') THEN 'United States'
         WHEN UPPER(country) IN ('MEX', 'MEXICO') THEN 'Mexico'
         WHEN UPPER(country) IN ('CANADA') THEN 'Canada'
       END AS country_clean
  FROM Customers;


-- standardize state_province values
SELECT state_province, UPPER(state_province) as state_province_clean
  FROM Customers;

-- put it all together
SELECT CONCAT(first_name, ' ', last_name) AS full_name,
       email,
       COALESCE(phone, 'Not Available') as phone,
       city,
       CASE
         WHEN UPPER(country) IN ('USA', 'UNITED STATES') THEN 'United States'
         WHEN UPPER(country) IN ('MEX', 'MEXICO') THEN 'Mexico'
         WHEN UPPER(country) IN ('CANADA') THEN 'Canada'
       END AS country,
       UPPER(state_province) as state_province
  FROM Customers;