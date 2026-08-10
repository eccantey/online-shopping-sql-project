# Online Shopping SQL Project

## Overview
This is a project to demonstrate my skills in SQL and data visualization using a synthetic dataset. I generated a database for an online shopping platform with customers and suppliers based in the three North American countries (United States, Canada, Mexico). I then used SQL to clean customer data and then queried the data for analysis. Visualizations are being worked on at the moment in Tableau.

## Source Data Tables
Five tables were used for this project. They are as follows:

### Customers
**Columns:** customer_id, first_name, last_name, email, phone, city, state_province, country, zip_code, registration_date

This table contains customer data. There are 5,500 rows.

### Orders
**Columns:** order_id, customer_id, order_date, status, shipped_date, delivery_date, exp_delivery_date

This table includes information about each order placed by a customer. There are 10,000 rows.

### OrderDetails
**Columns:** order_id, product_id, quantity, unit_price_usd

This table includes every product included in every order, how many of each product, and the unit price in American dollars. There are 25,000 rows.

### Products
**Columns:** product_id, supplier_id, product_name, category, price_usd

This table contains information about every product. There are 250 rows.

### Suppliers
**Columns:** supplier_id, supplier_name, city, state_province, country

This table contains information about the suppliers of our products. There are 75 rows.

## Cleaning Process
The Customer data was intentionally generated with messy values to allow for data cleaning.

The following procedures were performed on the data:

1. **Standardize Name Casing.** The Customer names had various casings (upper, lower, mixed). I uppercased the first letter in each name then concatenated them to the rest of the names to standardize the name casing.
2. **Add Country Codes to Phone Numbers.** There were no country codes in any of the phone numbers generated, so I decided to add them. For each phone number belonging to a customer based in the United States or Canada, I added +1 to the phone number. For Mexico, I added +52.
3. **Standardize Country Spellings.** There were also a variety of spellings and casings of each of the three countries in North America, from 'USA' and 'U.S.A' to 'Canda' and 'Mexcio'. I uppercased each value of country, and mapped them out to one of `United States`, `Canada`, and `Mexico`.
4. **Standardize State and Province Values**. The values for state and province each also had different casings, so I applied UPPER to the state_province values to make them all uppercase.

After putting all the changes together, the Customer data was cleaned with standardized names, numbers, countries, and state/province values. The data was now ready for analysis.

## Analysis

## Conclusion

## Tools Used
* Tonic Fabricate
* Microsoft SQL Server Management Studio 22
* Tableau
