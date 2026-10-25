#!/bin/bash
chcp 65001
 
sqlite3 movies_rating.db < db_init.sql
 
echo "1. Найти все пары пользователей, оценивших один и тот же фильм (без дубликатов и пар с самим собой). Показать имена пользователей и название фильма. Первые 100 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT DISTINCT
    u1.name AS user1,
    u2.name AS user2,
    m.title AS movie
FROM ratings r1
JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id
JOIN users u1 ON u1.id = r1.user_id
JOIN users u2 ON u2.id = r2.user_id
JOIN movies m ON m.id = r1.movie_id
ORDER BY m.title, u1.name, u2.name
LIMIT 100;"
echo " "
 
echo "2. Найти 10 самых свежих оценок от разных пользователей: название фильма, имя пользователя, оценка, дата отзыва (ГГГГ-ММ-ДД)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT
    m.title AS movie,
    u.name AS user,
    r.rating,
    strftime('%Y-%m-%d', r.timestamp, 'unixepoch') AS rating_date
FROM (
    SELECT ratings.*,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp DESC) AS rn
    FROM ratings
) r
JOIN users u ON u.id = r.user_id
JOIN movies m ON m.id = r.movie_id
WHERE r.rn = 1
ORDER BY r.timestamp DESC
LIMIT 10;"
echo " "
 
echo "3. Вывести в одном списке фильмы с максимальным и минимальным средним рейтингом, отсортировать по году выпуска и названию. В колонке 'Рекомендуем' указать Да или Нет."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH avg_ratings AS (
    SELECT movie_id, AVG(rating) AS avg_rating
    FROM ratings
    GROUP BY movie_id
)
SELECT
    m.title,
    m.year,
    ROUND(a.avg_rating, 2) AS avg_rating,
    CASE
        WHEN a.avg_rating = (SELECT MAX(avg_rating) FROM avg_ratings) THEN 'Да'
        ELSE 'Нет'
    END AS 'Рекомендуем'
FROM avg_ratings a
JOIN movies m ON m.id = a.movie_id
WHERE a.avg_rating = (SELECT MAX(avg_rating) FROM avg_ratings)
   OR a.avg_rating = (SELECT MIN(avg_rating) FROM avg_ratings)
ORDER BY m.year, m.title;"
echo " "
 
echo "4. Вычислить количество оценок и среднюю оценку, которую дали фильмам пользователи-женщины в период с 2010 по 2012 год."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT
    COUNT(*) AS ratings_count,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM ratings r
JOIN users u ON u.id = r.user_id
WHERE LOWER(u.gender) IN ('female', 'f')
  AND CAST(strftime('%Y', r.timestamp, 'unixepoch') AS INTEGER) BETWEEN 2010 AND 2012;"
echo " "
 
echo "5. Составить список фильмов с указанием средней оценки и места в рейтинге по средней оценке. Отсортировать по году выпуска и названию. Первые 20 записей."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH movie_stats AS (
    SELECT
        m.id,
        m.title,
        m.year,
        ROUND(AVG(r.rating), 2) AS avg_rating,
        RANK() OVER (ORDER BY AVG(r.rating) DESC) AS rating_place
    FROM movies m
    JOIN ratings r ON r.movie_id = m.id
    GROUP BY m.id, m.title, m.year
)
SELECT title, year, avg_rating, rating_place
FROM movie_stats
ORDER BY year, title
LIMIT 20;"
echo " "
 
echo "6. Вывести список из 10 последних зарегистрированных пользователей в формате 'Фамилия Имя|Дата регистрации'."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "SELECT
    substr(name, instr(name, ' ') + 1) || ' ' ||
    substr(name, 1, instr(name, ' ') - 1) || '|' ||
    register_date AS user_info
FROM users
ORDER BY register_date DESC
LIMIT 10;"
echo " "
 
echo "7. С помощью рекурсивного CTE составить таблицу умножения для чисел от 1 до 10."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE mult(a, b) AS (
    SELECT 1, 1
    UNION ALL
    SELECT
        CASE WHEN b = 10 THEN a + 1 ELSE a END,
        CASE WHEN b = 10 THEN 1 ELSE b + 1 END
    FROM mult
    WHERE NOT (a = 10 AND b = 10)
)
SELECT a || 'x' || b || '=' || (a * b) AS multiplication_table
FROM mult;"
echo " "
 
echo "8. С помощью рекурсивного CTE выделить все жанры фильмов из таблицы movies (каждый жанр в отдельной строке)."
echo --------------------------------------------------
sqlite3 movies_rating.db -box -echo "WITH RECURSIVE split(genre, rest) AS (
    SELECT '', genres || '|'
    FROM (SELECT DISTINCT genres FROM movies)
    UNION ALL
    SELECT
        substr(rest, 1, instr(rest, '|') - 1),
        substr(rest, instr(rest, '|') + 1)
    FROM split
    WHERE rest <> ''
)
SELECT DISTINCT genre
FROM split
WHERE genre <> ''
ORDER BY genre;"