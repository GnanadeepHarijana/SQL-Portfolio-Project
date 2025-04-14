-- Select the database to use
use projects1;

-- Retrieve all records from the 'human' table
select * from human;

-- Show the structure (columns) of the 'human' table
show columns from human;

-- Rename the column 'ï»¿id' to 'ID' with type varchar(20)
alter table human
change column ï»¿id ID varchar(20);

-- Describe the structure of the 'human' table
describe human;

-- Select only the 'birthdate' column from the 'human' table
select `birthdate` from human;

-- Disable safe update mode to allow updates without WHERE clause or KEY constraints
set sql_safe_updates = 0;

-- Update 'birthdate' to a standardized date format (YYYY-MM-DD)
update human
set `birthdate` = case
     when `birthdate` like '%/%' then date_format(str_to_date(`birthdate`, '%m/%d/%Y'), '%Y-%m-%d')
     when `birthdate` like '%-%' then date_format(str_to_date(`birthdate`, '%m-%d-%Y'), '%Y-%m-%d')
     Else null
END;

-- Modify the 'birthdate' column to be of DATE type
alter table human
modify column `birthdate` date;

-- Standardize 'hire_date' format in the same way as 'birthdate'
update human
set `hire_date` = case
     when `hire_date` like '%/%' then date_format(str_to_date(`hire_date`, '%m/%d/%Y'), '%Y-%m-%d')
     when `hire_date` like '%-%' then date_format(str_to_date(`hire_date`, '%m-%d-%Y'), '%Y-%m-%d')
     Else null
END;

-- Modify the 'hire_date' column to be of DATE type
alter table human
modify column `hire_date` date;

-- Select only the 'termdate' column from the 'human' table
select `termdate` from human;

-- Convert 'termdate' from datetime string to DATE format where applicable
update human
set `termdate` = date(str_to_date(`termdate`, '%Y-%m-%d %H:%i:%s UTC'))
where `termdate` is not null and `termdate`!= '';

-- Replace NULL or empty 'termdate' values with '0000-00-00'
update human
set `termdate` = '0000-00-00'
where `termdate` is null or `termdate`= '';

-- Set SQL mode to allow '0000-00-00' as a valid date
SET sql_mode = 'ALLOW_INVALID_DATES';

-- Modify the 'termdate' column to be of DATE type
alter table human
modify column `termdate` date;

-- Add a new column 'age' of type integer
Alter table human add column age int;

-- Update 'age' column by calculating age from 'birthdate' to current date
update human
set age = timestampdiff(year, `birthdate`, curdate());

-- Select the 'age' column from the 'human' table
select `age` from human;

-- Count total number of records in the 'human' table
select count(*) from human;

-- 1. Gender breakdown of currently employed staff
select `gender`, count(*) as `gender_count`
from human
where (STR_TO_DATE(`termdate`, '%Y-%m-%d') IS NULL or `termdate` > current_date())
group by `gender`
order by  `gender_count` Desc;

-- 2. Race breakdown of currently employed staff
select `race`, count(*) as `race_count`
from human
where (STR_TO_DATE(`termdate`, '%Y-%m-%d') IS NULL or `termdate` > current_date())
group by `race`
order by `race_count` desc;

--  Age range (youngest and oldest) of all employees
select min(age) as Youngest, max(age) as oldest from human;

-- 3. Age distribution grouped by defined age brackets and gender
select 
	case
		when `age` >= 18 and `age` <= 25 then '18-25'
        when `age` >= 26 and `age` <= 35 then '26-35'
        when `age` >= 36 and `age` <= 45 then '36-45'
        when `age` >= 46 and `age` <= 59 then '46-59'
	END AS `age_group`,
    count(*) as `age_count`, `gender`
from human
where (STR_TO_DATE(`termdate`, '%Y-%m-%d') IS NULL or `termdate` > current_date())
group by `age_group`, `gender`
order by `age_count`, `gender`;

-- 4. Count of employees working at headquarters vs remote locations
select `location`, count(*) as `location_count`
from human
where (STR_TO_DATE(`termdate`, '%Y-%m-%d') IS NULL or `termdate` > current_date())
group by `location`
order by  `location_count`;

-- 5. Average length of employment (in years) for terminated employees
select 
 round(avg(datediff(`termdate`, `hire_date`))/ 365, 2) as Avg_length_emp
from human
where (STR_TO_DATE(`termdate`, '%Y-%m-%d') IS not NULL or `termdate` < current_date());

-- 6. Gender distribution across departments for current employees
select `department`, `gender`, count(*) as `distribution`
from human
where (STR_TO_DATE(`termdate`, '%Y-%m-%d') IS NULL or `termdate` > current_date())
group by `department`,`gender`
order by `department`;

-- 7. Departments with highest turnover rates
select `department`, `total_count`, `terminated_count`, `terminated_count`/`total_count` as `termination_rate`
from(
	select `department`, count(*) as `total_count`,
    sum(case when (STR_TO_DATE(`termdate`, '%Y-%m-%d') IS not null) or (STR_TO_DATE(`termdate`, '%Y-%m-%d') <= curdate()) then 1 else 0 end) as `terminated_count`
    from human
    group by `department`
    ) as sub_query
order by `termination_rate` desc;

-- 8. Yearly hiring vs termination trends and net change in headcount
select `year` , `hires`, `terminations` , `hires`-`terminations` as `net_change`, 
        round((`hires`-`terminations`)/ `hires` * 100,2) as `net_change_percent`
from(
	select
		year(`hire_date`) as `year`,
        count(*) as `hires`,
        sum(case when (STR_TO_DATE(`termdate`, '%Y-%m-%d') IS not null) or (STR_TO_DATE(`termdate`, '%Y-%m-%d') <= curdate()) then 1 else 0 end) as `terminations`
		from human
        group by(`year`)
        ) as sub_query
order by `year`;
