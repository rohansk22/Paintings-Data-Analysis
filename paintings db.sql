show databases;
use painting;
show tables;

select * from artist
limit 10;

select * from canvas_size
limit 10;

select * from image_link
limit 10;

select * from museum_hours
limit 10;

select * from museum
limit 10;

select * from product_size
limit 10;

/* Work means a painting 
/* Sale price - Selling price
/* regular price - Actual Cost */

select * from subject 
limit 10;

select * from work
limit 10;

/* 10. Identify the museums which are open on both Sunday and Monday. Display
museum name, city */

desc museum;
desc museum_hours;
select * from museum_hours limit 10;


select distinct m1.name, m1.city from museum m1
inner join museum_hours m2 
on m1.museum_id = m2.museum_id 
where m2.day = 'Sunday'
and exists ( select 1 from museum_hours m2 
where m1.museum_id = m2.museum_id 
and m2.day = 'Monday');


select * from museum_hours;

/* 15. Which museum is open for the longest during a day. Dispay museum name, state
and hours open and which day? */ 

select * from (
select m1.name, m1.state, m2.day, str_to_date(open, '%h:%i:%p') as open_time, 
str_to_date(close, '%h:%i:%p') as close_time,
str_to_date(close, '%h:%i:%p') - str_to_date(open, '%h:%i:%p') as duration,
rank() over(order by (str_to_date(close, '%h:%i:%p') - str_to_date(open, '%h:%i:%p')) desc) rnk
from museum_hours m2
join museum m1 on m2.museum_id = m1.museum_id) x 
where x.rnk=1;

/* 1. Fetch all the paintings which are not displayed on any museums? */
show tables;
select w.name from work w
where museum_id is null;

/* 2. Are there museuems without any paintings? */
select name from museum m
where not exists ( select 1 from work w 
where m.museum_id = w.museum_id);

/* 3. How many paintings have an asking price of more than their regular price? */ 
show tables;
select * from product_size
where sale_price > regular_price;

/* 4. Identify the paintings whose asking price is less than 50% of its regular price */ 
select * from product_size 
where sale_price < 0.5*regular_price;

/*  Which canva size costs the most? */ 
select * from canvas_size;
show tables;
select * from product_size;

select c.label, p.size_id, p.sale_price from canvas_size c
inner join product_size p 
on c.size_id = p.size_id
order by sale_price desc
limit 1;

select cs.label as canva, ps.sale_price
	from (select *
		  , rank() over(order by sale_price desc) as rnk 
		  from product_size) ps
	join canvas_size cs on cs.size_id=ps.size_id
	where ps.rnk=1;		
    
/* 6. Delete duplicate records from work, product_size, subject and image_link tables */ 
set sql_safe_updates = false;
CREATE TABLE temp_work AS
SELECT DISTINCT * FROM work;

DELETE FROM work;

insert into work 
select * from temp_work;

select * from work;

/* Create a procedure for the other tables */ 

/* 7.  Identify the museums with invalid city information in the given dataset */ 

select * from museum
where city regexp '^[0-9]';

/*  Museum_Hours table has 1 invalid entry. Identify it and remove it */ 
SELECT MIN(museum_id) AS id
FROM museum_hours
GROUP BY museum_id, day;

select * from museum_hours;

# MIN identifies the minimum 'id' for each combination of museum_id and day. 

set sql_safe_updates = false;
DELETE FROM museum_hours
WHERE museum_id NOT IN (
    SELECT min_id FROM (
        SELECT MIN(museum_id) AS min_id
        FROM museum_hours
        GROUP BY museum_id, day
    ) AS subquery
);

select * from museum_hours;

create TABLE temp_museum_hours AS
SELECT distinct * FROM museum_hours;

DELETE FROM museum_hours;

insert into museum_hours
select * from temp_museum_hours;

select * from museum_hours;

/* 9. Fetch the top 10 most famous painting subject */
select subject, count(subject) as number from subject
group by subject
order by count(subject) desc
limit 10;

/* 11. How many museums are open every single day? */ 
select count(museum_id)
	from (select museum_id, count(1)
		  from museum_hours
		  group by museum_id
		  having count(museum_id) = 7) x;

/* 12. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum? */
select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;
   
/* 13. Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist) */
select a.full_name, count(1) as no_of_paintings,
rank() over( order by count(1) desc) rnk 
from work w 
join artist a on a.artist_id = w.artist_id
group by a.artist_id
limit 5;

/* 14. Display the 3 least popular canva sizes */ 
select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cs.size_id = ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;

/* 16. Which museum has the most no of most popular painting style? */ 
select style, count(style) as count 
from work
group by style
order by count(style) desc;

select * from work;
select * from museum;

select w.style, m.name, count(w.style) as count
from work w 
join museum m 
on w.museum_id = m.museum_id 
group by w.style, w.museum_id 
order by count(w.style) desc;

select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style;

with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;

/* 17. Identify the artists whose paintings are displayed in multiple countries */
select * from museum;
select * from artist;
select * from work;

with cte as 
( select distinct full_name as artist, w.name as painting, m.name as museum, m.country 
from work w
join artist a on a.artist_id = w.artist_id
join museum m on m.museum_id = w.museum_id) 

select artist,count(1) as no_of_countries from cte 
group by artist
having count(1)>1
order by 2 desc;

/* 18. Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. If there are multiple value, seperate them with comma. */
with cte_country as 
			(select country, count(1)
			, rank() over(order by count(1) desc) as rnk
			from museum
			group by country),
		cte_city as
			(select city, count(1)
			, rank() over(order by count(1) desc) as rnk
			from museum
			group by city)
	select group_concat( country.country order by country.country separator ', ') as countries, group_concat(city.city order by city.city separator ', ') as cities
	from cte_country country
	cross join cte_city city
	where country.rnk = 1
	and city.rnk = 1;

/* 19. Identify the artist and the museum where the most expensive and least expensive painting is placed. 
Display the artist name, sale_price, painting name, museum name, museum city and canvas label */ 
with cte as 
		(select *
		, rank() over(order by sale_price desc) as rnk
		, rank() over(order by sale_price ) as rnk_asc
		from product_size )
	select w.name as painting
	, cte.sale_price
	, a.full_name as artist
	, m.name as museum, m.city
	, cz.label as canvas
	from cte
	join work w on w.work_id=cte.work_id
	join museum m on m.museum_id=w.museum_id
	join artist a on a.artist_id=w.artist_id
	join canvas_size cz on cz.size_id = cte.size_id
	where rnk=1 or rnk_asc=1;

/* 20.  Which country has the 5th highest no of paintings? */
	with cte as 
		(select m.country, count(1) as no_of_Paintings
		, rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.country)
	select country, no_of_Paintings
	from cte 
	where rnk=5;
    
    /* 21. Which are the 3 most popular and 3 least popular painting styles? */ 
    
    select style, count(1) as count from work
    group by count(1);
    
    with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style
	, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;

    
/* 22) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality. */
	select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	
