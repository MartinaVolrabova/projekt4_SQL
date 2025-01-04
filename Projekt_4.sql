/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/**                                     name: Projekt_4.sql                                                                                 **/                                                        
/**                                     author: Martina Volrábová                                                                           **/
/**                                     email: Martina.volrabova@seznam.cz                                                                  **/
/**                                     discord: Martina Volrabova#!pdb1714                                                                 **/ 
/*********************************************************************************************************************************************/
/** Changelog: 2024/12/29 - first written                                                                                                   **/
/*********************************************************************************************************************************************/
/** Ukol_4 obsahuje dvě zdrohjové tabulky a 5 queries, které hledají odpověď na zkoumané otázky:                                            **/
/** tabulka_1 - t_martina_volrabova_project_SQL_primary_final                                                                               **/
/** tabulka_2 - t_martina_volrabova_project_SQL_secondary_final                                                                             **/
/** query_1   - data o vývoji mezd v různých odvětvích na základě ročních údajů                                                             **/
/** query_2   - data o mzdách pro jednotlivé obory, průměrnou cenu zkoumaných potravin v ČR v CZK                                           **/
/** query_3   - data o průměrném meziročním vývoji cen jednotlivých potravin za celé měřené období (2006 - 2018)                            **/
/** query_4   - data o procentuální meziroční změně průměrných mezd v ČR (průměr všech oborů)                                               **/
/** query_5   - data o ekonomickém vývoji ČR od roku 2000                                                                                   **/
/*********************************************************************************************************************************************/

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

/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/* QUERY_2 */
     
/* DOTAZ: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?*/
/* ODPOVĚĎ: viz výsledná množina, jetnovlicé obory mohly pořizovan různá množství chleba a mléka v jednotlivých kvartálech a letech */
     
/* min_max_year: Pomocná množina identifikující MIN a MAX období pro vývoj mezd a cen potravin, které jsou shodné v obou cílovách tabulkách 
                 množina je dále omezena pouze na produkty mléko a chleba src.category_code IN (111301, 114201) */
WITH min_max_year AS
(
SELECT min(src1.payroll_year) AS min_year
      ,max(src1.payroll_year) AS max_year
      ,src2.category_code
FROM t_martina_volrabova_project_SQL_primary_final src1
INNER JOIN t_martina_volrabova_project_SQL_secondary_final src2 ON src2.YEAR = src1.payroll_year
WHERE category_code IN (111301, 114201)
GROUP BY src2.category_code
)
/* Výsledná množina: množina obsahuje data o mzdách (salary) pro jednotlivé obory (industry_branch_name), průměrnou cenu zkoumaných potravin v České Republice v CZK (price)
                     a množství (quantity), které lze za jetnovlié mzdy pořídit (Chléb v kilogramech a Mléko v litrech). 
                     Množina obsahuje historická data rozdělená do jetnolivých kvartálů a roků (payroll_quarter, payroll_year)*/
SELECT distinct src1.salary
      ,src1.industry_branch_name
      ,src2.category_name
      ,src2.price
      ,Round(src1.salary / src2.price , 0) AS quantity
      ,src1.payroll_quarter
      ,src1.payroll_year

FROM t_martina_volrabova_project_SQL_primary_final src1
CROSS JOIN min_max_year src3
INNER JOIN (
			SELECT Round(avg(srcc1.price),2) AS price
			      ,srcc1.category_code
			      ,srcc1.category_name
			      ,srcc1.quarter
			      ,srcc1.year
			FROM t_martina_volrabova_project_SQL_secondary_final srcc1
			WHERE srcc1.category_code IN (111301, 114201)
			GROUP BY category_code, category_name, quarter, year
            ) src2 ON src2.quarter       = src1.payroll_quarter
                  AND src2.year          = src1.payroll_year
                  AND src2.category_code = src3.category_code
                  AND (src2.year = src3.min_year OR src2.year = src3.max_year)
WHERE src1.calculation_code = 100
ORDER BY src1.industry_branch_name
        ,src1.payroll_quarter
        ,src1.payroll_year
        ,src2.category_name ASC
  
/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/* QUERY_3 */     
        
/* DOTAZ: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? */
/* ODPOVĚĎ: Nejpomaleji zdražuje Cukr krystalový */

