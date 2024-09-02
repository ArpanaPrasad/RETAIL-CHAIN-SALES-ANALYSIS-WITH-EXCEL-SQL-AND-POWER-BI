
CREATE DATABASE Integerated_Case_studies_TERM1;

USE Integerated_Case_studies_TERM1


-----------
---B). Drop the observations(rows) if MCN is null or storeID is null or Cash_Memo_No

DELETE FROM ['Transaction Data$']
WHERE MCN IS NULL OR [Store ID] IS NULL OR Cash_Memo_No IS NULL

SELECT * FROM ['Transaction Data$']



--C) Join both tables considering Transaction table as base table 


SELECT * INTO FINAL_DATA 
FROM ['Transaction Data$'] AS T
LEFT JOIN CustData$ AS C
ON T.MCN = C.CustID

SELECT * FROM FINAL_DATA

--D).Calculate the discount variable

ALTER TABLE FINAL_DATA 
ADD DISCOUNT FLOAT 

UPDATE FINAL_DATA
SET  Discount = TotalAmount-SaleAmount 


--Filter the Final_Data using sample_flag=1

SELECT * INTO SAMPLE_DATA 
FROM FINAL_DATA
WHERE Sample_flag = 1

SELECT * FROM SAMPLE_DATA
-----------------------------------------------------------------------------------------------------------

---1)Count the number of observations having any of the variables having null value/missing values?

SELECT COUNT(*) AS COUNT_OF_NULL
FROM FINAL_DATA
WHERE  ItemCount IS NULL OR TransactionDate IS NULL OR 
       TotalAmount IS NULL OR SaleAmount IS NULL OR SalePercent IS NULL 
       OR CASH_MEMO_NO IS NULL  OR Dep1Amount IS NULL 
       OR Dep2Amount IS NULL OR Dep3Amount IS NULL 
       OR Dep3Amount IS NULL OR Dep4Amount IS NULL
       OR Store_ID IS NULL OR MCN IS NULL OR CustID IS NULL 
       OR Gender IS NULL OR [Location] IS NULL  OR Age IS NULL 
       OR Cust_seg IS NULL OR Sample_flag IS NULL 
        


----2) How many customers have shopped? 

SELECT COUNT(CustID) AS NO_OF_CUSTOMER_SHOPPED FROM 
  (
   SELECT CUSTID , COUNT(CUSTID) AS PURCHASE_COUNT 
   FROM FINAL_DATA
   WHERE TotalAmount > 0
   GROUP BY CustID
   ) AS X 


---3) How many shoppers (customers) visiting more than 1 store?


SELECT COUNT(CUSTID) COUNT_OF_SHOP_VISITING  
FROM 
 (
  SELECT CustID , COUNT(STORE_ID) AS NO_OF_VISITING 
  FROM FINAL_DATA
  GROUP BY CustID
  HAVING COUNT(STORE_ID) > 1
  ) AS X


SELECT * FROM FINAL_DATA 

----4)What is the distribution of shoppers by day of the week? 
--How the customer shopping behavior on each day of week?

SELECT  DATENAME(WEEKDAY,[TransactionDate]) AS [WEEKDAY]
        , COUNT(CUSTID) AS NO_OF_CUSTOMER ,COUNT(CASH_MEMO_NO) AS COUNT_OF_TRANSACTION 
		,SUM(TOTALAMOUNT) AS TOTAL_AMOUNT , SUM(SALEAMOUNT) AS TOTAL_SALES
		, SUM(SalePercent) AS [SALE_%] , SUM(ITEMCOUNT) AS TOTAL_QTY
FROM FINAL_DATA
GROUP BY DATENAME(WEEKDAY,[TransactionDate])
ORDER BY TOTAL_SALES DESC

---5)What is the average revenue per customer/average revenue per customer by each location?

SELECT CustID , [Location] , AVG(SALEAMOUNT) AS AVERAGE_REVENUE 
FROM FINAL_DATA
GROUP BY CustID , [Location]


----6)Average revenue per customer by each store etc?


SELECT [CustID] , Store_ID  , AVG(SALEAMOUNT) AS AVERAGE_REVENUE 
FROM FINAL_DATA
GROUP BY  [CustID] , Store_ID 

