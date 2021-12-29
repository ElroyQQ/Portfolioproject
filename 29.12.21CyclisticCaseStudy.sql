/*After querying the 12 tables we imported, we observe that there are many NULL values for the start and end station names. 
Considering these NULLs with no reference table to update them, and the geographical longtitude and latitude data not being useful without them, 
We will exclude the geographical data from our analysis. This case study is using Divvy data as a proxy for the fictional company Cyclistic as well,
we will assume any geographical analysis would not be relevant to it.*/

--We will create a table to combine all the 12 months of Cyclistic data
DROP TABLE IF EXISTS Cyclistic12monthsData	
CREATE TABLE Cyclistic12monthsData 
(
ride_id nvarchar(255),
rideable_type nvarchar(255),
started_at datetime,
ended_at datetime,
member_casual nvarchar(255)
)
--We will use INSERT INTO and UNION ALL to insert the columns we wish to use for our analysis
INSERT INTO Cyclistic12monthsData
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202012-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202101-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202102-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202103-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202104-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202105-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202106-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202107-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202108-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202109-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202110-divvy-tripdata$']
UNION ALL
SELECT ride_id, rideable_type, started_at, ended_at, member_casual
FROM dbo.['202111-divvy-tripdata$']

--Data cleaning
--We will check for any NULLS
SELECT *
FROM Cyclistic12monthsData
WHERE ride_id IS NULL

SELECT *
FROM Cyclistic12monthsData
WHERE rideable_type IS NULL

SELECT *
FROM Cyclistic12monthsData
WHERE started_at IS NULL

SELECT *
FROM Cyclistic12monthsData
WHERE ended_at IS NULL

SELECT *
FROM Cyclistic12monthsData
WHERE member_casual IS NULL
-- We have confirmed there are no NULL values
--To check for duplicates
SELECT ride_id, rideable_type,started_at, ended_at, member_casual, COUNT(*) AS num_of_duplicates
FROM Cyclistic12monthsData
GROUP BY ride_id, rideable_type,started_at, ended_at, member_casual
HAVING COUNT(*)>1

--To remove the duplicate rows, we will use a CTE and PARTITION BY. As ride_id should be unique for each trip, we will use it as a reference point.
WITH RowNumCTE AS 
(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY ride_id, rideable_type,started_at, ended_at, member_casual
ORDER BY ride_id) AS row_num
FROM Cyclistic12monthsData
)
DELETE FROM RowNumCTE WHERE row_num <>1

--Checking for duplicates again
SELECT ride_id, rideable_type,started_at, ended_at, member_casual, COUNT(*) AS num_of_duplicates
FROM Cyclistic12monthsData
GROUP BY ride_id, rideable_type,started_at, ended_at, member_casual
HAVING COUNT(*)>1

--Adding new useful columns
--We wil add a column for trip_duration for analysis as start and end times are not as easy to use
ALTER TABLE Cyclistic12monthsData
ADD ride_duration numeric

UPDATE Cyclistic12monthsData
SET ride_duration = DATEDIFF(second, started_at, ended_at)

/*Checking for trips less or equal to 0 seconds, we will remove them as such short duration trips are unlikely to be actual trips 
and are probably errorS/mistakes or testing rides by the company */
SELECT ride_id, trip_duration
FROM Cyclistic12monthsData
WHERE ride_duration <=0

DELETE FROM Cyclistic12monthsData
WHERE ride_duration <=0

--Checking 
SELECT ride_id, ride_duration
FROM Cyclistic12monthsData
WHERE ride_duration <=0

--Adding new column for day of the week, we will use the started_at column as that is the day where each trip started
ALTER TABLE Cyclistic12monthsData
ADD weekday nvarchar(255)

UPDATE Cyclistic12monthsData
SET weekday = DATENAME(WEEKDAY, started_at)

--Checking
SELECT ride_id, weekday
FROM Cyclistic12monthsData

--Adding a datetime column for each ride_id, there might be different start and end dates for some trips. We will use the started_at column as a reference point
ALTER TABLE Cyclistic12monthsData
ADD ride_date date

UPDATE Cyclistic12monthsData
SET ride_date = CONVERT(date, started_at)

--Checking
Select *
FROM Cyclistic12monthsData

/*Now that our data is cleaned and ready to be analysed, we will import the data into Tableau Public for analysis and visualisation
Tableau Public is a free software that can create interactive data visualizations to share freely, which is suitable for this project.
Since Tableau Public does not allow for direct connection to MS SQL Server, we will export our data to a CSV file via SQL Server Import and Export Wizard.*/