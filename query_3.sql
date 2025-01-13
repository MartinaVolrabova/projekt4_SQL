/* QUERY_3 */     
        
/* DOTAZ: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)? */
/* ODPOVĚĎ: Nejpomaleji zdražuje Cukr krystalový */

/* yearly_prices: Pomocná množina obsahuje zprůměrovaná data o cenách potravit za celou Českou republiku ve 4 kvartále, což zajistí
                  konzistenci v porovnávání cen EOY v jednotlivých letech */
WITH yoy_avg_price AS (
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
yoy_price_change AS (
    SELECT 
        category_name,
        year,
        avg_price,
        LAG(avg_price) OVER (PARTITION BY category_name ORDER BY year ASC) AS prev_year_price
    FROM yoy_avg_price
)
/* Výsledná množina: množina obsahuje data o průměrném meziročním vývoji cen jednotlivých potravin za celé měřené období (2006 - 2018)
                     Výsledkem je že Cuktr krystalový meziročně v průměru zlevňoval a jeho cena tedy zdražovala nejpomaleji*/
SELECT category_name
      ,ROUND(AVG((avg_price - prev_year_price) / prev_year_price) * 100, 2) AS avg_growth_rate
FROM yoy_price_change
WHERE prev_year_price IS NOT NULL
GROUP BY category_name
ORDER BY avg_growth_rate ASC;
