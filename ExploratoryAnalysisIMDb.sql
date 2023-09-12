-----Proyecto IMDb Taller de Modelacion 2------
-----Arturo Flores Callejas -------------------
-----Analisis exploratorio --------------------

--------------------------------------------------
-- Source: https://datasets.imdbws.com/ 	    --
-- Dictionary: https://www.imdb.com/interfaces/ --
-- Tables: 	data_title_akas   	 				--
--			data_title_basics 					--
--			data_title_crew       				--
--			data_title_principals  				--
--			data_title_ratings  				--s
--			data_name_basics     				--
--------------------------------------------------

--------------Tablas creadas -----------------------------------------------------------------------------------
--       	target      Contiene solo las peliculas con rating, entre 1980 y 2022
--       	target_title_basics     Tabla data_title_basics con conteo de generos y generos split
--          rated_movies        Peliculas con rating
--          rated_crew      Datos de crew solo para peliculas con rating
--          directors       Todos los directores por pelciula con rating
--          writers     Todos los directores por pelciula con rating
--          rated_akas      Datos de akas para peliculas con rating
--          name_basics_split       Datos de name_basics con profesión y knowfortitles separados por columnas
----------------------------------------------------------------------------------------------------------------

--------------------------------------
--  Se cargan las tablas originales --
--------------------------------------

create table data_title_basics(
	tconst	character varying(20),
	titleType	character varying(20),
	primaryTitle	character varying(500),
	originalTitle	character varying(500),
	isAdult	character varying(10),
	startYear	integer,
	endYear	character varying(20),
	runtimeMinutes	integer,
	genres character varying(400)
);

--- 
create table data_title_ratings 
(
	tconst	character varying(20),
	averageRating	float,
	numVotes	integer
);

--- 
create table data_title_crews(
	tconst	character varying(20),
	directors	character varying(20000),
	writers	character varying(20000)
);

--- 
create table data_name_basics(
	nconst	character varying(20),
	primaryName character varying(1000),
	birthYear	bigint,
	deathYear	bigint,
	primaryProfession	character varying(1000),
	knownForTitles	character varying(1000)
);

--- 
create table data_title_akas(
	tconst 	character varying(20),
	ordering integer,
	title	character varying(1000),
	region	character varying(20),
	language	character varying(100),
	types	character varying(100),
	attributes	character varying(100),
	isOriginalTitle integer
);

create table data_title_principals(
	tconst character varying(20), 
	ordering integer, 
	nconst character varying(30),
	category character varying(1000), 
	job character varying(1000),
	characters character varying(5000) 
);
	
CREATE TABLE countries ( -- later insert info
  code CHAR(2),
  name VARCHAR(255),
  full_name VARCHAR(255),
  iso3 CHAR(3),
  number CHAR(3),
  continent_code CHAR(2)
);

------------------------------------
-- Exploración data_title_basics --
------------------------------------

--- Numero de registros
select count(1) from data_title_basics; --9,694,044 rows

--- Conteo de registros de cada tipo --- 638,810 movies
select 	titletype, 
	    count(1) as cnt 
from data_title_basics
group by 1 	order by 1 ;

--- Conteo de registros de peliculas por cada año
select 	startYear, 
	    count(1) as cnt 
from data_title_basics
where titleType = 'movie'	group by 1 	order by 1 ;

--- Conteo de número máximo de generos por pelicula --- 3 genres
select max(tb.Cnt) 
from (
select CASE 
WHEN "genres" = '' THEN 0 
ELSE LENGTH("genres")-LENGTH(REPLACE("genres",',',''))+1 END AS cnt from public.data_title_basics) as tb; 

--- Se crea la población objetivo TARGET
create table target as
select tconst from public.data_title_ratings
where tconst in 
(select tconst from public.data_title_basics where data_title_basics.startyear >= '1980' 
 	and data_title_basics.startyear <= '2022' and data_title_basics.titletype = 'movie');

select count(*) from target; -- 211,383 registros objetivo

--- Info title basics restringida al target
create table public.target_title_basics as
select
	"tconst",
	public.data_title_basics.primaryTitle,
	length(public.data_title_basics.primaryTitle) as len_title,
	public.data_title_basics.originalTitle,
	public.data_title_basics.isAdult,
	public.data_title_basics.startYear :: Numeric,
	public.data_title_basics.runtimeMinutes,
	CASE WHEN "genres" = '' THEN 0 
		 ELSE LENGTH("genres")-LENGTH(REPLACE("genres",',',''))+1 END AS cnt_genres,
	split_part("genres", ',' , 1) as genres1,
	split_part("genres", ',' , 2) as genres2,
	split_part("genres", ',' , 3) as genres3
from public.data_title_basics
where "tconst" in (select tconst from public.target);

------------------------------------------
-- Exploración data_title_ratings       --
------------------------------------------

--- Registros tipo movie con rating

create table movies as --- registros tipo movie
select *
from data_title_basics
where titleType='movie' and tconst in (select tconst from data_title_ratings);

create table rated_movies as 
select *
from data_title_ratings
where tconst in (select tconst from movies);

