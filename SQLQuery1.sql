Select *
from PortfolioProjectCovid..CovidVaccinations
order by 3, 4

-- Seleccionamos los datos que vamos a usar
Select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProjectCovid..CovidDeaths
order by 1, 2

-- Comparamos total_cases vs total_deaths
Select location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) *100 as DeathPercentage
from PortfolioProjectCovid..CovidDeaths
order by 1, 2

-- Comparamos total_cases vs total_deaths con un país especifico
Select location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) *100 as DeathPercentage
from PortfolioProjectCovid..CovidDeaths
Where location like '%china%'
order by 1, 2

-- Comparamos total_cases vs population con Argentina
-- Nos mostrará que porcentaje de la población tuvo covid
Select location, date, population, total_cases,  (CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) *100 as DeathPercentage
from PortfolioProjectCovid..CovidDeaths
Where location like '%gentina%'
order by 1, 2


-- Buscando el mayor numero de infectados por país
Select location, population, MAX(total_cases) as HighestInfectionCount,  MAX(total_cases/population) *100 as DeathPercentage
from PortfolioProjectCovid..CovidDeaths
--Where location like '%gentina%'
Group by location, population
order by DeathPercentage desc

-- Ahora con mayores muertes
Select location, MAX(cast(total_deaths as bigint)) as HighestDeathsCount
from PortfolioProjectCovid..CovidDeaths
--Where location like '%gentina%'
Where continent is not null
Group by location
order by HighestDeathsCount desc

--Ahora con mayores muertes ordenados por continente NO EFICIENTE
Select continent, MAX(cast(total_deaths as bigint)) as HighestDeathsCount
from PortfolioProjectCovid..CovidDeaths
where continent is not null
Group by continent
order by HighestDeathsCount desc

--Ahora con mayores muertes ordenados por continente MANERA COMPLETA
Select location, MAX(cast(total_deaths as bigint)) as HighestDeathsCount
from PortfolioProjectCovid..CovidDeaths
where continent is null
Group by location
order by HighestDeathsCount desc


-- Casos y muertes totales por fecha
Select 
	date, 
	SUM(new_cases) as total_cases,
	SUM(cast(new_deaths as bigint)) as total_deaths, 
	SUM(cast(new_deaths as bigint)) / NULLIF(SUM(new_cases),0) * 100 as DeathPercentage
From 
	PortfolioProjectCovid..CovidDeaths
Where 
	continent IS NOT NULL
group by 
	date
HAVING 
    SUM(CAST(new_deaths AS BIGINT)) / NULLIF(SUM(new_cases), 0) IS NOT NULL
order by 1, 2


-- CANTIDAD DE CASOS Y MUERTES
Select  
	SUM(new_cases) as total_cases,
	SUM(cast(new_deaths as bigint)) as total_deaths, 
	SUM(cast(new_deaths as bigint)) / NULLIF(SUM(new_cases),0) * 100 as DeathPercentage
From 
	PortfolioProjectCovid..CovidDeaths
Where 
	continent IS NOT NULL
order by 1, 2



-- Juntamos los datasets (muertes y vacunados)
Select *
From
	PortfolioProjectCovid..CovidDeaths dea
Join 
	PortfolioProjectCovid..CovidVaccinations vac
ON
	dea.location = vac.location
and
	dea.date = vac.date


-- Comparamos la población total con la vacunada
Select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations
From
	PortfolioProjectCovid..CovidDeaths dea
Join 
	PortfolioProjectCovid..CovidVaccinations vac
ON
	dea.location = vac.location
and
	dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
	AND
	new_vaccinations IS NOT NULL
ORDER BY
	2, 3


-- Ver 2
Select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
From
	PortfolioProjectCovid..CovidDeaths dea
Join
	PortfolioProjectCovid..CovidVaccinations vac
	ON
		dea.location = vac.location
	AND
		dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
ORDER BY
	2,3


-- Agregamos el porcentaje de gente vacunada en base a la población total del país
-- Vamos a usar una variable temp POPVSVAC

WITH PopvsVac (Continent, Location, Data, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
Select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
From
	PortfolioProjectCovid..CovidDeaths dea
Join
	PortfolioProjectCovid..CovidVaccinations vac
	ON
		dea.location = vac.location
	AND
		dea.date = vac.date
WHERE
	dea.continent IS NOT NULL
)
Select *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac


-- Creamos una tabla temporal para almacenar lo que hicimos en el punto anterior
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Data datetime,
	Population bigint,
	New_vaccinations bigint,
	RollingPeopleVaccinated bigint
)
INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) as RollingPeopleVaccinated
FROM 
	PortfolioProjectCovid..CovidDeaths dea
JOIN 
	PortfolioProjectCovid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE
	dea.continent is not null

SELECT *, (RollingPeopleVaccinated/Population) * 100
FROM #PercentPopulationVaccinated


-- Creamos VIEWs para despues usarla en las visualizaciones
CREATE VIEW PercentPopulationVaccinated as
Select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
From
	PortfolioProjectCovid..CovidDeaths dea
Join
	PortfolioProjectCovid..CovidVaccinations vac
	ON
		dea.location = vac.location
	AND
		dea.date = vac.date
WHERE
	dea.continent IS NOT NULL

SELECT 
	*
FROM
	PercentPopulationVaccinated