 /* Q1-A Write ALL the queries we need to rent out a given movie.
 (Hint: these are the business logics that go into this task: 
 first confirm that the given movie is in stock, and then INSERT a row into the rental and the payment tables. 
 You may also need to check whether the customer has an outstanding balance 
 or an overdue rental before allowing him/her to rent a new DVD).
 film = Freaky Pocus
 customer = first_name Nicole
 in stock 
 table - inventory, rental, film
 customer outstanding balance or 
 table - payment, rental, customer, film
 -if payment date is null, the customer has outstanding balance
 -return status is late
 overdue rental
 table - rental, film, inventory, customer
 */

 
 --check outstanding balance 
SELECT payment.payment_id, payment.payment_date, customer.customer_id
FROM payment
JOIN customer 
 USING (customer_id)
WHERE  customer.first_name = 'Nicole'
AND payment_date IS NULL

--check if overdue rental

SELECT *
FROM rental
JOIN customer
USING (customer_id)
WHERE customer.first_name = 'Nicole' AND return_date IS NULL
 
 -- To check if the movie is in stock
 SELECT film.film_id, rental.rental_date, rental.return_date
 FROM film
 JOIN inventory
 USING (film_id)
JOIN rental
 USING (inventory_id)
 WHERE title = 'Freaky Pocus'
 ORDER BY rental.rental_date DESC;
 --insert into rental table 
INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, staff_id)
VALUES (16050, '06/07/2022', 1525, 68, 1 )
 --insert into payment table 
INSERT INTO payment (payment_id, customer_id, staff_id, rental_id, amount, payment_date)
VALUES (32099, 68, 1, 16050, 2.99, '06/07/2022' )
--OR
INSERT INTO rental (rental_id, rental_date, inventory_id, customer_id, staff_id)
VALUES (16050, Now(), 1526, 68, 1 )
  
 /* 1B- write ALL the queries we need to process return of a rented movie.
 (Hint: update the rental table and add the return date by first identifying the rental_id
 to update based on the inventory_id of the movie being returned.
 Table - rental, film, inventory, customer)*/

 --Find rental_id
 SELECT rental.rental_id
FROM film
JOIN inventory
USING (film_id)
JOIN rental
USING (inventory_id)
JOIN customer
USING (customer_id)
WHERE inventory_id = 2047
AND first_name = 'Gail' AND last_name = 'Knight'
--update the records
UPDATE rental
SETreturn_date = '07/06/2022'
WHERE rental_id = 11496
 -- To find where return_date is null
 SELECT * FROM rental 
 WHERE return_date IS NULL
 
