WITH latest_bp_per_patient_per_day AS
 (SELECT DISTINCT ON (facility_id, blood_pressures.patient_id, year, day)
      blood_pressures.id AS bp_id,
      blood_pressures.facility_id AS facility_id,
      cast(EXTRACT(DOY FROM blood_pressures.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS day,
      cast(EXTRACT(MONTH FROM blood_pressures.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS month,
      cast(EXTRACT(QUARTER FROM blood_pressures.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS quarter,
      cast(EXTRACT(YEAR FROM blood_pressures.recorded_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE'))) as text) AS year
  FROM blood_pressures
  INNER JOIN medical_histories ON (blood_pressures.patient_id = medical_histories.patient_id AND medical_histories.hypertension = 'yes')
  WHERE blood_pressures.deleted_at IS NULL
  ORDER BY facility_id, blood_pressures.patient_id, year, day, blood_pressures.recorded_at DESC, bp_id)
SELECT COUNT(bp_id) AS bp_count,
       facilities.id AS facility_id,
       facilities.deleted_at at time zone 'utc' at time zone (SELECT current_setting('TIMEZONE')) AS deleted_at,
       day, month, quarter, year
FROM latest_bp_per_patient_per_day
INNER JOIN facilities ON facilities.id = latest_bp_per_patient_per_day.facility_id
GROUP BY day, month, quarter, year, facilities.deleted_at, facilities.id;
