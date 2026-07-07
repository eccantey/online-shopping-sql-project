use Shopping;

-- see what we're working with before cleaning
select * from Customers;

-- standardize casing of customer names
SELECT first_name,
       CONCAT(UPPER(LEFT(first_name, 1)), RIGHT(first_name, LEN(first_name) - 1)) AS first_name_clean,
       last_name,
       CONCAT(UPPER(LEFT(last_name, 1)), RIGHT(last_name, LEN(last_name) - 1)) AS last_name_clean
  FROM Customers;


-- add country codes to phone numbers; for now we'll replace null phone values with 'Not Available'
SELECT COALESCE(CASE
         WHEN UPPER(country) IN ('USA', 'U.S.A', 'US', 'UNITED STATES', 'UNTIED STATES', 'U.S.A.', 'CANADA', 'CANDA', 'CA', 'CAN') THEN '+1' + phone
         WHEN UPPER(country) IN ('MEX', 'MEXICO', 'MEXCIO', 'MX', 'MÉXICO') THEN '+52' + phone
       END, 'Not Available') AS phone
  FROM Customers;

-- standardize countries
SELECT country,
       CASE
         WHEN UPPER(country) IN ('USA', 'U.S.A', 'US', 'UNITED STATES', 'UNTIED STATES', 'U.S.A.') THEN 'United States'
         WHEN UPPER(country) IN ('MEX', 'MEXICO', 'MEXCIO', 'MX', 'MÉXICO') THEN 'Mexico'
         WHEN UPPER(country) IN ('CANADA', 'CANDA', 'CA', 'CAN') THEN 'Canada'
         ELSE 'Unknown'
       END AS country_clean
  FROM Customers;



-- standardize state_province values
SELECT state_province, UPPER(state_province) as state_province_clean
  FROM Customers;

-- put it all together
UPDATE Customers
   SET first_name = CONCAT(UPPER(LEFT(first_name, 1)), RIGHT(first_name, LEN(first_name) - 1)),
       last_name = CONCAT(UPPER(LEFT(last_name, 1)), RIGHT(last_name, LEN(last_name) - 1)),
       phone = CASE
                 WHEN UPPER(country) IN ('USA', 'U.S.A', 'US', 'UNITED STATES', 'UNTIED STATES', 'U.S.A.', 'CANADA', 'CANDA', 'CA', 'CAN') THEN '+1' + phone
                 WHEN UPPER(country) IN ('MEX', 'MEXICO', 'MEXCIO', 'MX', 'MÉXICO') THEN '+52' + phone
               END,
       state_province = UPPER(state_province),
       country = CASE
         WHEN UPPER(country) IN ('USA', 'U.S.A', 'US', 'UNITED STATES', 'UNTIED STATES', 'U.S.A.') THEN 'United States'
         WHEN UPPER(country) IN ('MEX', 'MEXICO', 'MEXCIO', 'MX', 'MÉXICO') THEN 'Mexico'
         WHEN UPPER(country) IN ('CANADA', 'CANDA', 'CA', 'CAN') THEN 'Canada'
         ELSE 'Unknown'
       END;

SELECT * FROM Customers;
