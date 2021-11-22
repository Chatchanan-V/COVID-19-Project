--This Covid-19 dataset was recorded from 28/01/2020 - 19/11/2021 
--The CSV file dataset can be downloaded from https://ourworldindata.org/covid-deaths
--The dataset is divided into two excel files: coviddeath.xlsx and covidvaccination.xlsx, which can be downloaded from the repository


--Below are descriptions of several analytical insights along with their SQL code. 

-- Create two CTEs for further analysis: dea and pop_vac, derived from coviddeath and covidvaccination
WITH
	dea
	AS
	(
		SELECT continent, location, date, population, total_cases, new_cases, total_deaths, new_deaths
		FROM Covid_Death
	),
	pop_vac
	AS
	(
		SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
			SUM(CAST(cv.new_vaccinations as float)) OVER (PARTITION BY cd.location ORDER BY cd.date ASC) as rolling_vaccination
		FROM (SELECT DISTINCT *
			FROM Covid_Death) cd INNER JOIN Covid_Vaccination cv
			ON cd.location = cv.location and cd.date = cv.date
		WHERE cd.continent IS NOT NULL and cv.new_vaccinations IS NOT NULL
	)


-- Current death rate for each country, ordered by death rate in desceding order.
-- Death rate is defined as the percentage of infected people dying) 
SELECT *
FROM (
	SELECT location, MAX(total_cases) as current_total_case, MAX(cast(total_deaths as float)) current_total_death, (MAX(cast(total_deaths as float))/MAX(total_cases))*100 as current_death_rate
	FROM dea
	WHERE continent IS NOT NULL
	GROUP BY location) a
WHERE a.current_death_rate IS NOT NULL
ORDER BY a.current_death_rate DESC;


-- Current infection rate for each country, ordered by infection rate in descending order.
-- Infection rate is defined as the percentage of population having COVID-19 positive test.
SELECT *
FROM (
	SELECT location, MAX(total_cases)/MAX(population)*100 as infection_rate
	FROM dea
	WHERE continent IS NOT NULL
	GROUP BY location) b
WHERE infection_rate IS NOT NULL
ORDER BY infection_rate DESC;


--Total death count by continent (Exclude Antarctica)
SELECT location as continent, MAX(CAST(total_deaths as float)) death_count
FROM dea
WHERE continent IS NULL and location in ('Asia', 'North America','South America', 'Africa', 'Europe', 'Oceania')
GROUP BY location
ORDER BY death_count DESC;


--New cases, deaths, and death percentage over time (daily) across the world 
SELECT date, SUM(new_cases_isnull) daily_new_cases, SUM(CAST(new_deaths_isnull as float)) daily_new_death, CASE WHEN SUM(new_cases_isnull) = 0 THEN 0 ELSE
																												SUM(CAST(new_deaths_isnull as float))/SUM(new_cases_isnull)*100
																												END as DeathPercentage
FROM (SELECT *, ISNULL(total_cases, 0) total_cases_isnull, ISNULL(new_cases, 0) new_cases_isnull, ISNULL(total_deaths, 0) total_deaths_isnull, ISNULL(new_deaths, 0) new_deaths_isnull
	FROM dea) a
WHERE a.continent IS NOT NULL
GROUP BY a.date
ORDER BY a.date


--Total cases, total deaths, and death rate across the world
SELECT SUM(new_cases) total_cases, SUM(CAST(new_deaths as float)) total_deaths, SUM(CAST(new_deaths as float))/SUM(new_cases)*100 death_rate
FROM dea
WHERE continent IS NOT NULL


--Rolling vaccination percentage (Vaccination percentage is defined as the percentage of population having vaccinations)
SELECT *, (rolling_vaccination/population)*100  as rolling_vaccination_percentage
FROM pop_vac
ORDER BY location, date



-- Temp table
Drop table if exists population_vaccinated_rate
Create Table population_vaccinated_rate
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population float,
	new_vaccinations float,
	rolling_vaccination float
)

INSERT INTO population_vaccinated_rate
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
	SUM(CAST(cv.new_vaccinations as float)) OVER (PARTITION BY cd.location ORDER BY cd.date ASC) as rolling_vaccination
FROM (SELECT DISTINCT *
	FROM COVID19.dbo.Covid_Death) cd INNER JOIN COVID19.dbo.Covid_Vaccination cv
	ON cd.location = cv.location and cd.date = cv.date
WHERE cd.continent IS NOT NULL and cv.new_vaccinations IS NOT NULL

SELECT *, (rolling_vaccination/population)*100  as rolling_vaccination_percentage
FROM population_vaccinated_rate
ORDER BY location, date


View for visualizations
Drop view if exists pop_vac_rate
CREATE VIEW pop_vac_rate
as
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations,
		SUM(CAST(cv.new_vaccinations as float)) OVER (PARTITION BY cd.location ORDER BY cd.date ASC) as rolling_vaccination
	FROM (SELECT DISTINCT *
		FROM COVID19.dbo.Covid_Death) cd INNER JOIN COVID19.dbo.Covid_Vaccination cv
		ON cd.location = cv.location and cd.date = cv.date
	WHERE cd.continent IS NOT NULL and cv.new_vaccinations IS NOT NULL	
