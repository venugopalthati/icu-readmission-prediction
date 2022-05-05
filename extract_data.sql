-- 1. Create research_stays table which will hold icustays required for the research.
drop table research_stays

create table research_stays(subject_id int4, 
hadm_id  int4, 
icustay_id int4, 
intime timestamp,
outtime timestamp,
age int4, 
inunitmortality int,
inhospitalmortality int,
admittime timestamp, 
dischtime timestamp, 
deathtime timestamp,
insurance varchar(255),
ethnicity varchar(255),
gender varchar(10),
dob timestamp,
dod timestamp, los float8, y int default 0, primary key(subject_id, hadm_id,icustay_id))

 
-- 2. Find icustays where age>=18 and patient didn't die in ICU and insert them in research_stays table
insert into research_stays(subject_id,hadm_id,icustay_id,intime,outtime,age,inunitmortality,inhospitalmortality,admittime,dischtime,deathtime,insurance,ethnicity,gender,dob,dod,los)
select subject_id,hadm_id,icustay_id,intime,outtime,age,inunitmortality,inhospitalmortality,admittime,dischtime,deathtime,insurance,ethnicity,gender,dob,dod,los * 24.0 from(
	select (extract(DAY FROM i2.intime  - p2.dob) 
					+ extract(HOUR FROM  i2.intime  - p2.dob) / 24
					+ extract(MINUTE FROM  i2.intime  - p2.dob) / 24 / 60
					) / 365.242 AS age, 
					(case when a2.deathtime is not null and i2.intime  <= a2.deathtime and i2.outtime >= a2.deathtime then 1 else 0 end) +
						(case when a2.deathtime is null and p2.dod is not null and i2.intime  <= p2.dod and i2.outtime >= p2.dod then 1 else 0 end) as inunitmortality,
						(case when a2.deathtime is not null and a2.admittime  <= a2.deathtime and a2.dischtime  >= a2.deathtime then 1 else 0 end) +
						(case when a2.deathtime is null and p2.dod is not null and a2.admittime  <= p2.dod and a2.dischtime >= p2.dod then 1 else 0 end) as inhospitalmortality,
	i2.subject_id, i2.hadm_id, i2.icustay_id, i2.intime, i2.outtime, i2.los, a2.admittime, a2.dischtime,a2.deathtime, a2.insurance,a2.ethnicity,p2.gender, p2.dob, p2.dod 
	from icustays i2, admissions a2, patients p2 
	where i2.subject_id = a2.subject_id and i2.hadm_id = a2.hadm_id 
	and i2.subject_id = p2.subject_id 
) aa
where age >= 18 and inunitmortality = 0

-- 3. Create icd9_groups table to hold icd9 codes for icustays we found above.
drop table icd9_groups
create table icd9_groups(subject_id int4, 
hadm_id  int4, 
icustay_id int4, 
icd9group varchar(255),
icd9group_n int4,
counts int4)

insert into icd9_groups
select subject_id, hadm_id, icustay_id, icd9group,CAST(icd9group as integer) icd9group_n, count(*)   from(
select distinct di.subject_id, di.hadm_id, i3.icustay_id, seq_num, left(di.icd9_code, 3) icd9group, did.short_title, did.long_title  from d_icd_diagnoses did, diagnoses_icd di, research_stays i3  
where did.icd9_code = di.icd9_code 
and i3.subject_id = di.subject_id 
and i3.hadm_id = di.hadm_id 
and left(di.icd9_code, 3) ~ '^[0-9]+$'
union all
-- ICD Procedures
select distinct di.subject_id, di.hadm_id, i3.icustay_id, seq_num, left(di.icd9_code, 3) icd9group, dip.short_title, dip.long_title  from d_icd_procedures dip, diagnoses_icd di, research_stays i3  
where dip.icd9_code = di.icd9_code 
and i3.subject_id = di.subject_id 
and i3.hadm_id = di.hadm_id 
and left(di.icd9_code, 3) ~ '^[0-9]+$'
) aa
group by subject_id, hadm_id, icustay_id, icd9group, CAST(icd9group as integer)

-- 4. Find positive icustays i.e., icustays which requires readmission
with research_stays_maxouttime as (
	select subject_id, hadm_id, max(outtime) maxouttime  from research_stays
	group by subject_id, hadm_id 
	having count(icustay_id) > 1
)