---7)Find the department spend by store wise?


SELECT Store_ID  , SUM(Dep1Amount) AS SPEND_OF_DEP1,
      SUM(Dep2Amount) AS SPEND_OF_DEP2 , SUM(Dep3Amount) AS SPEND_OF_DEP3
	  ,SUM(Dep4Amount) AS SPEND_OF_DEP4
FROM FINAL_DATA
GROUP BY Store_ID 


---8) What is the Latest transaction date and Oldest Transaction date?

SELECT MAX(TRANSACTIONDATE) AS LATEST_TRANS_DATE ,
       MIN(TRANSACTIONDATE) AS OLDEST_TRANS_DATE
FROM FINAL_DATA

--9) How many months of data provided for the analysis?


SELECT DATEDIFF( MM ,  OLDEST_TRANS_DATE , LATEST_TRANS_DATE ) AS NO_OF_MONTHS 
FROM (
SELECT MAX(TRANSACTIONDATE) AS LATEST_TRANS_DATE ,
       MIN(TRANSACTIONDATE) AS OLDEST_TRANS_DATE
FROM FINAL_DATA
                ) AS X

--10) Find the top 3 locations interms of spend and total contribution of sales out of total sales?

SELECT  TOP 3
[Location],SUM(TOTALAMOUNT) AS TOTAL_SPEND ,
SUM(SALEAMOUNT) AS TOTAL_SALES
FROM FINAL_DATA
GROUP BY [Location]
ORDER BY TOTAL_SALES DESC

--11)Find the customer count and Total Sales by Gender?


SELECT GENDER , COUNT(CUSTOMERID) AS NO_OF_CUSTOMER,
               SUM(SALEAMOUNT) AS TOTAL_SALE
FROM FINAL_DATA
WHERE GENDER IS NOT NULL 
GROUP BY Gender

--12)What is total  discount and percentage of discount given by each location?

SELECT * , TOTAL_DISCOUNT/(SELECT SUM(DISCOUNT) FROM FINAL_DATA) AS [%_DISCOUNT]
FROM (
   SELECT [Location] , SUM(DISCOUNT) AS TOTAL_DISCOUNT
   FROM FINAL_DATA
   GROUP BY [Location]
     ) AS Z

--13)Which segment of customers contributing maximum sales?

SELECT Cust_seg , SUM(SALEAMOUNT) AS MAX_SALES
FROM FINAL_DATA
GROUP BY Cust_seg
ORDER BY MAX_SALES DESC

--14) What is the average transaction value by location, gender, segment?

SELECT Gender , [Location] , Cust_seg , AVG(SALEAMOUNT) AS AVG_SALES
FROM FINAL_DATA
GROUP BY Gender , [Location] , Cust_seg



--15) Create Customer_360 Table with below columns.


select * Into Customer_360
	   from ( 
    select 
    CUSTOMERID AS CUSTOMER_ID,
    Gender,
    [Location],
    Age,
    Cust_seg,
    COUNT(CUSTOMERID) AS No_of_transactions,
    SUM(ITEMCOUNT) AS No_of_items,
    SUM(SALEAMOUNT) AS Total_sale_amount,
    AVG(SALEAMOUNT) AS Average_transaction_value,
    SUM(DEP1AMOUNT) AS TotalSpend_Dep1,
    SUM(Dep2Amount) AS TotalSpend_Dep2,
    SUM(Dep3Amount) AS TotalSpend_Dep3,
    SUM(Dep4Amount) AS TotalSpend_Dep4,
    SUM(CASE WHEN DATEPART(WEEKDAY, transactiondate) IN (1,7 ) THEN 1 ELSE 0 END) AS weekend_count,
    SUM(CASE WHEN DATEPART(WEEKDAY, transactiondate) NOT IN (1, 7) THEN 1 ELSE 0 END) AS weekday_count , 
    RANK() OVER (ORDER BY SaleAmount DESC) AS Rank_based_on_Spend , 
        NTILE(10) OVER (ORDER BY SaleAmount) AS Decile
     FROM FINAL_DATA  
    GROUP BY CUSTOMERID, Gender, [Location], Age, Cust_seg , SaleAmount
	) as x


SELECT * FROM Customer_360