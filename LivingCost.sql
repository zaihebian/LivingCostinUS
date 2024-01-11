--The data sets include two Files: one containing data on living costs in different counties in America,
--and the other containing county information.

-- Check the tables

select top 10 *
from cost_of_living_us

select top 10 *
from county_info

-- Calculate the pearson correlation coeficient between housing_cost and total_cost
Select (Avg(housing_cost * total_cost) - Avg(housing_cost) * Avg(total_cost)) / (StDevP(housing_cost) * StDevP(total_cost)) as correlation
from cost_of_living_us

-- Calculate the pearson correlation coeficient between population and total_cost
Select (Avg(b.total_pop_20 * a.total_cost) - Avg(b.total_pop_20) * Avg(a.total_cost)) / (StDevP(b.total_pop_20) * StDevP(a.total_cost)) as correlation
from cost_of_living_us a
left join county_info b
on a.county = b.county

-- Add new columns to indicate family sizes and child numbers
alter table cost_of_living_us
add family_size int Null, child_number int null;

update cost_of_living_us
set family_size = convert(int,substring(family_member_count,1,1)) +convert(int,substring(family_member_count,3,1))

update cost_of_living_us
set child_number = convert(int,substring(family_member_count,3,1))

-- ==============================================================================================================
-- Check the living costs for different family structures
select family_member_count,avg(total_cost) as AverageTotalCost,avg(housing_cost) as AverageHousingCost,
       avg(childcare_cost) as AverageChildcareCost
from cost_of_living_us
group by family_member_count
order by AverageTotalCost desc

-- Check the tax rate for families with different numbers of children
select child_number,round(avg(taxes/total_cost*100),2)
from cost_of_living_us
group by child_number
order by 1


-- Check the living cost of households without children in counties that are metropolitan and have a population larger than 1,000,000.
select a.state,a.county,a.family_member_count,a.housing_cost, a.food_cost,a.transportation_cost,a.healthcare_cost,a.other_necessities_cost,a.total_cost
from cost_of_living_us a
left join county_info b
on a.county = b.county
where a.isMetro = 1 and b.total_pop_20>1000000 and a.family_member_count like '%0c'
order by 1,2

-- Check the max living costs for  a 2p2c(2 parents and 2 children) family in different states,only consider states with 
-- more than 5 counties
select state,count(county) as county_number_included,max(total_cost) as MaxCost
from cost_of_living_us
where family_member_count like '2p2c'
group by state
having count(county)>5
order by MaxCost desc

-- Check the gap between living costs for  a 2p2c family in the most  and the least expensive state
with cte (state,county_number_included,MaxCost)
as
	(select state,count(county) as county_number_included,max(total_cost) as MaxCost
	from cost_of_living_us
	where family_member_count like '2p2c'
	group by state
	having count(county)>5)
select max(maxcost) - min(maxcost) as CostGap
from cte

-- Find the most cost-friendly place for a single person across the country
with Cte_average (state,county,family_member_count,total_cost,Average_cost)
as
(
select state,county,family_member_count,total_cost, avg(total_cost) over(partition by family_member_count) as Average_cost
from cost_of_living_us
)
select top 3 state,county,family_member_count,total_cost/Average_cost as ratio
from Cte_average
where family_member_count = '1p0c'
order by ratio