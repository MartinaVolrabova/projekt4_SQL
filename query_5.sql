/* QUERY_5 */

/* DOTAZ: Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
          projeví se to na cenách potravin či mzdách ve stejném nebo násdujícím roce výraznějším růstem? */
/* ODPOVĚĎ: Nelze určit, z analyzovaných dat nelze vypozorovat souvislost mezi růstem HDP a rychlostí zvyšování mezd a potravin */

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
