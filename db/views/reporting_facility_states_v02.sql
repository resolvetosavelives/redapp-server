WITH
    registered_patients AS (
        SELECT registration_facility_region_id as region_id, month_date,
               COUNT(*) as cumulative_registrations,
               COUNT(*) FILTER (WHERE months_since_registration = 0) as monthly_registrations
        FROM reporting_patient_states
        WHERE hypertension = 'yes'
        GROUP BY 1, 2
    ),

    assigned_patients AS (
        SELECT assigned_facility_region_id as region_id, month_date,
               COUNT(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') as under_care,
               count(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') as lost_to_follow_up,
               count(distinct(patient_id)) FILTER (WHERE htn_care_state = 'dead') as dead,
               COUNT(*) as assigned_patients
        FROM reporting_patient_states
        WHERE hypertension = 'yes'
        GROUP BY 1, 2
    ),

    treatment_outcomes_in_last_3_months AS (
        SELECT assigned_facility_region_id as region_id, month_date,

               count(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'controlled' AND htn_care_state = 'under_care') as controlled_under_care,
               count(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'controlled' AND htn_care_state = 'lost_to_follow_up') as controlled_lost_to_follow_up,

               count(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'uncontrolled' AND htn_care_state = 'under_care') as uncontrolled_under_care,
               count(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'uncontrolled' AND htn_care_state = 'lost_to_follow_up') as uncontrolled_lost_to_follow_up,

               count(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'missed_visit' AND htn_care_state = 'under_care') as missed_visit_under_care,
               count(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'missed_visit' AND htn_care_state = 'lost_to_follow_up') as missed_visit_lost_to_follow_up,

               count(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'visited_no_bp' AND htn_care_state = 'under_care') as visited_no_bp_under_care,
               count(distinct(patient_id)) FILTER (WHERE htn_treatment_outcome_in_last_3_months = 'visited_no_bp' AND htn_care_state = 'lost_to_follow_up') as visited_no_bp_lost_to_follow_up,

               count(distinct(patient_id)) FILTER (WHERE htn_care_state = 'under_care') as patients_under_care,
               count(distinct(patient_id)) FILTER (WHERE htn_care_state = 'lost_to_follow_up') as patients_lost_to_follow_up
         FROM reporting_patient_states
        WHERE hypertension = 'yes'
          AND months_since_registration >= 3
        GROUP BY 1, 2
    )

SELECT
    cal.*,
    rf.*,

    rp.cumulative_registrations,
    rp.monthly_registrations,
    ap.under_care,
    ap.lost_to_follow_up,
    ap.dead,
    ap.assigned_patients,

    tout.controlled_under_care,
    tout.controlled_lost_to_follow_up,
    tout.uncontrolled_under_care,
    tout.uncontrolled_lost_to_follow_up,
    tout.missed_visit_under_care,
    tout.missed_visit_lost_to_follow_up,
    tout.visited_no_bp_under_care,
    tout.visited_no_bp_lost_to_follow_up,
    tout.patients_under_care,
    tout.patients_lost_to_follow_up

    FROM registered_patients rp
    LEFT OUTER JOIN assigned_patients ap
        ON rp.region_id = ap.region_id
        AND rp.month_date = ap.month_date
    LEFT OUTER JOIN treatment_outcomes_in_last_3_months tout
        ON rp.region_id = tout.region_id
        AND rp.month_date = tout.month_date
    INNER JOIN reporting_facilities rf
        ON rp.region_id = rf.facility_region_id
    INNER JOIN reporting_months cal
        ON rp.month_date = cal.month_date
