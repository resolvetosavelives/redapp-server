SELECT COUNT(patients.id),
       registration_facility_id AS facility_id,
       facilities.facility_size AS facility_size,
       facilities.created_at AS facility_created_at,
       facilities.district AS facility_district,
       facilities.zone AS facility_zone,
cast(EXTRACT(MONTH FROM patients.recorded_at) as text) AS month,
cast(EXTRACT(QUARTER FROM patients.recorded_at) as text) AS quarter,
cast(EXTRACT(YEAR FROM patients.recorded_at) as text) AS year
FROM patients
INNER JOIN facilities ON patients.registration_facility_id = facilities.id
WHERE patients.status= 'active' AND patients.deleted_at IS NULL
GROUP BY month, quarter, year, facility_id, facility_size, facility_created_at, facility_district, facility_zone;