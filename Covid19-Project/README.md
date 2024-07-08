# Covid19-Project. (MySQL Workbench/Tableau)

This project is a collection of SQL queries and data analysis related to COVID-19 data. It aims to analyze COVID-19 statistics, including deaths, cases, vaccinations, and population data, and derive insights from the data. It performs various calculations and creates views to facilitate further analysis. The project includes the following major sections:

Filtering and Sorting Data: The project starts by selecting specific columns from a table named "coviddeaths" where the "continent" column is not null and orders the results based on certain columns.

Analyzing COVID-19 Cases and Deaths in States: It focuses on COVID-19 cases and deaths in locations containing the word "states" in their name, calculating death percentages and population percentages affected.

Analyzing Countries with High Infection Rates: It identifies countries with the highest infection rates compared to their populations.

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/e4e46895-3c52-4038-955b-fae113cbcaaa)

Analyzing Countries with the Highest Death Counts: It identifies countries with the highest death counts per population.

Breakdown by Continent: It breaks down COVID-19 data by continent, including the continent with the highest death count per population.

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/6b93c1a4-dba7-4c62-acd6-ad3c7f699755)

Global COVID-19 Numbers: It presents global COVID-19 statistics, including total cases, total deaths, and death percentages.

Calculations without Date: Similar to the global numbers but without considering specific dates.

Using Common Table Expressions (CTE): The project demonstrates the use of CTEs to simplify complex queries and calculations.

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/a95ff9dd-9577-4a5e-9afe-8f54470330d8)

Creating and Populating Temporary Tables: Temporary tables are created to store intermediate results, and data is inserted into these tables. The code also calculates the percentage of the population vaccinated.

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/728e2723-1d79-4ae3-9f0b-383efcf08adb)

Further Analysis: This section includes additional calculations and creates a view to store data for later visualizations.

Creating a View: A view named "PercentPopulationVaccinated" is created to store processed data for visualization purposes.

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/0803140b-3503-43ea-af2c-bdd34d424cdb)

Selecting Data from View: The project concludes by selecting data from the created view.

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/9d17b89f-11e2-46db-ad9d-804348a8dfd4)

This project serves as a comprehensive analysis of COVID-19 data using SQL queries and provides a structured workflow for analyzing and visualizing pandemic-related statistics.

Furthermore, Summary of the COVID-19 Data Analysis in Tableau with MySQL Queries (Visualization)

Description:
This Tableau project focuses on the analysis of COVID-19 data using MySQL queries to extract and transform the data for visualization in Tableau with a focus on summarizing and visualizing key statistics such as total cases, total deaths, death percentages, and infection rates.

Queries Used:
1. Global Numbers: Calculates total cases, total deaths, and the death percentage for COVID-19 data, filtering for specific conditions such as excluding locations with null continents and ordering the results by total cases and total deaths.

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/4245c165-a73e-42cb-8d71-f81b59554c81)

2. Total Deaths Per Continent: Retrieves the total death count for different locations, excluding specific entries like 'World,' 'European Union,' and 'International,' and orders the results by the total death count.

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/11fd5b27-09c5-4414-b6bc-14c8bfc4f3f0)

3. Percent Population Infected Per Country: Identifies the locations with the highest infection counts and calculates the percentage of the population infected for each location. The results are ordered by the percentage of the population infected.

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/97855fba-4e05-4bd9-bf61-52de0e2a0594)

4. Percent Population Infected: Similar to Query 3, but this query also considers the infection data over time by including the date in the analysis.

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/9a8fa137-deb2-46c9-b5f5-00a9957e6222)

Dashboard View

![image](https://github.com/ibukuntolulope/Covid19-Project/assets/90901397/9e1d1a87-a954-49ba-adc2-a498ea4d02ed)

This project is suitable for anyone interested in analyzing and visualizing COVID-19 data using Tableau and MySQL. The provided SQL queries can be used to retrieve and preprocess data for Tableau dashboards and visualizations, making it a valuable resource for data enthusiasts interested.
