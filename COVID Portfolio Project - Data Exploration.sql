----------------------------------------------------
-- Covid Deaths
----------------------------------------------------

-- Finding the data with which wer are going to work

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- Looking at Total Cases vs Total Deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%INDIA%'
ORDER BY 1, 2

-- Looking at Total Cases vs Population

SELECT location, date, total_cases, population, (total_cases/population)*100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at Countries with Highest Infection Rate Compared to Population

SELECT location, population, MAX(total_cases) AS Highest_Infection_Count, MAX(total_cases/population)*100 
as Percent_Infection_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY Percent_Infection_Count DESC

-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

-- LET'S BREAK THINGS DOWN BY CONTINENT

SELECT location, MAX(total_deaths) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_Death_Count DESC

--BREAKING THINGS DOWN BY GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS Total_Cases, SUM(new_deaths) AS Total_Deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS 
Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

----------------------------------------------------
-- Covid Vaccinations
----------------------------------------------------

-- First Join Both the Tables

SELECT *
FROM PortfolioProject..CovidDeaths CD
JOIN PortfolioProject..CovidVaccinations CV
	ON CD.location = CV.location
	AND CD.date = CV.DATE

-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
SUM(CONVERT(int, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths CD
JOIN PortfolioProject..CovidVaccinations CV
	ON CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
ORDER BY 2, 3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopsVsVacc (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS
(
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
SUM(CONVERT(int, CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths CD
JOIN PortfolioProject..CovidVaccinations CV
	ON CD.location = CV.location
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
)
           
SELECT * , (Rolling_People_Vaccinated/Population) * 100
from PopsVsVacc

-- Using Temp Table to perform Calculation on Partition By in previous query

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
SUM(CONVERT(INT,CV.new_vaccinations)) OVER (PARTITION BY CD.Location ORDER BY CD.location, CD.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths CD
JOIN PortfolioProject..CovidVaccinations CV
	ON CD.location = CV.location
	AND CD.date = CV.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations, 
SUM(CONVERT(INT,CV.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths CD
JOIN PortfolioProject..CovidVaccinations CV
	ON CD.location = CV.location
	and CD.date = CV.date
WHERE CD.continent IS NOT NULL