/* yearly_prices: Pomocná množina obsahuje zprůměrovaná data o cenách potravit za celou Českou republiku ve 4 kvartále, což zajistí
                  konzistenci v porovnávání cen EOY v jednotlivých letech */
WITH yearly_prices AS (
    SELECT 
        category_name
       ,year
       ,AVG(price) AS avg_price
    FROM t_martina_volrabova_project_SQL_secondary_final
    WHERE quarter = 4
    GROUP BY category_name, year
),
/* price_changes: Pomocná množina obsahuje funkci LAG, která vezme hodnotu průměrné ceny z předchozího roku v rámci stejné kategorie 
                  a doplní ji k roku následujícímu a tím v jednom řádku vznikne infomrace o průměrné ceně za předchozí a aktuální období */
price_changes AS (
    SELECT 
        category_name,
        year,
        avg_price,
        LAG(avg_price) OVER (PARTITION BY category_name ORDER BY year ASC) AS prev_year_price
    FROM yearly_prices
)
/* Výsledná množina: množina obsahuje data o průměrném meziročním vývoji cen jednotlivých potravin za celé měřené období (2006 - 2018)
                     Výsledkem je že Cuktr krystalový meziročně v průměru zlevňoval a jeho cena tedy zdražovala nejpomaleji*/
SELECT category_name
      ,ROUND(AVG((avg_price - prev_year_price) / prev_year_price) * 100, 2) AS avg_growth_rate
FROM price_changes
WHERE prev_year_price IS NOT NULL
GROUP BY category_name
ORDER BY avg_growth_rate ASC;

/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/* QUERY_4 */

/* DOTAZ: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)? */
/* ODPOVĚĎ: V roce 2013 byl nárůst cen potravin vyšší než růst mezd a to zejména proto, že v roce 2013 mzdy výrazně klesaly */

/* salary_changes: Pomocná množina obsahuje funkci LAG, která vezme hodnotu průměrné mzdy z předchozího roku v rámci stejného oboru 
                  a doplní ji k roku následujícímu a tím v jednom řádku vznikne infomrace o průměrné mzdě za předchozí a aktuální období.
                  Výsledek této analytické funkce je dále použit pro výpočet meziroční změny ve vývoji mzdy (yearly_change_percent).
                  Pro snadnější spojení s cenami potravit, byly vybrány mzdy pouze fyzické mzdy za 4 kvartál */
WITH salary_changes AS
(
 SELECT payroll_year
       ,salary
       ,-((lag(salary) OVER (PARTITION BY industry_branch_name ORDER BY payroll_year ASC) - salary ) / salary ) * 100  AS yearly_change_percent
	   ,industry_branch_name
 FROM t_martina_volrabova_project_SQL_primary_final 
 WHERE calculation_code = 100 -- fyzicky
   AND payroll_quarter = 4
),

/* price_changes: Pomocná množina obsahuje funkci LAG, která vezme hodnotu průměrné ceny z předchozího roku v rámci stejné kategorie
                  a doplní ji k roku následujícímu a tím v jednom řádku vznikne infomrace o průměrné ceně za předchozí a aktuální období.
                  Pro snadnější spojení s cenami potravit, byly vybrány pouze ceny potravin za 4 kvartál */
price_changes AS 
(
 SELECT price
       ,category_name
       ,((lag(price) OVER (PARTITION BY category_name ORDER BY year ASC) - price ) / price ) * 100  AS yearly_change_percent
       ,year
 FROM t_martina_volrabova_project_SQL_secondary_final
 WHERE quarter = 4
)

/* Výsledná množina: množina obsahuje data o procentuální meziroční změně průměrných mezd v ČR (průměr všech oborů) - "avg_yearly_salary_change_percent"
                     a meziroční změně cen potravin v procentech "avg_yearly_price_change_percent" pro jednotlivé potraviny "category_name".
                     Výsledná množina zobrazuje pouze období (roky) ve kterých cena potravin rostla rychleji než mzdy o více než 10%. */
SELECT sc1.payroll_year
       ,avg(sc1.salary) AS avg_salary
       ,round(avg(sc1.yearly_change_percent),2) AS avg_yearly_salary_change_percent
       ,pc1.category_name
       ,avg(pc1.price) AS avg_price
       ,round(avg(pc1.yearly_change_percent),2) AS avg_yearly_price_change_percent