----------------------------------
-- Exploración data_title_crews --
----------------------------------

--- Registros crew con rating
create table rated_crew as 
select * 
from data_title_crews 
where tconst in (select tconst from rated_movies);


---Se crea tabla directors
create table directors as
select tconst, unnest(string_to_array(directors,',')) as director
from rated_crew
where directors != '' or directors = NULL
and tconst in (select tconst from data_title_ratings)
;

---Se crea tabla writers 
create table writers as
select tconst, unnest(string_to_array(writers,',')) as writers
from rated_crew
where writers != '' or writers = NULL
and tconst in (select tconst from data_title_ratings)
;

------------------------------------
-- Exploración data_title_akas    --
------------------------------------

--- Registros akas con rating ---2,107,632 registros
create table rated_akas as 
select * from data_title_akas where tconst in (select tconst from rated_movies); 

select count(*) from rated_akas;

---Conteo de languages por película
select tconst, count(distinct language) from rated_akas group by tconst order by count desc;

---Conteo de tipos por película
select tconst, count(distinct types) from rated_akas group by tconst order by count desc;

--- Peliculas con titulo original
select * from rated_akas where isoriginaltitle = 1;

--- Inner join by tconst entre rated_movies y rated_akas añadiendo titulos originales.
select * from rated_movies 
as x1 inner join (select * from rated_akas where isoriginaltitle=1) as x2 on x1.tconst = x2.tconst;


-------------------------------------------
-- Exploración data_title_name_basics    --
-------------------------------------------

--- Max numero knownForTitles = 6 de tabla data_name_basics
select case when knownForTitles is NULL or knownForTitles='' then 0
else length(knownForTitles)-length(replace(knownForTitles, ',', '')) + 1 end as cont_know
from data_name_basics group by cont_know order by cont_know desc;

--- Tabla con profesiones y titulos seprados por columnas
create table name_basics_split as
select 
	nconst,
	primaryName,
	birthYear,
	deathYear,
	split_part(primaryProfession, ',' , 1) as Profession1,
	split_part(primaryProfession, ',' , 2) as Profession2,
	split_part(primaryProfession, ',' , 3) as Profession3,
	split_part(knownForTitles, ',' , 1) as knownForTitles1,
	split_part(knownForTitles, ',' , 2) as knownForTitles2,
	split_part(knownForTitles, ',' , 3) as knownForTitles3,
	split_part(knownForTitles, ',' , 4) as knownForTitles4,
	split_part(knownForTitles, ',' , 5) as knownForTitles5,
	split_part(knownForTitles, ',' , 6) as knownForTitles6
from data_name_basics;

-------------------
-- Valores nulos --
-------------------

--Valores nulos en columna runtimeminutes-- 27,401 de 286,307
select count(1) as count_null, (select count(1) from movies) as countfinal
from movies
where runtimeminutes is NULL 

--Valores nulos en columna numVotes-- 0 de 286,307
select count(1) as count_null, (select count(1) from rated_movies) as countfinal
from rated_movies
where numvotes is NULL 


--Valores nulos en columna startyear-- 55 de 286,307
select count(1) as count_null, (select count(1) from movies) as countfinal
from movies
where startyear is NULL

--Valores nulos en columna endyear-- 286,307 de 286,307
select count(1) as count_null, (select count(1) from movies) as countfinal
from movies
where endyear is NULL

--Valores nulos en columna genres-- 9,792 de 286,307
select count(1) as count_null, (select count(1) from movies) as countfinal
from movies
where genres is NULL

--Valores nulos en columna isadult-- 0 de 286,307
select count(1) as count_null, (select count(1) from movies) as countfinal
from movies
where isadult is NULL

--Valores nulos en columna types-- 0 de 286,307
select count(1) as count_null, (select count(1) from rated_akas) as countfinal
from rated_akas
where types is NULL

--Valores nulos en columna averagerating-- 0 de 286,307
select count(1) as count_null, (select count(1) from rated_movies) as countfinal
from rated_movies
where averagerating is NULL

--Valores nulos en columna directors-- 3,287 de 286,307
select count(1) as count_null, (select count(1) from rated_crew) as countfinal
from rated_crew
where directors is NULL

--Valores nulos en columna directors-- 35,345 de 286,307
select count(1) as count_null, (select count(1) from rated_crew) as countfinal
from rated_crew
where writers is NULL

--Valores nulos en columna directors-- 35,345 de 286,307
select count(1) as count_null, (select count(1) from rated_crew) as countfinal
from rated_crew
where writers is NULL

--Valores nulos en columna region-- 292983 de 2107632
select count(1) as count_null, (select count(1) from rated_akas) as countfinal
from rated_akas
where region is NULL

--Valores nulos en columna language-- 292983 de 2107632
select count(1) as count_null, (select count(1) from rated_akas) as countfinal
from rated_akas
where language is NULL

--Valores nulos en columna primaryTitle-- 0 de 2107632
select count(1) as count_null, (select count(1) from target_title_basics) as countfinal
from target_title_basics
where primaryTitle is NULL
