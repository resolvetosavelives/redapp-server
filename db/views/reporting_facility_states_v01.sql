WITH
    registered_patients AS (
        SELECT registration_facility_region_id AS region_id, month_date,
               COUNT(*) AS cumulative_registrations,
               COUNT(*) FILTER (WHERE months_since_registration = 0) AS monthly_registrations
        FROM reporting_patient_states
        WHERE hypertension = 'yes'
        GROUP BY 1, 2
    ),

    assigned_patients AS (
        SELECT assigned_facility_region_id AS region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'dead') AS dead,
               COUNT(*) AS cumulative_assigned_patients
        FROM reporting_patient_states
        WHERE hypertension = 'yes'
        GROUP BY 1, 2
    ),

    treatment_outcomes_in_last_3_months AS (
        SELECT assigned_facility_region_id AS region_id, month_date,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'controlled') AS controlled_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'uncontrolled') AS uncontrolled_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'missed_visit') AS missed_visit_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care' AND htn_treatment_outcome_in_last_3_months = 'visited_no_bp') AS visited_no_bp_under_care,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND htn_treatment_outcome_in_last_3_months = 'missed_visit') AS missed_visit_lost_to_follow_up,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up' AND htn_treatment_outcome_in_last_3_months = 'visited_no_bp') AS visited_no_bp_lost_to_follow_up,

               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') AS patients_under_care,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') AS patients_lost_to_follow_up

         FROM reporting_patient_states
        WHERE hypertension = 'yes'
          AND months_since_registration >= 3
        GROUP BY 1, 2
    )

SELECT
cal.*,
rf.*,

registered_patients.cumulative_registrations,
registered_patients.monthly_registrations,
assigned_patients.under_care,
assigned_patients.lost_to_follow_up,
assigned_patients.dead,
assigned_patients.cumulative_assigned_patients,

outcomes.controlled_under_care,
outcomes.uncontrolled_under_care,
outcomes.missed_visit_under_care,
outcomes.visited_no_bp_under_care,

outcomes.missed_visit_lost_to_follow_up,
outcomes.visited_no_bp_lost_to_follow_up,

outcomes.patients_under_care,
outcomes.patients_lost_to_follow_up

-- ensure a row for every facility and month combination
FROM reporting_facilities rf
INNER JOIN reporting_months cal
    ON true
LEFT OUTER JOIN registered_patients
    ON registered_patients.month_date = cal.month_date
    AND registered_patients.region_id = rf.facility_region_id
LEFT OUTER JOIN assigned_patients
    ON assigned_patients.month_date = cal.month_date
    AND assigned_patients.region_id = rf.facility_region_id
LEFT OUTER JOIN treatment_outcomes_in_last_3_months outcomes
    ON outcomes.month_date = cal.month_date
    AND outcomes.region_id = rf.facility_region_id