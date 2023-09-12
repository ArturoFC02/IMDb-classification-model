-----Proyecto IMDb Taller de Modelacion 2------
-----Arturo Flores Callejas -------------------
-----Construcción de la ABT -------------------

--------------------------------------------------
-- Source: https://datasets.imdbws.com/ 	    --
-- Dictionary: https://www.imdb.com/interfaces/ --
-- Tables: 	data_title_akas   	 				--
--			data_title_basics 					--
--			data_title_crew       				--
--			data_title_principals  				--
--			data_title_ratings  				--
--			data_name_basics     				--
--------------------------------------------------

--------------
--ABT try 0 --
--------------
create table ABT_try0 as 
select x1.tconst, averagerating, numvotes, primarytitle, len_title, originaltitle, isadult, startyear, 
runtimeminutes, cnt_genres, genres1
from rated_movies x1 
join target_title_basics x2 
on x1.tconst = x2.tconst;

select count(*) from abt_try0; ------- 211,462
select * from abt_try0 limit 1000; ----- visualizacion

-------------
-- Conteos --
-------------
create table cnt_target_types as --- cnt types
SELECT tconst, 
COUNT( DISTINCT types ) as cnt_types 
FROM rated_akas where tconst in (select tconst from target)
GROUP BY tconst;

select count(*) from cnt_target_types; ----- 192,002 registros 

create table cnt_target_region as --- cnt region
SELECT tconst, 
COUNT( DISTINCT region ) as cnt_region 
FROM rated_akas where tconst in (select tconst from target)
GROUP BY tconst;

create table cnt_target_titles as --- cnt titulos
SELECT tconst, 
COUNT( DISTINCT title ) as cnt_titles 
FROM rated_akas where tconst in (select tconst from target)
GROUP BY tconst;

create table cnt_crew_movie as --- cnt_crew
select
	tconst,
	CASE WHEN "directors" is null THEN 0 
		ELSE LENGTH("directors")-LENGTH(REPLACE("directors",',',''))+1 END AS cnt_diretors,
	CASE WHEN "writers" is null THEN 0 
		ELSE LENGTH("writers")-LENGTH(REPLACE("writers",',',''))+1 END AS cnt_writers
from data_title_crew
where tconst in (select * from target);

-- Pruebas
select * from rated_akas where tconst = 'tt0035423';
select * from cnt_target_region where tconst = 'tt0035423';
select count(*) from cnt_target_region;

-------- Target Target  target con calificación mayor o igual a 8
create table target_target as 
select tconst, 
CASE WHEN averagerating >= 8 then 1 
	ELSE 0 end as target
from data_title_ratings where tconst in (select * from target);

select count(*) from target_target --- 211,383

--------------
--ABT try 1 -- Con target_target y conteos de region, types, titles 
--------------
create table abt_try1 as select 
x1.tconst, 
primarytitle, 
len_title,
runtimeminutes, 
averagerating,
startYear,
numvotes,
isadult, 
x5.target, 
genres1, 
cnt_types, 
cnt_genres, 
cnt_titles,
cnt_region
from abt_try0 x1 join cnt_target_region x2 on x1.tconst = x2.tconst
join target_target x5 on x1.tconst = x5.tconst
join cnt_target_titles x3 on x1.tconst = x3.tconst
join cnt_target_types x4 on x1.tconst= x4.tconst
;

select count(*) from abt_try1;	-- 210,844 registros

--------------
--ABT try 2 -- Con decades 
--------------

create table abt_try2 as select 
tconst, 
primarytitle, 
len_title,
runtimeminutes, 
averagerating,
numvotes,
isadult, 
target, 
genres1, 
cnt_types, 
cnt_genres, 
cnt_titles,
cnt_region,
CASE 
	WHEN startyear < 1990 then '80s'
	WHEN startyear < 2000 and startyear>=1990 then '90s'
	WHEN startyear < 2010 and startyear>=2000 then '00s'
	WHEN startyear < 2020 and startyear>=2010 then '10s'
	Else '20s'
	END as decade
from abt_try1;
	
select count(distinct abt_try2.decade) from abt_try2;


----------- Crew binary vectors 
create temp table tmp0 as 
select nconst, split_part(primaryProfession,',', 1) as profession, unnest(string_to_array(knownForTitles,',')) as tconst from data_name_basics;

