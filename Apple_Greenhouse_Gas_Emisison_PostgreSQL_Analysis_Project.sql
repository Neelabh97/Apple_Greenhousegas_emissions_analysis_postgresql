--GreenhouseGasEmissions
DROP TABLE GreenhouseGasEmissions;
CREATE TABLE GreenhouseGasEmissions (
    FiscalYear INT,
    Category VARCHAR(50),
    Type VARCHAR(50),
    Scope VARCHAR(50),
    Description TEXT,
    Emissions FLOAT
);




-- TABLE CarbonFootprintByProduct 
 CREATE TABLE CarbonFootprintByProduct (
    ReleaseYear INT,
    Product VARCHAR(100),
    BaselineStorage VARCHAR(50),
    CarbonFootprint FLOAT
);

--- TABLE NormalizingFactors

CREATE TABLE NormalizingFactors (
    FiscalYear INT,
    Revenue FLOAT,
    MarketCapitalization FLOAT,
    Employees INT
);


--1. How much has Apple reduced their emissions from 2015 to 2022?
 ---- Solving Using CTE
with Emission_2022 as 
(
	select fiscalyear, sum(emissions) as total_emission_1
	from GreenhouseGasEmissions
	where fiscalyear = '2022'
	group by fiscalyear
	
),
 Emission_2015 as 
( 
	select fiscalyear, sum(emissions) as total_emission_2
	from GreenhouseGasEmissions
	where fiscalyear = '2015'
	group by fiscalyear
)

select total_emission_1, total_emission_2, (total_emission_1 - total_emission_2) as Emission_Reduction
from Emission_2022, Emission_2015;

--- Solving Using Subquerry.
SELECT 
    (SELECT SUM(Emissions) FROM GreenhouseGasEmissions WHERE FiscalYear = 2015) AS Emissions2015,
    (SELECT SUM(Emissions) FROM GreenhouseGasEmissions WHERE FiscalYear = 2022) AS Emissions2022,
    (SELECT SUM(Emissions) FROM GreenhouseGasEmissions WHERE FiscalYear = 2022) - (SELECT SUM(Emissions) FROM GreenhouseGasEmissions WHERE FiscalYear = 2015) AS EmissionsReduction

-- 2. How does 2015 compare to 2022 revenue & market cap.
-- Using CTE 
select * from NormalizingFactors;

With Revenue_Marketcap_2015 as
( 
 select Fiscalyear, sum(revenue) as Revenue_2015, sum(marketcapitalization) as Marketcap_2015
 from NormalizingFactors
 where fiscalyear = '2015'
 group by Fiscalyear

),
Revenue_Marketcap_2022 as 
( 
 select Fiscalyear, sum(revenue) as Revenue_2022, sum(marketcapitalization) as Marketcap_2022
 from NormalizingFactors
 where fiscalyear = '2022'
 group by Fiscalyear
)

select Revenue_2015, Revenue_2022, Marketcap_2015,Marketcap_2022 
from Revenue_Marketcap_2015, Revenue_Marketcap_2022;


--Using Subquerry: 
SELECT 
    (SELECT Revenue FROM NormalizingFactors WHERE FiscalYear = 2015) AS Revenue2015,
    (SELECT Revenue FROM NormalizingFactors WHERE FiscalYear = 2022) AS Revenue2022,
    (SELECT MarketCapitalization FROM NormalizingFactors WHERE FiscalYear = 2015) AS MarketCap2015,
    (SELECT MarketCapitalization FROM NormalizingFactors WHERE FiscalYear = 2022) AS MarketCap2022
	


-- 3 What is the trend of Apple's greenhouse gas emissions over the past 5 yeas?

select fiscalyear, sum(emissions) as "Total Emission Per Year"
from GreenhouseGasEmissions
where fiscalyear between 2015 and 2020
group by fiscalyear
order by sum(emissions) desc;




-- 4.  Comparing Emission between two categories between year 2015 and 2022.

with Corporate_Emission as 
( 
	select distinct
    	(select sum(emissions) from GreenhouseGasEmissions where fiscalyear = '2015' and category = 'Corporate emissions' group by category ) as emission_2015_Corporate,
		(select sum(emissions)  from GreenhouseGasEmissions where fiscalyear = '2022' and category = 'Product life cycle emissions' group by category)as emission_2022_Corporate
	from GreenhouseGasEmissions
	
),

 PLC_emission as 
(

	select distinct
    	(select sum(emissions) from GreenhouseGasEmissions where fiscalyear = '2015' and category = 'Product life cycle emissions' group by category ) as PLCE_2015,
		(select sum(emissions)  from GreenhouseGasEmissions where fiscalyear = '2022' and category = 'Product life cycle emissions' group by category) as PLCE_2022
	from GreenhouseGasEmissions
)

	
select emission_2015_Corporate, emission_2022_Corporate , (emission_2015_Corporate - emission_2022_Corporate) as Emission_Diff_Corporate, PLCE_2015, PLCE_2022, (PLCE_2022 - PLCE_2015) as Emission_Diff_PLCE
from Corporate_Emission, PLC_emission;

select * from GreenhouseGasEmissions

-- Average Annual reduction in emission from year 2015 to 2022.

