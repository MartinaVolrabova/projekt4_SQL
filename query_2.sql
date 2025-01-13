/* QUERY_2 */
     
/* DOTAZ: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?*/
/* ODPOVĚĎ: viz výsledná množina, jetnovlicé obory mohly pořizovan různá množství chleba a mléka v jednotlivých kvartálech a letech */
     
/* Pomocná query identifikující MIN a MAX období pro vývoj mezd a cen potravin, které jsou shodné v obou cílovách tabulkách 
                 množina je dále omezena pouze na produkty mléko a chleba src.category_code IN (111301, 114201)
SELECT min(src1.payroll_year) AS min_year
      ,max(src1.payroll_year) AS max_year
      ,src2.category_code
FROM t_martina_volrabova_project_SQL_primary_final src1
INNER JOIN t_martina_volrabova_project_SQL_secondary_final src2 ON src2.YEAR = src1.payroll_year
WHERE category_code IN (111301, 114201)
GROUP BY src2.category_code  */

/* Výsledná množina: množina obsahuje data o mzdách (salary) pro jednotlivé obory (industry_branch_name), průměrnou cenu zkoumaných potravin v České Republice v CZK (price)
                     a množství (quantity), které lze za jetnovlié mzdy pořídit (Chléb v kilogramech a Mléko v litrech). 
                     Množina obsahuje historická data rozdělená do zkoumaných let 2006 a 2018 (payroll_year)*/
SELECT avg(src1.salary) as avg_salary
      ,src1.industry_branch_name
      ,src2.category_name
      ,src2.price
      ,Round(avg(src1.salary)/ src2.price , 0) AS quantity
      ,src1.payroll_year

FROM t_martina_volrabova_project_SQL_primary_final src1
INNER JOIN (
			SELECT Round(avg(sq1.price),2) AS price
			      ,sq1.category_code
			      ,sq1.category_name
			      ,sq1.year
			FROM t_martina_volrabova_project_SQL_secondary_final sq1
			WHERE sq1.category_code IN (111301, 114201)
			  AND sq1.Year in (2006,2018) 
			GROUP BY category_code, category_name, year
            ) src2  ON src2.year          = src1.payroll_year
WHERE src1.calculation_code = 100
GROUP BY src1.industry_branch_name
        ,src2.category_name
        ,src2.price
        ,src1.payroll_year
        
ORDER BY src1.industry_branch_name
        ,src1.payroll_year
        ,src2.category_name ASC