create temp table tmp1 as select * from tmp0 where tconst in (select tconst from movies);

create temp table tmp_director as select  tconst, count(*) as cnt_director from tmp1 where "profession" = 'director' group by 1 order by 1;
create temp table tmp_writer as select  tconst, count(*) as cnt_writer from tmp1 where "profession" = 'writer' group by 1 order by 1;
create temp table tmp_actor as select  tconst, count(*) as cnt_actor from tmp1 where "profession" = 'actor' group by 1 order by 1;
create temp table tmp_actress as select  tconst, count(*) as cnt_actress from tmp1 where "profession" = 'actress' group by 1 order by 1;
create temp table tmp_animation_department as select  tconst, count(*) as cnt_animation_department from tmp1 where "profession" = 'animation_department' group by 1 order by 1;
create temp table tmp_art_department as select  tconst, count(*) as cnt_art_department from tmp1 where "profession" = 'art_department' group by 1 order by 1;
create temp table tmp_assistant_director as select  tconst, count(*) as cnt_assistant_director from tmp1 where "profession" = 'assistant_director' group by 1 order by 1;
create temp table tmp_camera_department as select  tconst, count(*) as cnt_camera_department from tmp1 where "profession" = 'camera_department' group by 1 order by 1;
create temp table tmp_cinematographer as select  tconst, count(*) as cnt_cinematographer from tmp1 where "profession" = 'cinematographer' group by 1 order by 1;
create temp table tmp_composer as select  tconst, count(*) as cnt_composer from tmp1 where "profession" = 'composer' group by 1 order by 1;
create temp table tmp_costume_department as select  tconst, count(*) as cnt_costume_department from tmp1 where "profession" = 'costume_department' group by 1 order by 1;
create temp table tmp_editor as select  tconst, count(*) as cnt_editor from tmp1 where "profession" = 'editor' group by 1 order by 1;
create temp table tmp_editorial_department as select  tconst, count(*) as cnt_editorial_department from tmp1 where "profession" = 'editorial_department' group by 1 order by 1;
create temp table tmp_make_up_department as select  tconst, count(*) as cnt_make_up_department from tmp1 where "profession" = 'make_up_department' group by 1 order by 1;
create temp table tmp_miscellaneous as select  tconst, count(*) as cnt_miscellaneous from tmp1 where "profession" = 'miscellaneous' group by 1 order by 1;
create temp table tmp_music_department as select  tconst, count(*) as cnt_music_department from tmp1 where "profession" = 'music_department' group by 1 order by 1;
create temp table tmp_producer as select  tconst, count(*) as cnt_producer from tmp1 where "profession" = 'producer' group by 1 order by 1;
create temp table tmp_production_manager as select  tconst, count(*) as cnt_production_manager from tmp1 where "profession" = 'production_manager' group by 1 order by 1;
create temp table tmp_sound_department as select  tconst, count(*) as cnt_sound_department from tmp1 where "profession" = 'sound_department' group by 1 order by 1;
create temp table tmp_soundtrack as select  tconst, count(*) as cnt_soundtrack from tmp1 where "profession" = 'soundtrack' group by 1 order by 1;
create temp table tmp_visual_effects as select  tconst, count(*) as cnt_visual_effects from tmp1 where "profession" = 'visual_effects' group by 1 order by 1;

