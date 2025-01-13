/* QUERY_4 */

/* DOTAZ: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)? */
/* ODPOVĚĎ: V roce 2013 byl nárůst cen potravin vyšší než růst mezd a to zejména proto, že v roce 2013 mzdy výrazně klesaly */

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
