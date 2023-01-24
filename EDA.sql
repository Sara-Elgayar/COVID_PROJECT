-- 1

SELECT * 
FROM [CovidProj].[dbo].[CovidVaccinations];

-- 2

SELECT *
FROM CovidDeaths
ORDER BY 3, 4;

-- 3

SELECT location
  ,date
  ,total_cases
  ,new_cases
  ,total_deaths
  ,population
FROM CovidDeaths
ORDER BY 1, 2;


-- 4

--Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in your country

SELECT location
      ,date 
      ,total_cases
      ,total_deaths
      ,(total_deaths /total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;


-- 5

-- Looking at Total Cases vs Population
-- Shows what percentange of population got Covid

SELECT location
     ,date
     ,population
     ,total_cases
     ,(total_cases/population)*100 as CasesPercentage
FROM CovidDeaths
ORDER BY 1, 2;


-- 6

-- Looking at Countries with Highest Infiection Rate compared to Population
SELECT location
      ,population
      ,max(total_cases) as HighestInfectionCount
      ,max((total_cases/population))*100 as PercentagePopulationInfected
FROM CovidDeaths
GROUP BY [location], population
ORDER BY PercentagePopulationInfected desc;

-- 7
--Showing Countries with Highest Death Count per Population

SELECT location
      ,max(cast(total_deaths as int)) as TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location]
ORDER BY TotalDeathCount DESC

-- 8
-- GROUP BY CONTINENT 
SELECT continent
       ,max(cast(total_deaths as int)) as TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [continent]
ORDER BY TotalDeathCount DESC

-- 9
-- Global numbers
SELECT SUM(new_cases) AS total_cases
      ,SUM(cast(new_deaths as int)) as total_deaths
      ,SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- 10
-- Total Population vs Vaccinations

SELECT ds.continent
      ,ds.LOCATION
      ,ds.DATE
      ,ds.population
      ,vs.new_vaccinations,
 SUM(convert(int,vs.new_vaccinations)) OVER (partition by ds.location order by ds.location, ds.DATE) as RollingPeopleVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as ds
JOIN [CovidProj].[dbo].[CovidVaccinations]  as vs
    on ds.[location] = vs.location
    and ds.[date] = vs.date
WHERE ds.continent is not NULL
ORDER by 2,3 


-- 11
-- CTE (common table expression )

WITH PopvsVac (continent
               ,location
               ,DATE
               ,population
               ,New_vaccination
               ,RollingPeopleVaccinated)
AS
(
SELECT ds.continent
       ,ds.LOCATION
       ,ds.DATE
       ,ds.population
       ,vs.new_vaccinations
       ,SUM(convert(int,vs.new_vaccinations)) OVER (partition by ds.location order by ds.location, ds.DATE) as RollingPeopleVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as ds
JOIN [CovidProj].[dbo].[CovidVaccinations]  as vs
    on ds.[location] = vs.location
    and ds.[date] = vs.date
WHERE ds.continent IS NOT NULL
)
SELECT *
      ,(RollingPeopleVaccinated/population)* 100 as RollingPeoplePercentage
FROM PopvsVac 


-- 12
-- Temp Table
DROP TABLE if EXISTS #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
    Continent NVARCHAR(225),
    Location NVARCHAR(225),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)
INSERT into #PercentPopulationVaccinated
SELECT ds.continent
       ,ds.LOCATION
       ,ds.DATE
       ,ds.population
       ,vs.new_vaccinations
       ,SUM(convert(int,vs.new_vaccinations)) OVER (partition by ds.location order by ds.location, ds.DATE) as RollingPeopleVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as ds
JOIN [CovidProj].[dbo].[CovidVaccinations]  as vs
    on ds.[location] = vs.location
    and ds.[date] = vs.date
WHERE ds.continent IS NOT NULL

SELECT *
      ,(RollingPeopleVaccinated/population)* 100 as RollingPeoplePercentage
FROM #PercentPopulationVaccinated


-- 13
-- Creating view to store data for later visualizations

GO
CREATE VIEW PercentPopulationVaccinated 
AS
SELECT 
    ds.continent, 
    ds.LOCATION, 
    ds.DATE, 
    ds.population, 
    vs.new_vaccinations,
    SUM(convert(int,vs.new_vaccinations)) OVER (partition by ds.location order by ds.location, ds.DATE) as RollingPeopleVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as ds
JOIN [CovidProj].[dbo].[CovidVaccinations]  as vs
    on ds.[location] = vs.location
    and ds.[date] = vs.date
WHERE ds.continent is not NULL
GO

-- 14 
-- Test view 

SELECT * 
FROM PercentPopulationVaccinated