create table ABT_temp1 as 
select x1.tconst, x2.cnt_director, x3.cnt_writer, x4.cnt_actor, x5.cnt_actress, x6.cnt_animation_department, x7.cnt_art_department,
x8.cnt_assistant_director, x9.cnt_camera_department, x10.cnt_cinematographer, x11.cnt_composer, x12.cnt_costume_department, x13.cnt_editor, 
x14.cnt_editorial_department, x15.cnt_make_up_department, x16.cnt_miscellaneous, x17.cnt_music_department, x18.cnt_producer, 
x19.cnt_production_manager, x20.cnt_sound_department, x21.cnt_soundtrack, x22.cnt_visual_effects 
from abt_try2 as x1  
left join tmp_director as x2 on x1.tconst=x2.tconst
left join tmp_writer as x3 on x1.tconst=x3.tconst
left join tmp_actor as x4 on x1.tconst=x4.tconst
left join tmp_actress as x5 on x1.tconst=x5.tconst
left join tmp_animation_department as x6 on x1.tconst=x6.tconst
left join tmp_art_department as x7 on x1.tconst=x7.tconst
left join tmp_assistant_director as x8 on x1.tconst=x8.tconst
left join tmp_camera_department as x9 on x1.tconst=x9.tconst
left join tmp_cinematographer as x10 on x1.tconst=x10.tconst
left join tmp_composer as x11 on x1.tconst=x11.tconst
left join tmp_costume_department as x12 on x1.tconst=x12.tconst
left join tmp_editor as x13 on x1.tconst=x13.tconst
left join tmp_editorial_department as x14 on x1.tconst=x14.tconst
left join tmp_make_up_department as x15 on x1.tconst=x15.tconst
left join tmp_miscellaneous as x16 on x1.tconst=x16.tconst
left join tmp_music_department as x17 on x1.tconst=x17.tconst
left join tmp_producer as x18 on x1.tconst=x18.tconst
left join tmp_production_manager as x19 on x1.tconst=x19.tconst
left join tmp_sound_department as x20 on x1.tconst=x20.tconst
left join tmp_soundtrack as x21 on x1.tconst=x21.tconst
left join tmp_visual_effects as x22 on x1.tconst=x22.tconst;

create table ABT_temp2 as select *,
case when cnt_director is NULL then 0 else 1 end as v1,
case when cnt_writer is NULL then 0 else 1 end as v2,
case when cnt_actor is NULL then 0 else 1 end as v3,
case when cnt_actress is NULL then 0 else 1 end as v4,
case when cnt_animation_department is NULL then 0 else 1 end as v5,
case when cnt_art_department is NULL then 0 else 1 end as v6,
case when cnt_assistant_director is NULL then 0 else 1 end as v7,
case when cnt_camera_department is NULL then 0 else 1 end as v8,
case when cnt_cinematographer is NULL then 0 else 1 end as v9,
case when cnt_composer is NULL then 0 else 1 end as v10,
case when cnt_costume_department is NULL then 0 else 1 end as v11,
case when cnt_editor is NULL then 0 else 1 end as v12,
case when cnt_editorial_department is NULL then 0 else 1 end as v13,
case when cnt_make_up_department is NULL then 0 else 1 end as v14,
case when cnt_miscellaneous is NULL then 0 else 1 end as v15,
case when cnt_music_department is NULL then 0 else 1 end as v16,
case when cnt_producer is NULL then 0 else 1 end as v17,
case when cnt_production_manager is NULL then 0 else 1 end as v18,
case when cnt_sound_department is NULL then 0 else 1 end as v19,
case when cnt_soundtrack is NULL then 0 else 1 end as v20,
case when cnt_visual_effects is NULL then 0 else 1 end as v21
from ABT_temp1;

--------------
--ABT try 3 -- Con crew vectors principalCrew, departments y othercrew
--------------

create table ABT_temp3 as
select tconst,
concat(v1,v2,v3,v4,v9,v12,v17) as principalCrew,
concat(v5,v6,v8,v11,v13,v14,v16,v19) as departments,
concat(v7,v10,v15,v18,v20,v21) as otherCrew
from ABT_temp2;

drop table ABT_temp1;
drop table ABT_temp2;  

create table ABT_try3 as
select x1.tconst, x1.primarytitle, x1.isadult, x1.decade, x1.runtimeminutes, x1.numvotes, x1.genres1, x1.cnt_genres,
x1.cnt_types, x1.cnt_region, x1.cnt_titles, x1.target, 
x2.principalCrew, x2.departments, x2.otherCrew from abt_try2 as x1 left join ABT_temp3 as x2 on x1.tconst=x2.tconst;

--- cnt_cont y continent code
create temp table akas_corr as
select *,
case when region = 'BUM' then 'BM'
when region = 'CSH' then 'CH'
when region = 'CSX' then 'CX'
when region = 'SUH' then 'SH'
when region = 'XAS' then'AS'
when region = 'XAU' then 'AU'
when region = 'XNA' then 'NA'
when region = 'XSA' then 'SA'
when region in ('DDD','XEU','XKO','XKV','XPI','XWG','XWW','XYU','YUC','ZRC') then NULL
else region end
as correct_region
from data_title_akas where data_title_akas.tconst in (select tconst from movies);

create table akas_cont as
select a.*, b.continent_code from akas_corr as a
left join (select code, continent_code from countries) as b  
on a.region = b.code;