FROM salary_changes sc1
INNER JOIN price_changes pc1 ON pc1.year = sc1.payroll_year
GROUP BY sc1.payroll_year
        ,sc1.industry_branch_name
        ,pc1.category_name
        ,pc1.year
HAVING avg(pc1.yearly_change_percent) > 0
       AND  avg(pc1.yearly_change_percent) - avg(sc1.yearly_change_percent)  > 10;

/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/
/*********************************************************************************************************************************************/      
/* QUERY_5 */

/* DOTAZ: Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
          projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem? */
/* ODPOVĚĎ: Nelze určit, z analyzovaných dat nelze vypozorovat souvislost mezi růstem HDP a rychlostí zvyšování mezd a potravin */
      
/* price_changes: Pomocná množina obsahuje funkci LAG, která vezme hodnotu průměrné ceny z předchozího roku v rámci stejné kategorie
                  a doplní ji k roku následujícímu a tím v jednom řádku vznikne infomrace o průměrné ceně za předchozí a aktuální období.
                  Pro snadnější spojení s cenami potravit, byly vybrány pouze ceny potravin za 4 kvartál */
WITH price_changes AS
(
  SELECT price
       ,category_name
       ,((lag(price) OVER (PARTITION BY category_name ORDER BY year ASC) - price ) / price ) * 100  AS yearly_change_percent
       ,year
 FROM t_martina_volrabova_project_SQL_secondary_final
 WHERE quarter = 4
),

/* salary_changes: Pomocná množina obsahuje funkci LAG, která vezme hodnotu průměrné mzdy z předchozího roku v rámci stejného oboru 
                  a doplní ji k roku následujícímu a tím v jednom řádku vznikne infomrace o průměrné mzdě za předchozí a aktuální období.
                  Výsledek této analytické funkce je dále použit pro výpočet meziroční změny ve vývoji mzdy (yearly_change_percent).
                  Pro snadnější spojení s cenami potravit, byly vybrány mzdy pouze fyzické mzdy za 4 kvartál */
 salary_changes AS
(
 SELECT payroll_year
       ,salary
       ,-((lag(salary) OVER (PARTITION BY industry_branch_name ORDER BY payroll_year ASC) - salary ) / salary ) * 100  AS yearly_change_percent
	   ,industry_branch_name
 FROM t_martina_volrabova_project_SQL_primary_final 
 WHERE calculation_code = 100 -- fyzicky
   AND payroll_quarter = 4
)

/* Výsledná množina:  reprezentuje ekonomický vývoj ČR od roku 2000 na základě tří hlavních ukazatelů:

  * Makroekonomický výkon (GDP)
  * ceny potravin a jejich růst – jak se vyvíjely průměrné ceny potravin a jejich meziroční změny
  * mzdy a jejich růst – Jak rostly (nebo stagnovaly) průměrné mzdy
 
   Výstupem je časová řada s meziročními změnami, která umožňuje:
   
  * porovnat tempo růstu GDP, mezd a cen potravin
  * identifikovat roky ekonomických krizí, kdy GDP klesalo a inflace rostla
  * vyhodnotit, zda růst mezd držel krok s inflací potravin. */

SELECT e1.country
      ,e1.year
      ,e1.GDP
      ,(-(lag(e1.GDP) OVER (PARTITION BY e1.country ORDER BY e1.year ASC) - e1.GDP ) / e1.GDP ) * 100  AS gdp_yearly_change_percent
      ,ROUND(AVG(pc1.price),2) AS avg_food_price 
      ,ROUND(AVG(pc1.yearly_change_percent),2) AS food_yearly_change_percent
      ,ROUND(AVG(sc1.salary),2) AS avg_salary 
      ,ROUND(AVG(sc1.yearly_change_percent),2) AS salary_yearly_change_percent

FROM economies e1
INNER JOIN price_changes pc1 ON pc1.year = e1.year
INNER JOIN salary_changes sc1 ON sc1.payroll_year = e1.year

WHERE e1.country = 'Czech Republic'
  AND e1.year >= 2000

 GROUP BY  e1.country
          ,e1.year
          ,e1.GDP
ORDER BY e1.year ASC  
