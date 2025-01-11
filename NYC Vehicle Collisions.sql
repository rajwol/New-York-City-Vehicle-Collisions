--Filtering the Data (2018 - 2024) into Temp Table
SELECT *
INTO #temp_nyc_collisions
FROM nyc_vehicle_crashes
WHERE crash_date BETWEEN '2018-01-01' AND '2024-12-31'

-- Summary Dashboard Key Indicators
SELECT 
	COUNT(*) AS collisions,
	SUM(number_of_persons_killed) AS fatalities,
	SUM(number_of_persons_injured) AS injuries,
	COUNT(DISTINCT contributing_factor_vehicle_1) AS 'Unique Cases'
FROM #temp_nyc_collisions

--Total Collisions by Year
SELECT 
	DATEPART(YEAR,crash_date) AS YearOfCrash,
	count(collision_id) AS collisions
FROM #temp_nyc_collisions
GROUP BY  DATEPART(YEAR,crash_date)
ORDER BY YearOfCrash

--Top Contributing Factors by Collisions
SELECT TOP 5
	contributing_factor_vehicle_1 AS ContributingFactor,
	COUNT(collision_id) AS collisions
FROM #temp_nyc_collisions
WHERE contributing_factor_vehicle_1 != 'Unspecified'
GROUP BY contributing_factor_vehicle_1
ORDER BY collisions DESC

--Top Contributing Factors by Deaths
SELECT TOP 5
	contributing_factor_vehicle_1 AS ContributingFactor,
	SUM(number_of_persons_killed) AS fatalities
FROM #temp_nyc_collisions
WHERE contributing_factor_vehicle_1 != 'Unspecified'
GROUP BY contributing_factor_vehicle_1
ORDER BY fatalities DESC

-- Collisions by Time Of Day
SELECT
	DATEPART(HOUR, crash_time) AS TimeOfDay,
	COUNT(collision_id) AS collisions
FROM #temp_nyc_collisions
GROUP BY datepart(hour, crash_time)
ORDER BY TimeOfDay

--Collisions by Day of Week
SELECT
	DATENAME(WEEKDAY, crash_date) AS DayName,
	COUNT(collision_id) AS Collisions
FROM #temp_nyc_collisions
GROUP BY DATENAME(WEEKDAY, crash_date), DATEPART(WEEKDAY, crash_date)
ORDER BY DATEPART(WEEKDAY, crash_date)

--Causes & Collisions Key Indicators
SELECT
	COUNT(collision_id) / 365,
	(SUM(number_of_persons_killed) * 10000.0) / COUNT(collision_id) AS DeathsPer10K,
	(SUM(number_of_persons_injured) * 10000.0) / COUNT(collision_id) AS InjuriesPer10K
FROM #temp_nyc_collisions

--Collisions & deaths by Borough
SELECT
	borough,
	COUNT(collision_id) as collisions,
	SUM(number_of_persons_killed) AS fatalities
FROM #temp_nyc_collisions
GROUP BY borough

-- Top Zip Codes with Most Collisions
WITH ranked_zipcodes_cte AS (
	SELECT 
        borough, zip_code,
        COUNT(collision_id) AS collisions,
        SUM(number_of_persons_injured) AS injuries,
        SUM(number_of_persons_killed) AS fatalities,
        DENSE_RANK() OVER (PARTITION BY borough ORDER BY COUNT(collision_id) DESC) AS collisions_rank
    FROM #temp_nyc_collisions
    GROUP BY borough, zip_code
)
SELECT *
FROM ranked_zipcodes_cte
WHERE collisions_rank <= 7
ORDER BY borough, collisions_rank;

-- Road User Death Percentages
SELECT 
    borough,
    (SUM(number_of_pedestrians_killed) * 100.0) / NULLIF(SUM(number_of_persons_killed), 0) AS pedestrian_fatality_percentage,
    (SUM(number_of_motorist_killed) * 100.0) / NULLIF(SUM(number_of_persons_killed), 0) AS motorist_fatality_percentage,
    (SUM(number_of_cyclist_killed) * 100.0) / NULLIF(SUM(number_of_persons_killed), 0) AS cyclist_fatality_percentage
FROM #temp_nyc_collisions
GROUP BY borough;
