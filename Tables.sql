-- Tabulka vývoje fyzických (code = 5958)  mezd za jednotlivé obory v jednotlivých obdobích (roky a kvartály).
DROP TABLE t_martina_volrabova_project_SQL_primary_final;
CREATE TABLE t_martina_volrabova_project_SQL_primary_final 
AS
SELECT cp1.value           AS salary
      ,cpvt1.name          AS salary_type
	    ,cpu1.name           AS unit_name
	    ,cpc1.code           AS calculation_code
	    ,cpc1.name           AS calculation_name
	    ,cpib1.code          AS industry_branch_code
	    ,cpib1.name          AS industry_branch_name
	    ,cp1.payroll_year    AS payroll_year
 	    ,cp1.payroll_quarter AS payroll_quarter
FROM czechia_payroll cp1
INNER JOIN czechia_payroll_value_type cpvt1 ON cpvt1.code = cp1.value_type_code
INNER JOIN czechia_payroll_unit cpu1 ON cpu1.code = cp1.unit_code
INNER JOIN czechia_payroll_industry_branch cpib1 ON cpib1.code = cp1.industry_branch_code
INNER JOIN czechia_payroll_calculation cpc1 ON cpc1.code = cp1.calculation_code 
WHERE 1=1
AND cp1.value IS NOT NULL
AND cpvt1.code = 5958;

/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/

-- Tabulka vývoje maloobchodních cen v jednotlivých regionech v jednotlivých obdobích
DROP TABLE t_martina_volrabova_project_SQL_secondary_final;
CREATE TABLE t_martina_volrabova_project_SQL_secondary_final 
AS
 SELECT cp1.id
       ,cp1.value         AS price
       ,cp1.category_code AS category_code
       ,cpc1.name         AS category_name
       ,cpc1.price_value  AS price_value
       ,cpc1.price_unit   AS price_unit
       ,cr1.code          AS region_code
       ,cr1.name          AS region_name
       ,cp1.date_from     AS date_from
       ,cp1.date_to       AS date_to
       ,YEAR(date_to)     AS Year
       ,QUARTER(date_to)  AS Quarter
 -- Informace o cenách vybraných potravin za několikaleté období (roky a kvartály)
 FROM czechia_price cp1
 -- Číselník kategorií potravin
 INNER JOIN czechia_price_category cpc1 ON cpc1.code = cp1.category_code
 -- Infomrace o regionech
 INNER JOIN czechia_region cr1 ON cr1.code = cp1.region_code
 ORDER BY date_from, date_to asc;

/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/* price_changes: Pomocná množina obsahuje funkci LAG, která vezme hodnotu průměrné ceny z předchozího roku v rámci stejné kategorie
                  a doplní ji k roku následujícímu a tím v jednom řádku vznikne infomrace o průměrné ceně za předchozí a aktuální období.
                  Pro snadnější spojení s cenami potravit, byly vybrány pouze ceny potravin za 4 kvartál */
CREATE /*TEMPORARY -- access denied */ TABLE price_changes
SELECT price
       ,category_name
       ,((lag(price) OVER (PARTITION BY category_name ORDER BY year ASC) - price ) / price ) * 100  AS yearly_change_percent
       ,year
 FROM t_martina_volrabova_project_SQL_secondary_final
 WHERE quarter = 4;

/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
 /* salary_changes: Pomocná množina obsahuje funkci LAG, která vezme hodnotu průměrné mzdy z předchozího roku v rámci stejného oboru 
                  a doplní ji k roku následujícímu a tím v jednom řádku vznikne infomrace o průměrné mzdě za předchozí a aktuální období.
                  Výsledek této analytické funkce je dále použit pro výpočet meziroční změny ve vývoji mzdy (yearly_change_percent).
                  Pro snadnější spojení s cenami potravit, byly vybrány mzdy pouze fyzické mzdy za 4 kvartál */

 CREATE /*TEMPORARY -- access denied */ TABLE salary_changes AS
 SELECT payroll_year
       ,salary
       ,-((lag(salary) OVER (PARTITION BY industry_branch_name ORDER BY payroll_year ASC) - salary ) / salary ) * 100  AS yearly_change_percent
	   ,industry_branch_name
 FROM t_martina_volrabova_project_SQL_primary_final 
 WHERE calculation_code = 100 -- fyzicky
   AND payroll_quarter = 4;
