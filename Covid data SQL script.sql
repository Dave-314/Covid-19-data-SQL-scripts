-- view total vaccinations for each country
SELECT location, SUM(CONVERT(INT,new_tests)) AS vaccinations_to_date
FROM CovidPortfolio..CovidVaccinations
GROUP BY location
ORDER BY location, vaccinations_to_date

-- view total tests, vaccinations, cases and deaths for each country
SELECT vax.location, SUM(CONVERT(INT, vax.new_tests)) AS tests_to_date,
	SUM(CAST(vax.new_vaccinations AS BIGINT)) AS vaccinations_to_date,
	SUM(death.new_cases) AS cases_to_date,
	SUM(death.new_deaths) AS deaths_to_date
FROM CovidPortfolio..CovidVaccinations as vax
JOIN CovidPortfolio..CovidDeaths as death 
	ON death.location = vax.location
	AND death.date = vax.date
GROUP BY vax.location
ORDER BY vax.location

-- calculate new tests and total tests for each month in the united states
SELECT YEAR(death.date) AS year, MONTH(death.date) AS month, 
	SUM(death.new_cases) AS month_cases,
	SUM(CONVERT(INT, vax.new_tests)) AS month_tests,
	SUM(CONVERT(INT,vax.new_vaccinations)) AS month_vaccinations,
	SUM(death.new_deaths) AS month_deaths
FROM CovidPortfolio..CovidVaccinations AS vax
JOIN CovidPortfolio..CovidDeaths AS death
	ON vax.location = death.location
	AND vax.date = death.date
WHERE vax.location LIKE 'United States'
GROUP BY YEAR(death.date), MONTH(death.date)
ORDER BY YEAR(death.date), MONTH(death.date)

-- view a rolling total of tests for each location
--Note: many 'null' data, countries have different start date  
SELECT location, date, new_tests, SUM(convert(int, new_tests)) OVER (PARTITION BY location ORDER BY location, date) AS tests_running_total
FROM CovidPortfolio..CovidVaccinations
ORDER BY location, date

-- view a rolling total of new cases by location
--Note: many 'null' data, countries have different start date  
SELECT location, date, new_cases, SUM(new_cases) OVER (PARTITION BY location ORDER BY location, date) AS cases_running_total
FROM CovidPortfolio..CovidDeaths

-- view a rolling total of both new cases and new tests
SELECT vax.location, vax.date, 
	SUM(CONVERT(INT, vax.new_tests)) OVER (PARTITION BY vax.location ORDER BY vax.location, vax.date) AS tests_running_total,
	SUM(death.new_cases) OVER(PARTITION BY vax.location ORDER BY vax.location, vax.date) AS cases_running_total
FROM CovidPortfolio..CovidVaccinations AS vax
JOIN CovidPortfolio..CovidDeaths AS death
	ON vax.location = death.location
	AND vax.date = death.date

-- calculate new case and new deaths for each month for the United States
SELECT YEAR(date) AS year, MONTH(date) AS month, SUM(new_cases) AS month_cases, SUM(new_deaths) AS month_deaths
FROM CovidPortfolio..CovidDeaths
WHERE location LIKE 'United States'
GROUP BY YEAR(date), MONTH(date)
ORDER BY YEAR(date), MONTH(date)

-- total tests by continent
SELECT continent, SUM(CONVERT(int, new_tests))/1000000 AS total_tests_in_millions
FROM CovidPortfolio..CovidVaccinations
WHERE continent IS NOT NULL
-- remove categorization by socio-economic status
	AND location NOT LIKE '%income%'
GROUP BY continent

-- total deaths by continent
SELECT continent, SUM(new_deaths) AS continent_total_deaths
FROM CovidPortfolio..CovidDeaths
WHERE continent IS NOT NULL
	AND location NOT LIKE '%income%'
GROUP BY continent

-- view deaths per case for each country
SELECT continent, location, 
	SUM(new_deaths) AS deaths, 
	SUM(new_cases) AS cases, 
	SUM(new_deaths) / SUM(NULLIF(new_cases,0)) * 100000 AS case_fatality_per_100k
FROM CovidPortfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY case_fatality_per_100k DESC

-- view deaths/case, deaths/population, case/population 
SELECT continent, location, population,
	SUM(new_deaths) AS deaths, 
	SUM(new_cases) AS cases, 
	SUM(new_deaths) / SUM(NULLIF(new_cases,0)) * 100000 AS case_fatality_per_100k,
	SUM(new_deaths) / population *100000 AS population_death_per_100k,
	SUM(new_cases) / population * 100000 AS population_cases_per_1000k
FROM CovidPortfolio..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY case_fatality_per_100k DESC

-- calculate proportion of population that is fully vaccinated by date and location where available
-- NOTE: not all countries/date have data for 'people_fully vaccinated'
SELECT death.date, death.continent, death.location, death.population, vax.people_fully_vaccinated, 
	ROUND(SUM(CAST(vax.people_fully_vaccinated AS BIGINT)) / death.population * 100, 0) AS population_proportion_fully_vax
FROM CovidPortfolio..CovidDeaths AS death
JOIN CovidPortfolio..CovidVaccinations as vax
	ON death.location = vax.location AND
	death.date = vax.date
WHERE death.continent IS NOT NULL
	AND people_fully_vaccinated IS NOT NULL
GROUP BY death.continent, death.location, death.date, death.population, vax.people_fully_vaccinated
--HAVING ROUND(SUM(CAST(vax.people_fully_vaccinated AS BIGINT)) / death.population * 100, 0) > 100