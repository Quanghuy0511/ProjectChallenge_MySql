UPDATE project_sql.us_household_income
SET `Type` = 'CDP'
WHERE `Type` = 'CPD';
UPDATE project_sql.us_household_income
SET `Type` = 'Borough'
WHERE `Type` = 'Boroughs';
UPDATE project_sql.us_household_income
SET State_Name ='Georgia'
WHERE State_Name ='georia';
UPDATE project_sql.us_household_income
SET State_Name ='Alabama'
WHERE State_Name ='alabama';
SELECT * FROM sql_project.us_household_income;

#Task 1: Summarizing Data by State

SELECT State_Name, State_ab , AVG(ALand), AVG(AWater)
FROM sql_project.us_household_income
GROUP BY State_Name, State_ab
ORDER BY AVG(ALand);

#Task 2: Filtering Cities by Population Range
SELECT City, State_Name, County, ALand
FROM sql_project.us_household_income
WHERE ALand BETWEEN 50000000 AND 100000000
ORDER BY City;

#Task 3: Counting Cities per State

SELECT State_Name, State_ab, COUNT(DISTINCT City)
FROM sql_project.us_household_income
GROUP BY State_Name, State_ab
ORDER BY COUNT(*) DESC;

#Task 4: Identifying Counties with Significant Water Area

SELECT State_Name, County, SUM(AWater) total_water_area
FROM sql_project.us_household_income
GROUP BY State_Name, County
ORDER BY SUM(AWater) DESC
LIMIT 10;

#Task 5: Finding Cities Near Specific Coordinates 	

SELECT State_Name, County, City, Lat, Lon
FROM sql_project.us_household_income
WHERE 
	(Lat BETWEEN 30 AND 35) AND
    (Lon BETWEEN -90 AND -85)
ORDER BY Lat, Lon;

#Task 6: Using Window Functions for Ranking
 
SELECT 
	State_Name, City, ALand, 
    RANK() OVER(PARTITION BY State_Name ORDER BY ALand desc) Rank_Aland
FROM sql_project.us_household_income
GROUP BY State_Name, City, ALand
ORDER BY State_Name, Rank_Aland;

#Task 7: Creating Aggregate Reports

SELECT 
	State_Name, State_ab, 
    SUM(ALand) total_land_area, 
    SUM(AWater) total_water_area,  
    COUNT(DISTINCT City) City_Count
FROM sql_project.us_household_income
GROUP BY State_Name, State_ab
ORDER BY total_land_area DESC;

#Task 8: Subqueries for Detailed Analysis

SELECT State_Name, City, ALand
FROM sql_project.us_household_income
WHERE ALand > (SELECT AVG(ALand) FROM sql_project.us_household_income)
ORDER BY ALand DESC;

#Task 9: Identifying Cities with High Water to Land Ratios

SELECT 
	State_Name, City,
    ALand, AWater, 
    AWater/ALand water_to_land_ratio
FROM sql_project.us_household_income
HAVING water_to_land_ratio > 0.5
ORDER BY water_to_land_ratio DESC;

#Task 11: Creating and Using Temporary Tables

#1 : Creat Temporary Tables top_20_cities
CREATE TEMPORARY TABLE top_20_cities AS
SELECT State_Name, City, ALand, AWater
FROM sql_project.us_household_income
ORDER BY ALand DESC
LIMIT 20;
#2 : Calculate the average water area of these top 20 cities
SELECT AVG(AWater)
FROM top_20_cities;
#3 : Final report
SELECT State_Name, City, ALand, AWater
FROM top_20_cities;

#Task 12: Complex Multi-Level Subqueries

SELECT State_Name, AVG(ALand)
FROM sql_project.us_household_income	
GROUP BY State_Name
HAVING AVG(ALand) > (SELECT AVG(ALand)
					FROM sql_project.us_household_income);

#Task 13: Optimizing Indexes for Query Performance

WITH RECURSIVE CumulativeLandArea AS (
    -- Bước đầu tiên: Chọn thông tin từ bảng dữ liệu
    SELECT
        City,
        State_Name,
        ALand AS Individual_Land_Area,
        ALand AS Cumulative_Land_Area,
        ROW_NUMBER() OVER (PARTITION BY State_Name ORDER BY City) AS rn
    FROM
        sql_project.us_household_income

    UNION ALL

    -- Bước đệ quy: Tính tổng tích lũy diện tích đất
    SELECT
        a.City,
        a.State_Name,
        a.Individual_Land_Area,
        a.Cumulative_Land_Area + b.Individual_Land_Area AS Cumulative_Land_Area,
        a.rn
    FROM
        (
            SELECT
                City,
                State_Name,
                ALand AS Individual_Land_Area,
                ALand AS Cumulative_Land_Area,
                ROW_NUMBER() OVER (PARTITION BY State_Name ORDER BY City) AS rn
            FROM
                sql_project.us_household_income
        ) a
        JOIN CumulativeLandArea b ON a.rn = b.rn + 1 AND a.State_Name = b.State_Name
)

SELECT 
    City,
    State_Name,
    Individual_Land_Area,
    Cumulative_Land_Area
FROM CumulativeLandArea
ORDER BY
    State_Name,
    City;
    
#Task 14: Data Anomalies Detection

WITH t1 AS(
	SELECT 
		State_Name,
        AVG(ALand) Avg_Land_Area,
        STDDEV(ALand) stvdev_land_area
    FROM sql_project.us_household_income
    GROUP BY State_Name),
	t2 AS (
	SELECT 
		h.State_Name,
        h.City,
        h.ALand,
		t1.Avg_Land_Area,
		t1.stvdev_land_area,
        (h.ALand - t1.Avg_Land_Area)/ t1.stvdev_land_area AS Z_score
	FROM sql_project.us_household_income h
    JOIN t1
    ON h.State_Name = t1.State_Name)

SELECT 
	State_Name,
	City,
    ALand,
    Avg_Land_Area,
    Z_score
FROM t2
ORDER BY Z_score DESC;