WITH EmissionsData AS (
    SELECT 
        FiscalYear,
        SUM(Emissions) AS TotalEmissions
    FROM GreenhouseGasEmissions
    GROUP BY FiscalYear
    ORDER BY FiscalYear
),
FirstYearData AS (
    SELECT TotalEmissions AS InitialEmissions
    FROM EmissionsData
    WHERE FiscalYear = (SELECT MIN(FiscalYear) FROM EmissionsData)
),
LastYearData AS (
    SELECT TotalEmissions AS FinalEmissions
    FROM EmissionsData
    WHERE FiscalYear = (SELECT MAX(FiscalYear) FROM EmissionsData)
)
 SELECT 
        ((FinalEmissions - InitialEmissions) /  TotalEmissions) AS AvgAnnualReduction
    FROM FirstYearData, LastYearData,EmissionsData
   

-- what percentage of apple's total emisions come from scope1, scope2 and scope3 sources.
		
WITH total_emissions AS (
  SELECT SUM(Emissions) AS total
  FROM GreenhouseGasEmissions
  WHERE Type = 'Gross emissions'
),
scope_emissions AS (
  SELECT
    SUM(CASE WHEN Scope = 'Scope 1' THEN Emissions ELSE 0 END) AS scope1,
    SUM(CASE WHEN Scope = 'Scope 2 (market-based)' THEN Emissions ELSE 0 END) AS scope2,
    SUM(CASE WHEN Scope = 'Scope 3' THEN Emissions ELSE 0 END) AS scope3
  FROM  GreenhouseGasEmissions
  WHERE Type = 'Gross emissions'
)
SELECT
  CAST(100.0 * scope1 / total AS NUMERIC(5,2)) AS scope1_percentage,
  CAST(100.0 * scope2 / total AS NUMERIC(5,2)) AS scope2_percentage,
  CAST(100.0 * scope3 / total AS NUMERIC(5,2)) AS scope3_percentage
FROM scope_emissions, total_emissions;


--2. How does the trend of Apple's emissions compare to the industry average?


--5. Which fiscal year had the highest revenue for Apple?
select fiscalyear, sum(revenue) as "Total Revenue"
from normalizingfactors
group by fiscalyear
order by sum(revenue)
limit 1;


--6. What is the revenue generated per employee for Apple each year?


select fiscalyear, cast(employees/revenue as Numeric (5,2))as "Revenue Per Employee"
from normalizingfactors



--7. Calculate the year-over-year revenue growth rate for Apple.

with Previous_year_revenue as 
(
select fiscalyear, revenue, lag(revenue) over(order by fiscalyear) as Previous_Year_Revenue
from normalizingfactors
)

select fiscalyear , cast(((revenue - Previous_Year_Revenue)/ Previous_Year_Revenue)*100 as numeric (5,2)) as Growth_Rate_percentage
from Previous_year_revenue
order by  1

--8. Identify the top 3 products with the highest carbon footprint in the latest year.

select product, sum(carbonfootprint) as total_carboon_footprint
from carbonfootprintbyproduct
group by 1
order by 2 desc
limit 3;

--10. Which fiscal years had maximum emissions reductions compared to the previous year?

with Previous_year_emission as 
(
select fiscalyear, sum(emissions) as current_year_emissions, lag(sum(emissions)) over(order by fiscalyear) as Previous_Year_emissions
from greenhousegasemissions
group by 1
)
select fiscalyear, previous_year_emissions - current_year_emissions as yearly_Emission_reduction
from previous_year_emission
order by 2 desc


--11. What is the average carbon footprint per product category?

select product, avg(carbonfootprint) as average_carbon_footprint
from carbonfootprintbyproduct
group by product

--12. Calculate the year-over-year change in market capitalization for Apple.

with Previous_year_marketcapitalization as 
(
select fiscalyear, sum(marketcapitalization) as current_year_marketcapitalization, lag(sum(marketcapitalization)) over(order by fiscalyear) as Previous_Year_marketcapitalization
from normalizingfactors
group by 1
)
select fiscalyear,  current_year_marketcapitalization-previous_year_marketcapitalization  as marketcapitalization_growth_rate
from previous_year_marketcapitalization
order by 2 desc

-- Calculate the moving average of emissions over a 3-year period.

WITH emissions_data AS (
  SELECT
    FiscalYear,
    SUM(emissions) AS emissions
  FROM
    greenhousegasemissions
  GROUP BY
    Fiscalyear
  ORDER BY
    FiscalYear
),
emissions_with_lag AS (
  SELECT
    FiscalYear,
    emissions,
    LAG(emissions, 1) OVER (ORDER BY FiscalYear) AS prev_year_emissions,
    LAG(emissions, 2) OVER (ORDER BY FiscalYear) AS two_years_ago_emissions
  FROM
    emissions_data
)
SELECT
  FiscalYear,
  emissions,
  cast(AVG(emissions) OVER (ORDER BY FiscalYear ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as numeric (10,2)) AS moving_avg_3_years
FROM
  emissions_with_lag
WHERE
   FiscalYear >= (SELECT
    MIN(FiscalYear) + 2
  FROM
    emissions_data);


--18. Calculate the compound annual growth rate (CAGR) of revenue for Apple.

WITH RevenueData AS (
    SELECT FiscalYear, Revenue,
           LAG(Revenue) OVER (ORDER BY FiscalYear) AS PrevYearRevenue
    FROM NormalizingFactors
)
SELECT fiscalyear, Cast((POWER(Revenue / PrevYearRevenue, 1.0 / (FiscalYear - LAG(FiscalYear) OVER (ORDER BY FiscalYear))) - 1) as Numeric (5,2)) * 100 AS CAGR
FROM RevenueData
ORDER BY FiscalYear;



