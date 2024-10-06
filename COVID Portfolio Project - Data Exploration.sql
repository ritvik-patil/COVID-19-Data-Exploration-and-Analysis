
/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

USE PortfolioProject;

SELECT * FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location,date;

--SELECT * FROM CovidVaccinations
--ORDER BY location,date;

-- Select the data the we are going to be using

SELECT location,date,total_cases,new_cases,total_deaths,population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location,date;

-- Total Cases vs Total Deaths
-- Shows the likelihood of Dying if you contract Covid in your Country

SELECT location,date,total_cases,total_deaths, 
(total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE 'I_d_a'
AND continent IS NOT NULL
ORDER BY location,date;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location,date,total_cases,population, 
(total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location,date;


-- Countries with Highest Infection Rate compared to Population

SELECT location,population,MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY PercentPopulationInfected DESC;


-- Countries with Highest Death Count 

SELECT location,MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location,population
ORDER BY TotalDeathCount DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing the Continents with Highest Death Count 

SELECT continent,MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC; 

-- This query gives more accurate results than above

SELECT location,MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC; 

-- Continents with highest Percent Death Count per Population

SELECT location,MAX(CAST(total_deaths AS INT)/population)*100 AS PercentDeathsPerPopulation
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY PercentDeathsPerPopulation DESC; 

-- GLOBAL NUMBERS

-- By date
SELECT date,SUM(new_cases) AS TotalCases,
	SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Total numbers
SELECT SUM(new_cases) AS TotalCases,
	SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
	SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL;
--GROUP BY date
--ORDER BY 1,2;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT d.continent,d.location,d.date,d.population,
	v.new_vaccinations,
	SUM(CONVERT(INT,v.new_vaccinations)) 
	OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths d
JOIN CovidVaccinations v
	ON d.location = v.location
	AND d.date=v.date
WHERE d.continent IS NOT NULL AND v.new_vaccinations IS NOT NULL
ORDER BY 2,3;


-- Using CTE(Common Table Expressions) to perform Calculation on Partition By in previous query

WITH PopVsVac(Continent, Location, Date, Population,New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT d.continent,d.location,d.date,d.population,
	v.new_vaccinations,
	SUM(CONVERT(INT,v.new_vaccinations)) 
	OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths d
JOIN CovidVaccinations v
	ON d.location = v.location
	AND d.date=v.date
WHERE d.continent IS NOT NULL
-- ORDER BY 2,3
)

SELECT *,(RollingPeopleVaccinated/Population)*100 AS PercPopVaccinated
FROM PopVsVac
WHERE New_Vaccinations IS NOT NULL;



-- Maximum Vaccination Rate
WITH PopVsVac AS
(
SELECT d.continent, d.location, d.population,
    SUM(CONVERT(BIGINT, v.new_vaccinations)) OVER (PARTITION BY d.location) AS RollingPeopleVaccinated
FROM CovidDeaths d
JOIN CovidVaccinations v 
ON d.location = v.location 
AND d.date = v.date
WHERE d.continent IS NOT NULL
)

SELECT Location,Population,
    MAX(ISNULL(RollingPeopleVaccinated, 0)) / Population * 100 AS MaxVaccinationRate
FROM PopVsVac
GROUP BY Location, Population
ORDER BY MaxVaccinationRate DESC;

-- TEMP TABLE--Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT d.continent,d.location,d.date,d.population,
	v.new_vaccinations,
	SUM(CONVERT(INT,v.new_vaccinations)) 
	OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths d
JOIN CovidVaccinations v
	ON d.location = v.location
	AND d.date=v.date
-- WHERE d.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *,(RollingPeopleVaccinated/Population)*100 AS PercPopVaccinated
FROM #PercentPopulationVaccinated
WHERE continent IS NOT NULL AND New_Vaccinations IS NOT NULL;


-- Creating View to store data for later Visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent,d.location,d.date,d.population,
	v.new_vaccinations,
	SUM(CONVERT(INT,v.new_vaccinations)) 
	OVER (PARTITION BY d.location ORDER BY d.location,d.date) AS RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM CovidDeaths d
JOIN CovidVaccinations v
	ON d.location = v.location
	AND d.date=v.date
WHERE d.continent IS NOT NULL;
-- ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated
WHERE New_Vaccinations IS NOT NULL;