insert into positive_patients(subject_id, hadm_id, icustay_id)
-- Died in ward 2046, actual 1974
select subject_id,hadm_id,icustay_id from research_stays where inunitmortality = 0 and inhospitalmortality = 1


union 

-- Returned to lowerward but returned to ICU again 3145, actual 3555
select rs.subject_id, rs.hadm_id, rs.icustay_id  from research_stays rs,research_stays_maxouttime rsm
	where rs.subject_id = rsm.subject_id 
	and rs.hadm_id = rsm.hadm_id 
	and rs.outtime < rsm.maxouttime 

-- Discharged and returned back in 30 days  2769
union
select subject_id, hadm_id, icustay_id  from (
	select subject_id, hadm_id, icustay_id, admittime, dischtime, DATE_PART('day', lead(admittime) over (partition by subject_id order by dischtime) - dischtime) as readmitdays 
	from research_stays ) aa
where 
readmitdays is not null and readmitdays between 0 and 30
union
-- Died after discharge in 30 days 2533
select subject_id, hadm_id, icustay_id  from research_stays i where dod is not null and DATE_PART('day',dod-dischtime) between 0 and 30 and inunitmortality = 0 and inhospitalmortality = 0

-- 5. Update research_stays table with y value as 1 for icustays from the positive_patients table
update research_stays set y = 1 where
subject_id in (select distinct p.subject_id from positive_patients p ) and
hadm_id in (select distinct p.hadm_id  from positive_patients p ) and 
icustay_id in (select distinct p.icustay_id  from positive_patients p)

-- 6. Update gender to have 2 dimensions
update research_stays  set gender = 'MALE' where gender = 'M';
update research_stays  set gender = 'FEMALE' where gender = 'F';

-- 7. Update ethnicity to have 6 dimensions
update research_stays set ethnicity='ASIA'  where ethnicity like '%ASIA%';
update research_stays set ethnicity='BLACK'  where ethnicity like '%BLACK%';
update research_stays set ethnicity='HISPANIC'  where ethnicity like '%HISPANIC%';
update research_stays set ethnicity='WHITE'  where ethnicity like '%WHITE%';
update research_stays set ethnicity='UNKNOWN'  where ethnicity like '%UNABLE TO OBTAIN%';
update research_stays set ethnicity='UNKNOWN'  where ethnicity like '%PATIENT DECLINED TO ANSWER%';
update research_stays set ethnicity='UNKNOWN'  where ethnicity like '%UNKNOWN%';
update research_stays set ethnicity='OTHER'  where ethnicity not in ('ASIA','BLACK','HISPANIC','WHITE','UNKNOWN');


-- 8. Update insurance to have 5 dimensions
update research_stays set insurance='GOVERNMENT'  where insurance like '%Government%';
update research_stays set insurance='SELFPAY'  where insurance like '%Self Pay%';
update research_stays set insurance='MEDICARE'  where insurance like '%Medicare%';
update research_stays set insurance='PRIVATE'  where insurance like '%Private%';
update research_stays set insurance='MEDICAID'  where insurance like '%Medicaid%';

-- I used DBeaver community edition to extract data as CSV file in the next three steps. https://dbeaver.io/download/

-- 9. Extract chart events. 
select c.icustay_id, c.charttime,  c.value, iivm.level2			
	from chartevents c, item_id_variable_map iivm
	where c.itemid = iivm.itemid and c.icustay_id in (select icustay_id from research_stays rs)
	and c.itemid in (select distinct itemid from mimiciii.item_id_variable_map where level2 in (
			'Capillary refill rate',
			'Diastolic blood pressure',
			'Fraction inspired oxygen',
			'Glascow coma scale eye opening',
			'Glascow coma scale motor response',
			'Glascow coma scale total',
			'Glascow coma scale verbal response',
			'Glucose',
			'Heart Rate',
			'Height',
			'Mean blood pressure',
			'Oxygen saturation',
			'Respiratory rate',
			'Systolic blood pressure',
			'Temperature',
			'Weight',
			'pH'
	))
-- 10. Extract icu stays
select icustay_id, intime, outtime, gender, ethnicity, insurance, age, y  from research_stays
-- 11. Extract icd9 groups
select icustay_id,icd9group,icd9group_n from icd9_groups ig 
	
	
	
	

