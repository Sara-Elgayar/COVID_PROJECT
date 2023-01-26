
-- 1. 
-- Find the death percentage locally, location = 'egypt'

SELECT location
      ,date 
      ,total_cases
      ,total_deaths
      ,(total_deaths /total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE location like '%egypt%'
ORDER BY 1, 2;



-- 2. 
-- Find Total Cases, Total Deaths, Percentage Infected, Percentage Death 
-- For each Location, Order by TOTAL_CASES

SELECT location AS LOCATION
     ,SUM(convert(bigint, total_cases)) AS TOTAL_CASES
     ,SUM(convert(bigint,total_deaths)) AS TOTAL_DEATHS
     ,population AS POPULATION
     ,SUM(convert(bigint,total_cases))/ SUM(population) * 100 AS PERCENT_INFECTED
     ,SUM(convert(bigint,total_deaths))/ SUM(population) * 100 AS PERCENT_DEATHS
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [location], [population]
ORDER BY TOTAL_CASES DESC;


-- 3.
-- Find Countries with Highest ICU Patients and hospitalized Patients compared to Population

SELECT location
      ,population
      ,max(icu_patients) as HighestIcuPatientsCount
      ,max((icu_patients/population))*100 as PercentageIcuPatients
      ,max(hosp_patients) as HighestHospPatientsCount
      ,max((hosp_patients/population))*100 as PercentageHospPatients
FROM CovidDeaths
GROUP BY [location], population
ORDER BY PercentageIcuPatients desc;


-- 4.
-- Global information about total cases, total Vaccinations, total tests, total hospitalized patients,
-- total Icu Patients and World Vaccination Percentage

SELECT SUM(cast(total_cases as bigint)) as Total_Cases
      ,SUM(cast(hosp_patients as bigint)) as TotalHospitalizedPatients
      ,SUM(cast(icu_patients as bigint)) as TotalIcuPatients
      ,SUM(cast(total_tests as bigint)) as TotalTestsCount
      ,SUM(cast(total_vaccinations as bigint)) as TotalVaccinationsCount
      ,SUM(cast(total_vaccinations as bigint)) / sum(population) * 100 AS WorldVaccinationPercentage
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL


-- 5.
-- Total Hospitalized Patients, Icu Patients and Total Deaths for each CONTINENT 
-- Ordered by Total Cases

SELECT continent
      ,SUM(cast(total_cases as bigint)) as Total_Cases
      ,SUM(cast(total_tests as bigint)) as TotalTestsCount
      ,SUM(cast(total_vaccinations as bigint)) as TotalVaccinationsCount
      ,SUM(cast(total_deaths as bigint)) as TotalDeathsCount
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY [Total_Cases] DESC


-- 6.
-- Daily People Vaccinated, where table CovidDeaths and CovidVaccinations are Joined to get the result
-- Ordered by Location and Date
SELECT D.continent
      ,D.LOCATION
      ,D.DATE
      ,D.population
      ,V.new_vaccinations
      ,SUM(convert(int,V.new_vaccinations)) OVER (partition by D.location order by D.location, D.DATE) as RollingPeopleVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as D
JOIN [CovidProj].[dbo].[CovidVaccinations]  as V
    on D.[location] = V.location
    and D.[date] = V.date
WHERE D.continent is not NULL
ORDER by 2,3 


-- 7.
-- Find daily new hospitalized patients and cumilative hospitalized patients 
-- new icu patients and cumilative Icu patients 
-- daily new deaths, cumiliative deaths
-- people fully vaccinated , cumiliative people fully vaccinated 
-- where location = United States


WITH PopvsVac (continent
               ,location
               ,DATE
               ,population
               ,hosp_patients
               ,RollingHospitalizedPatients
               ,icu_patients
               ,RollingIcuPatients
               ,new_deaths
               ,RollingDeaths
               ,people_fully_vaccinated
               ,RollingPeopleFullyVaccinated)
AS
(
SELECT D.continent
       ,D.LOCATION
       ,D.DATE
       ,D.population
       ,D.hosp_patients
       ,SUM(convert(bigint, D.hosp_patients)) OVER (partition by D.location order by D.location, D.DATE) as RollingHospitalizedPatients
       ,D.icu_patients
       ,SUM(convert(bigint, D.icu_patients)) OVER (partition by D.location order by D.location, D.DATE) as RollingIcuPatients
       ,D.new_deaths
       ,SUM(convert(bigint, D.new_deaths)) OVER (partition by D.location order by D.location, D.DATE) as RollingDeaths
       ,V.people_fully_vaccinated
       ,SUM(convert(bigint,V.people_fully_vaccinated)) OVER (partition by D.location order by D.location, D.DATE) as RollingPeopleFullyVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as D
JOIN [CovidProj].[dbo].[CovidVaccinations]  as V
    on D.[location] = V.location
    and D.[date] = V.date
WHERE D.continent IS NOT NULL
)
SELECT Date
       ,location
       --,hosp_patients
       ,RollingHospitalizedPatients
       --,icu_patients
       ,RollingIcuPatients
       --,new_deaths
       ,RollingDeaths
       --,people_fully_vaccinated
       ,RollingPeopleFullyVaccinated
       ,(RollingIcuPatients/population)* 100 as RollingIcuPatientsPercentage
FROM PopvsVac 
Where [location] like '%states%'


-- 8.
-- Create Temp Table for Fully Vaccinated Percent and Daily People Fully Vaccinated

DROP TABLE if EXISTS #FullyVaccinatedPercent
CREATE Table #FullyVaccinatedPercent
(
    Continent NVARCHAR(225),
    Location NVARCHAR(225),
    Date DATETIME,
    Population NUMERIC,
    PeopleFullyVaccinated NUMERIC,
    RollingPeopleFullyVaccinated NUMERIC,
)
INSERT into #FullyVaccinatedPercent
SELECT  D.continent
       ,D.LOCATION
       ,D.DATE
       ,D.population
       ,V.people_fully_vaccinated
       ,SUM(convert(bigint,V.people_fully_vaccinated)) OVER (partition by D.location order by D.location, D.DATE) as RollingPeopleFullyVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as D
JOIN [CovidProj].[dbo].[CovidVaccinations]  as V
    on D.[location] = V.location
    and    D.[date] = V.date
WHERE D.continent IS NOT NULL

SELECT *
      ,(RollingPeopleFullyVaccinated/Population)*100 as RollingPeopleFullyVaccinatedPercentage
FROM #FullyVaccinatedPercent

-- 9.
-- Creating view to store data for later visualizations from Query 7.
DROP VIEW IF EXISTS PercentagePopulationFullyVaccinated
GO
CREATE View PercentagePopulationFullyVaccinated
AS
SELECT D.continent
       ,D.LOCATION
       ,D.DATE
       ,D.population
       ,D.hosp_patients
       ,SUM(convert(bigint, D.hosp_patients)) OVER (partition by D.location order by D.location, D.DATE) as RollingHospitalizedPatients
       ,D.icu_patients
       ,SUM(convert(bigint, D.icu_patients)) OVER (partition by D.location order by D.location, D.DATE) as RollingIcuPatients
       ,D.new_deaths
       ,SUM(convert(bigint, D.new_deaths)) OVER (partition by D.location order by D.location, D.DATE) as RollingDeaths
       ,V.people_fully_vaccinated
       ,SUM(convert(bigint,V.people_fully_vaccinated)) OVER (partition by D.location order by D.location, D.DATE) as RollingPeopleFullyVaccinated
FROM [CovidProj].[dbo].[CovidDeaths] as D
JOIN [CovidProj].[dbo].[CovidVaccinations]  as V
    on D.[location] = V.location
    and D.[date] = V.date
WHERE D.continent IS NOT NULL
GO

SELECT * 
FROM PercentagePopulationFullyVaccinated

-- End of File