/* 2-A Which movie genres are the most and least popular? 
  And how much revenue have they each generated for the business?*/
 -- create view to least_popular
 CREATE VIEW least_popular AS(
	(SELECT name as genre, COUNT(rental_id) AS number_of_rentals, sum (payment.amount) as revenue
	FROM payment
	 join rental
	 using (rental_id)
	JOIN inventory USING(inventory_id)
	JOIN film_category USING(film_id)
	JOIN category USING(category_id)
	GROUP BY Genre
	ORDER BY number_of_rentals, revenue
	LIMIT 1) 
	UNION ALL
 -- creat view to most_popular
 -- CREATE VIEW most_popular AS(
	(SELECT name as genre, COUNT(rental_id) AS number_of_rentals, sum (payment.amount) as revenue
	FROM payment
	 join rental
	 using (rental_id)
	JOIN inventory USING(inventory_id)
	JOIN film_category USING(film_id)
	JOIN category USING(category_id)
	GROUP BY Genre
	ORDER BY number_of_rentals desc, revenue asc
 LIMIT 1)
--return most and least popular in one table
SELECT * FROM least_popular
UNION
SELECT * FROM most_popular;


/*2B-What are the top 10 most popular movies? And how many times have they each been rented out thus far?
table - rental, film, inventory
title, #rented*/

SELECT film.film_id, film.title, COUNT (rental.rental_id) AS rental_frequency
FROM rental
JOIN inventory
USING (inventory_id)
JOIN film 
USING (film_id)
GROUP BY film.title, film.film_id
ORDER BY COUNT (rental.rental_id) DESC
LIMIT 10

/*2C- Which genres have the highest and the lowest average rental rate?*/
--create view for highest average 
CREATE VIEW highest_AVG_rental AS(SELECT ct.name AS genre, ROUND(AVG(rental_rate),2) AS avg_rent
FROM category ct
INNER JOIN film_category fc ON fc.category_id=ct.category_id
INNER JOIN film fl ON fl.film_id=fc.film_id
GROUP BY genre
ORDER BY AVG(rental_rate) desc
LIMIT 1)
--create view for lowest average
CREATE VIEW lowest_AVG_rental AS(SELECT ct.name AS genre, ROUND(AVG(rental_rate),2) AS avg_rent
FROM category ct
INNER JOIN film_category fc ON fc.category_id=ct.category_id
INNER JOIN film fl ON fl.film_id=fc.film_id
GROUP BY genre
ORDER BY AVG(rental_rate) 
LIMIT 1)
-- return highest and lowest together
SELECT * FROM lowest_AVG_rental
UNION
SELECT * FROM highest_AVG_rental;


/* 2D-How many rented movies were returned late
Is this somehow correlated with the genre of a movie?
table - rental, film, inventory
film_id, rental duration, rental_date , return_date */

 --correlation NOT DONE
  WITH table_A AS (SELECT*, date_part('day', return_date - rental_date)
			AS date_difference
			FROM rental),
			table_B AS (SELECT rental_duration, date_difference,
				  CASE
				  WHEN rental_duration < date_difference THEN 'return_late'
						WHEN rental_duration >= date_difference THEN 'return_ontime'
						ELSE 'not_returned' 
				  END AS return_status
				 FROM film
				  JOIN inventory
				  USING (film_id)
				  JOIN table_A
				  USING (inventory_id))
				  SELECT return_status, COUNT(*) AS total_number_of_movies
				  FROM Table_B
	   group by 1
  

				  
/* 2E - What are the top 5 cities that rent the most movies
How about in terms of total sales volume?
table - city, address , custormer, rental, inventory, film 
name city, # movies rented*/
-- rented the most movie 
SELECT city.city_id, city.city, COUNT (rental.inventory_id)  Number_of_rental
FROM city
JOIN address
USING (city_id)
JOIN customer
USING (address_id)
JOIN rental
USING (customer_id)
JOIN inventory 
USING (inventory_id)
JOIN film 
USING (film_id)
GROUP BY city.city_id, city.city
ORDER BY COUNT  (rental.inventory_id) DESC
LIMIT 5
-- total sale volume
SELECT city.city_id, city.city, SUM (payment.amount)  total_sales
FROM city
JOIN address
USING (city_id)
JOIN customer
USING (address_id)
JOIN payment
USING (customer_id)
GROUP BY city.city_id, city.city
ORDER BY SUM (payment.amount) DESC
LIMIT 5

/* 2F - let's say you want to give discounts as a reward to your loyal customers 
and those who return movies they rented on time.
So, who are your 10 best customers in this respect?*
loyal customer - high rental frequency */
SELECT customer.customer_id, 
				  concat (customer.first_name, ' ', customer.last_name) AS customer_full_name, SUM(payment.amount) AS spending, 
				  date_part('day', return_date - rental_date) AS date_difference, COUNT(rental_id) AS rental_frequency
				  FROM customer
				  JOIN payment 
				  USING (customer_id)
				  JOIN rental
				  USING (rental_id)
				   JOIN inventory
				  USING (inventory_id)
						JOIN film
					   USING (film_id)
				 GROUP BY customer.customer_id,  concat (customer.first_name, ' ', customer.last_name),
				  date_part('day', return_date - rental_date) 
				 ORDER BY date_difference ASC, SUM (payment.amount) DESC, COUNT(rental_id)
				LIMIT 10

/* 2G - What are the 10 best rated movies? Is customer rating somehow correlated with revenue?
        Which actors have acted in most number of the most popular or highest rated movies?
  table - film , payment
Which actors have acted in most number of the most popular or highest rated movies?
*/
--best rated movies and revenue
SELECT film.film_id, MAX(film.rental_rate), SUM (payment.amount) AS revenue
FROM payment 
JOIN rental
USING (rental_id)
JOIN inventory
USING (inventory_id)
JOIN film 
USING (film_id)
GROUP BY film.film_id  
ORDER BY revenue DESC
LIMIT 10 

--actors have acted in most number of the most popular or highest rated movies (CHECK AGAIN)
SELECT actor. actor_id, concat (actor.first_name, ' ', actor.last_name)  actor_full_name, 
 COUNT(rental.rental_id)  frequency_of_rental, film.rental_rate
 from actor
 JOIN film_actor
USING (actor_id)
 JOIN film 
 USING  (film_id)
 JOIN inventory
 USING  (film_id)
 JOIN rental 
 USING  (inventory_id)
 GROUP BY actor. actor_id, concat (actor.first_name, ' ', actor.last_name), rental_rate 
 HAVING rental_rate = '4.99'
 ORDER BY COUNT(rental.rental_id) DESC
   
/*2H-Rentals and hence revenues have been falling behind among young families. 
In order to reverse this, you wish to target all family movies for a promotion.
Identify all movies categorized as family films.
 table film_category, film, category */
SELECT category.name, film.title, film. film_id
  FROM category
  INNER JOIN film_category
  ON category.category_id = film_category.category_id
  INNER JOIN film 
  ON film_category.film_id=film.film_id
  WHERE category.name = 'Family'

/*2I - How much revenue has each store generated so far?
table - store, staff, payment */

SELECT store.store_id, SUM(payment.amount) AS revenue
FROMstore
JOIN staff
USING (store_id)
JOIN payment
USING (staff_id)
GROUP BY  store_id
ORDER BY SUM(payment.amount)


/* 2J - As a data analyst for the DVD rental business, 
you would like to have an easy way of viewing the Top 5 genres by average revenue. 
Write the query to get list of the top 5 genres in average revenue in descending order and create a view for it?
table - category, film-category, film, inventory, rental, payment
name, payment */

CREATE VIEW highest_AVG_revenue AS(SELECT ct.name AS genre, ROUND(avg(payment.amount),2) AS avg_revenue
FROM category ct
INNER JOIN film_category
USING (category_id)
  JOIN inventory
USING (film_id)
JOIN rental
  USING (inventory_id)
JOIN payment 
  USING (rental_id)
GROUP BY genre
ORDER BY avg(payment.amount) DESC
LIMIT 5)
--- return
SELECT * FROM highest_avg_revenue


  