create table cont_akas_tmp001 as 
select tconst, continent_code, count(*) as cnt
from akas_cont where correct_region is not NULL or correct_region != '\N' 
group by 1,2 order by 1,3 desc;

---Continente principal (continent code)
create table cont_akas_tmp002 as
select tconst, codes[1] as continent_code from (
select tconst, array_agg(continent_code) as codes
from cont_akas_tmp001
group by tconst
order by tconst) as foo
order by tconst;

-- cnt_cont
create table cont_akas_tmp003 as select tconst, count(*) as cnt_cont
from cont_akas_tmp001 group by tconst order by tconst;

create table cont_akas as   
select a.*, b.continent_code from cont_akas_tmp003 
as a left join cont_akas_tmp002 as b on a.tconst = b.tconst;

--------------
--ABT try 4 -- Con cnt_continents y continent_code
--------------
create table ABT_try4 as 
select a.*, b.cnt_cont as cnt_continents, b.continent_code from
ABT_try3 as a left join cont_akas as b on a.tconst=b.tconst;


----TOP director  
create table base as
select tconst, case when averagerating < 8.0 then '0' else '1' end as target,
averagerating from rated_movies;

create table title_crew_movie as
select tconst, unnest(string_to_array("directors",',')) as director, unnest(string_to_array("writers",',')) as writer
from data_title_crews where tconst in (select tconst from movies);

create table topDirectors as   /** 1,771 with Rating >= 8.0 **/
select a.director, count(*) as cnt_movies, avg(b.averageRating) as avgRating
from title_crew_movie as a inner join base as b
on a.tconst = b.tconst 
where director is not null
group by 1
having avg(b.averageRating) >= 8.0 and count(*) > 1
order by 3 desc;

create table title_topDirectors as
select distinct tconst, case when director in (select director from topDirectors) then '1' else '0' end as TopDirector
from title_crew_movie order by 1, 2;

--------------
--ABT try 5 -- Con topdirector
--------------
create table ABT_try5 as
select a.*, b.topdirector from ABT_try4 as a inner join title_topDirectors as b on a.tconst=b.tconst;


--- Tablas auxiliares para Top Actor
create table nconst_tconst as
select
	nconst,
	case when data_name_basics.deathYear is null then '0'
		else '1' end as isDeath,
	split_part(data_name_basics.primaryProfession, ',' , 1) as Profession,
	unnest(string_to_array(data_name_basics.knownForTitles,',')) as tconst
from data_name_basics;

create table nconst_tconst_movie as
select	*
from nconst_tconst
where tconst in (select * from target);

----TOP actor

create table topActor as  
select a.nconst, avg(b.averageRating) as avgRating, count(*) as cnt_movies
from nconst_tconst_movie as a inner join base as b
on a.tconst = b.tconst
where profession = 'actor'
group by 1
having avg(b.averageRating) >= 8.0 and count(*) > 1
order by 2 desc;

create table title_topActor as  
select distinct tconst, '1' as TopActor
from nconst_tconst_movie
where nconst in (select nconst from topActor);

---------------
-- ABT try 6 --
---------------
create table ABT_try6 as
select a.*, b.topactor as topactor_1 from ABT_try5 as a left join title_topActor as b on a.tconst=b.tconst;

create table ABT as
select *, case when topactor_1 is null then '0' else '1' end as topactor from ABT_try6;
alter table ABT drop column topactor_1;

---TOP Actress

create table topActress as  
select a.nconst, avg(b.averageRating) as avgRating, count(*) as cnt_movies
from nconst_tconst_movie as a inner join base as b
on a.tconst = b.tconst
where profession = 'actress'
group by 1
having avg(b.averageRating) >= 8.0 and count(*) > 1
order by 2 desc;

create table title_topActress as  
select distinct tconst, '1' as TopActress
from nconst_tconst_movie
where nconst in (select nconst from topActress);

---------------
-- ABT try 6.1 --
---------------
create table ABT_try6_1 as
select a.*, b.topactress as topactress_1 from ABT as a left join title_topActress as b on a.tconst=b.tconst;

---------------
-- ABT 2 --
---------------
create table ABT_2 as
select *, case when topactress_1 is null then '0' else '1' end as topactress from ABT_try6_1;

alter table ABT_2 drop column topactress_1;

---------------
-- ABT FINAL (ABT_2) --
---------------
select * from ABT_2;





