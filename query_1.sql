/*QUERY_1*/
/* DOTAZ: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají? */
/* ODPOVĚĎ: Mzdy v průměru rostou, vyjímkou jsou roky 2013 a 2014. V těchto obcodbích mzdy klesaly. */

/* Výsledná množina: obsahuje vývoj mezd v různých odvětvích na základě ročních údajů (payroll_year) a obsahuje informace o průměrných mzdách, meziročním růstu mezd a směru pohybu mezd.
                     Pokud atribut "yearly_change_percent" obsahuje +, mzda meziročně rostla, pokud -, mzda meziročně klesla */
SELECT  payroll_year
       ,industry_branch_name
       ,salary
       ,round(yearly_change_percent, 2) AS yearly_change_percent
       ,CASE WHEN yearly_change_percent > 0 THEN '+'
             WHEN yearly_change_percent < 0 THEN '-'
             ELSE 'N/A'
        END AS salary_movement     
FROM (
		SELECT payroll_year
              ,salary
              ,-((lag(salary) OVER (PARTITION BY industry_branch_name ORDER BY payroll_year ASC) - salary ) / salary ) * 100  AS yearly_change_percent
	          ,industry_branch_name
        FROM t_martina_volrabova_project_SQL_primary_final 
        WHERE calculation_code = 100 -- fyzicky
          AND payroll_quarter = 4
     ) src1
