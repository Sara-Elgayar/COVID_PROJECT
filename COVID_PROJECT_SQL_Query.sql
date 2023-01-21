SELECT * 
FROM [CovidProj].[dbo].[CovidVaccinations];

SELECT *
FROM CovidDeaths
ORDER BY 3, 4;

SELECT location
  ,date
  ,total_cases
  ,new_cases
  ,total_deaths
  ,population
FROM CovidDeaths
ORDER BY 1, 2;

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

-- Looking at Total Cases vs Population
-- Shows what percentange of population got Covid

SELECT location
     ,date
     ,population
     ,total_cases
     ,(total_cases/population)*100 as CasesPercentage
FROM CovidDeaths
--where location like '%states%'
ORDER BY 1, 2;

-- Looking at Countries with Highest Infiection Rate compared to Population
SELECT location
      ,population
      ,max(total_cases) as HighestInfectionCount
      ,max((total_cases/population))*100 as PercentagePopulationInfected
FROM CovidDeaths
GROUP BY [location], population
ORDER BY PercentagePopulationInfected desc;

--Showing Countries with Highest Death Count per Population

SELECT location
      ,max(cast(total_deaths as int)) as TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location]
ORDER BY TotalDeathCount DESC

-- LET's BREAK THINGS DOWN BY CONTINENT 
SELECT continent
       ,max(cast(total_deaths as int)) as TotalDeathCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [continent]
ORDER BY TotalDeathCount DESC

-- Global numbers
SELECT SUM(new_cases) AS total_cases
      ,SUM(cast(new_deaths as int)) as total_deaths
      ,SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2



-- Total Population vs Vaccinations

SELECT dea.continent
      ,dea.LOCATION
      ,dea.DATE
      ,dea.population
      ,vac.new_vaccinations,
 SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.DATE) as RollingPeopleVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as dea
JOIN [CovidProj].[dbo].[CovidVaccinations]  as vac
    on dea.[location] = vac.location
    and dea.[date] = vac.date
WHERE dea.continent is not NULL
ORDER by 2,3 


-- CTE (common table expression )

WITH PopvsVac (continent
               ,location
               ,DATE
               ,population
               ,New_vaccination
               ,RollingPeopleVaccinated)
AS
(
SELECT dea.continent
       ,dea.LOCATION
       ,dea.DATE
       ,dea.population
       ,vac.new_vaccinations
       ,SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.DATE) as RollingPeopleVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as dea
JOIN [CovidProj].[dbo].[CovidVaccinations]  as vac
    on dea.[location] = vac.location
    and dea.[date] = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *
      ,(RollingPeopleVaccinated/population)* 100 as RollingPeoplePercentage
FROM PopvsVac 



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
SELECT dea.continent
       ,dea.LOCATION
       ,dea.DATE
       ,dea.population
       ,vac.new_vaccinations
       ,SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.DATE) as RollingPeopleVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as dea
JOIN [CovidProj].[dbo].[CovidVaccinations]  as vac
    on dea.[location] = vac.location
    and dea.[date] = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
      ,(RollingPeopleVaccinated/population)* 100 as RollingPeoplePercentage
FROM #PercentPopulationVaccinated


-- Creating view to store data for later visualizations

GO
CREATE VIEW PercentPopulationVaccinated 
AS
SELECT 
    dea.continent, 
    dea.LOCATION, 
    dea.DATE, 
    dea.population, 
    vac.new_vaccinations,
    SUM(convert(int,vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.DATE) as RollingPeopleVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as dea
JOIN [CovidProj].[dbo].[CovidVaccinations]  as vac
    on dea.[location] = vac.location
    and dea.[date] = vac.date
WHERE dea.continent is not NULL
GO

SELECT * 
FROM PercentPopulationVaccinated