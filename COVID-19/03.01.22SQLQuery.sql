--Covid data from https://ourworldindata.org/covid-deaths with data from 24/02/2020 to 17/12/2021

--Glimpse of Data on Covid cases and deaths 
SELECT *
FROM [Portfolio project]..Covid_deaths
ORDER BY 3,4


--For Covid data in all countries

--Summary statistics
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as total_deaths, SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 AS DeathPercentage
FROM [Portfolio project]..Covid_deaths
WHERE continent IS NOT NULL 
ORDER BY 1,2

--Looking at countries with highest infections rates compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX(total_cases/population)*100 AS infected_population_percentage
FROM [Portfolio project]..Covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infected_population_percentage DESC

--Showing countries with highest number of deaths
SELECT location, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM [Portfolio project]..Covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC	

--For highest number of deaths by continent
SELECT continent, MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM [Portfolio project]..Covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC	

--Global numbers for cases, deaths and mortality rates 
SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS mortality_rate
FROM [Portfolio project]..Covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2



--Singapore
--Likelihood of dying from Covid in Singapore over time
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS mortality_rate
FROM [Portfolio project]..Covid_deaths
WHERE location = 'Singapore'

--Likelihood of dying from Covid for the different countries over time
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS mortality_rate
FROM [Portfolio project]..Covid_deaths
ORDER BY mortality_rate DESC

--What percentage of population has got Covid in Singapore
SELECT location, date, total_cases, population, (total_cases/population)*100 AS sg_infected_population_percentage
FROM [Portfolio project]..Covid_deaths
WHERE location = 'Singapore'
ORDER BY 1, 2



--For vaccination data, we will JOIN the previous table with the vaccination table
-- For total population's vaccination rates
SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cummulative_vaccinations
FROM [Portfolio project]..Covid_deaths AS dea
JOIN [Portfolio project]..Covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 ORDER BY 2, 3

--Vaccination rates over time for the world
--Method 1 Use CTE
 WITH pop_vs_vac(continent, location, date, population, new_vaccinations, cummulative_vaccinations)
 AS(
 SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cummulative_vaccinations
FROM [Portfolio project]..Covid_deaths AS dea
JOIN [Portfolio project]..Covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 --ORDER BY 2, 3
 )	
 SELECT *, (cummulative_vaccinations/population)*100 AS cummulative_vac_rate
 FROM pop_vs_vac

 --Method 2 Temporary table
 CREATE TABLE #percent_population_vac
 (
 continent nvarchar(255),
 location nvarchar(255),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 cummulative_vac numeric
 )

 
 INSERT INTO #percent_population_vac
 SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cummulative_vac
FROM [Portfolio project]..Covid_deaths AS dea
JOIN [Portfolio project]..Covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL
 --ORDER BY 2, 3

 SELECT *, (cummulative_vac/population)*100 AS cummulative_vac_rate
 FROM #percent_population_vac

--For Singapore's vaccination data
SELECT *, (cummulative_vac/population)*100 AS cummulative_vac_rate
 FROM #percent_population_vac
 WHERE location = 'Singapore'


--Create View to store data for later visualization, as a permanent table
 CREATE VIEW view_percent_population_vac AS 
  SELECT dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations, 
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cummulative_vac
FROM [Portfolio project]..Covid_deaths AS dea
JOIN [Portfolio project]..Covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
 WHERE dea.continent IS NOT NULL

 SELECT *
 FROM view_percent_population_vac