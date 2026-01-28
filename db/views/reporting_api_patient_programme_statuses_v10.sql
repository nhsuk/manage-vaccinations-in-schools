WITH vaccination_summary AS (
  SELECT
    vr.patient_id,
    vr.programme_type,
    vr_tl.team_id,
    vr_tl.academic_year,
    COUNT(*) FILTER (WHERE vr.outcome = 0) AS sais_vaccinations_count,
    BOOL_OR(vr.outcome = 0) AS has_sais_vaccination,
    MAX(vr.performed_at_date) FILTER (WHERE vr.outcome = 0) AS most_recent_vaccination,
    BOOL_OR(vr.outcome = 0 AND vr.delivery_method = 2) AS has_nasal,
    BOOL_OR(vr.outcome = 0 AND vr.delivery_method IN (0, 1)) AS has_injection
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  INNER JOIN team_locations vr_tl ON vr_tl.id = vr_s.team_location_id
  WHERE vr.discarded_at IS NULL
    -- For Td/IPV, only count dose 5 or unknown dose (recorded in service)
    AND (
      vr.programme_type != 'td_ipv'
      OR vr.dose_sequence = 5
      OR vr.dose_sequence IS NULL
    )
  GROUP BY vr.patient_id, vr.programme_type, vr_tl.team_id, vr_tl.academic_year
),
all_vaccinations_by_year AS (
  SELECT
    vr.patient_id,
    vr.programme_type,
    vr_tl.academic_year,
    vr_tl.team_id,
    vr.outcome,
    vr.source
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  INNER JOIN team_locations vr_tl ON vr_tl.id = vr_s.team_location_id
  WHERE vr.discarded_at IS NULL
    -- For Td/IPV, only count dose 5 or unknown dose (recorded in service)
    AND (
      vr.programme_type != 'td_ipv'
      OR vr.dose_sequence = 5
      OR vr.dose_sequence IS NULL
    )

  UNION ALL

  SELECT
    vr.patient_id,
    vr.programme_type,
    CASE
      WHEN EXTRACT(MONTH FROM (vr.performed_at_date)) >= 9
      THEN EXTRACT(YEAR FROM (vr.performed_at_date))::integer
      ELSE EXTRACT(YEAR FROM (vr.performed_at_date))::integer - 1
    END AS academic_year,
    NULL AS team_id,
    vr.outcome,
    vr.source
  FROM vaccination_records vr
  WHERE vr.discarded_at IS NULL
    AND vr.source IN (1, 2)
    AND vr.session_id IS NULL
    -- For Td/IPV without session, only dose 5 counts (not recorded in service)
    AND (
      vr.programme_type != 'td_ipv'
      OR vr.dose_sequence = 5
    )
),
base_data AS (
  SELECT
    -- Unique identifier for concurrent refresh support
    CONCAT(p.id, '-', s_programme_type::TEXT, '-', t.id, '-', tl.academic_year) AS id,
  -- Patient identifiers (minimal)
  p.id AS patient_id,
  CASE p.gender_code
    WHEN 0 THEN 'not known'
    WHEN 1 THEN 'male'
    WHEN 2 THEN 'female'
    WHEN 9 THEN 'not specified'
    ELSE NULL
  END AS patient_gender,
  -- Programme info
  s_programme_type AS programme_type,
  tl.academic_year,
  -- Team info
  t.id AS team_id,
  t.name AS team_name,
  -- Archive/deceased status - check if there's an archive reason for this patient-team pair or patient is deceased
  (ar.patient_id IS NOT NULL OR p.date_of_death IS NOT NULL) AS is_archived,
  -- Patient location info (minimal for filtering)
  COALESCE(school_la.mhclg_code, '') AS patient_school_local_authority_code,
  COALESCE(school_la.mhclg_code, '') AS patient_local_authority_code,
  school.id AS patient_school_id,
  school.urn AS patient_school_urn,
  CASE
    WHEN school.name IS NOT NULL THEN school.name
    WHEN p.home_educated = true THEN 'Home educated'
    ELSE 'Unknown'
  END AS patient_school_name,
  CASE
    WHEN pl.patient_id IS NULL THEN patient_team_prog.location_id
    ELSE pl.location_id
  END AS session_location_id,
  -- Calculate patient year group for the academic year
  CASE
    WHEN p.birth_academic_year IS NOT NULL
    THEN tl.academic_year - p.birth_academic_year - 5 -- See AGE_CHILDREN_START_SCHOOL
    ELSE NULL
  END AS patient_year_group,
  -- Vaccination status booleans
  (vr_any.patient_id IS NOT NULL OR vr_previous.patient_id IS NOT NULL OR consent_already_vaccinated.patient_id IS NOT NULL) AS has_any_vaccination,
  (vaccination_summary.has_sais_vaccination) AS vaccinated_by_sais_current_year,
  ((vr_elsewhere_declared.patient_id IS NOT NULL OR consent_already_vaccinated.patient_id IS NOT NULL) AND vr_elsewhere_recorded.patient_id IS NULL) AS vaccinated_elsewhere_declared_current_year,
  (vr_elsewhere_recorded.patient_id IS NOT NULL) AS vaccinated_elsewhere_recorded_current_year,
  (vr_previous.patient_id IS NOT NULL
    AND vaccination_summary.has_sais_vaccination IS NOT TRUE
    AND vr_elsewhere_declared.patient_id IS NULL
    AND consent_already_vaccinated.patient_id IS NULL
    AND vr_elsewhere_recorded.patient_id IS NULL
  ) AS vaccinated_in_previous_years,
  -- Vaccination counts
  COALESCE(vaccination_summary.sais_vaccinations_count, 0) AS sais_vaccinations_count,
  EXTRACT(MONTH FROM (vaccination_summary.most_recent_vaccination)) AS most_recent_vaccination_month,
  EXTRACT(YEAR FROM (vaccination_summary.most_recent_vaccination)) AS most_recent_vaccination_year,
  -- Consent information
  COALESCE(pps.consent_status, 0) AS consent_status,
  pps.consent_vaccine_methods AS consent_vaccine_methods,
  (parent_refused.patient_id IS NOT NULL) AS parent_refused_consent_current_year,
  (child_refused.patient_id IS NOT NULL) AS child_refused_vaccination_current_year,
  -- Vaccination by delivery method (flu programme)
  (vaccination_summary.has_nasal) AS vaccinated_nasal_current_year,
  (vaccination_summary.has_injection) AS vaccinated_injection_current_year,
  -- Flag for patients outside the team's cohort (vaccinated but not enrolled)
  (pl.patient_id IS NULL) AS outside_cohort

FROM patients p
-- Join to get team-patient-programme relationships via sessions
-- UNION of: (1) enrolled patients and (2) patients vaccinated by teams where they're not enrolled
INNER JOIN (
  -- Part 1: Patients enrolled in sessions (for cohort tracking)
  SELECT DISTINCT
    pl.patient_id,
    pl.location_id,
    s.id AS session_id,
    tl.academic_year,
    spyg.programme_type AS s_programme_type,
    tl.team_id
  FROM patient_locations pl
  INNER JOIN team_locations tl ON tl.location_id = pl.location_id AND tl.academic_year = pl.academic_year
  INNER JOIN sessions s ON s.team_location_id = tl.id
  INNER JOIN session_programme_year_groups spyg ON spyg.session_id = s.id

  UNION ALL

  -- Part 2: Patients with vaccinations administered by teams where NOT enrolled
  -- (only creates rows when patient doesn't have enrollment with this team)
  SELECT DISTINCT
    vr.patient_id,
    tl.location_id,
    vr.session_id,
    tl.academic_year,
    vr.programme_type,
    tl.team_id
  FROM vaccination_records vr
  INNER JOIN sessions s ON s.id = vr.session_id
  INNER JOIN team_locations tl ON tl.id = s.team_location_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 0 -- administered
    -- Only include if patient is NOT enrolled with this team in this academic year
    AND NOT EXISTS (
      SELECT 1
      FROM patient_locations pl_check
      INNER JOIN team_locations tl_check ON tl_check.location_id = pl_check.location_id
          AND tl_check.team_id = tl.team_id
          AND tl_check.academic_year = pl_check.academic_year
      WHERE pl_check.patient_id = vr.patient_id
        AND pl_check.academic_year = tl.academic_year
    )
) patient_team_prog ON patient_team_prog.patient_id = p.id
-- Left join patient_locations to allow for patients who moved out but were vaccinated
LEFT JOIN patient_locations pl ON pl.patient_id = p.id
  AND pl.location_id = patient_team_prog.location_id
  AND pl.academic_year = patient_team_prog.academic_year
INNER JOIN sessions s ON s.id = patient_team_prog.session_id
INNER JOIN teams t ON t.id = patient_team_prog.team_id
INNER JOIN team_locations tl ON tl.id = s.team_location_id

-- Left join to check if patient is archived for this team
LEFT JOIN archive_reasons ar ON ar.patient_id = p.id AND ar.team_id = t.id

-- Left join patient school for local authority info and organisation
LEFT JOIN locations school ON school.id = p.school_id
LEFT JOIN local_authorities school_la ON school_la.gias_code = school.gias_local_authority_code

-- Left join current patient location for organisation (fallback if no school)
-- Use vaccination location if pl is NULL (not enrolled), otherwise use enrollment location
LEFT JOIN locations current_location ON current_location.id =
  CASE
    WHEN pl.patient_id IS NULL THEN patient_team_prog.location_id
    ELSE pl.location_id
  END

LEFT JOIN vaccination_summary ON vaccination_summary.patient_id = p.id
  AND vaccination_summary.programme_type = s_programme_type
  AND vaccination_summary.team_id = t.id
  AND vaccination_summary.academic_year = tl.academic_year

LEFT JOIN (
  SELECT DISTINCT patient_id, programme_type, academic_year
  FROM all_vaccinations_by_year
  WHERE outcome IN (0, 4)
) vr_any ON vr_any.patient_id = p.id AND vr_any.programme_type = s_programme_type AND vr_any.academic_year = tl.academic_year

-- Left join to check if patient declared they were already vaccinated elsewhere
LEFT JOIN (
  SELECT DISTINCT vr.patient_id, vr.programme_type, COALESCE(vr_tl.academic_year, EXTRACT(YEAR FROM (vr.performed_at_date))) AS academic_year
  FROM vaccination_records vr
  LEFT JOIN sessions vr_s ON vr_s.id = vr.session_id
  LEFT JOIN team_locations vr_tl ON vr_tl.id = vr_s.team_location_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 4 -- already_had (declared elsewhere)
    -- For Td/IPV, only count if dose 5 or unknown dose with session
    AND (
      vr.programme_type != 'td_ipv'
      OR vr.dose_sequence = 5
      OR (vr.dose_sequence IS NULL AND vr.session_id IS NOT NULL)
    )
) vr_elsewhere_declared ON vr_elsewhere_declared.patient_id = p.id
  AND vr_elsewhere_declared.programme_type = s_programme_type
  AND vr_elsewhere_declared.academic_year = tl.academic_year

-- Left join to check if parent refused consent claiming child was already vaccinated
LEFT JOIN (
  SELECT DISTINCT
    c.patient_id,
    c.programme_type,
    c.academic_year
  FROM consents c
  WHERE c.invalidated_at IS NULL
    AND c.withdrawn_at IS NULL
    AND c.response = 1  -- refused
    AND c.reason_for_refusal = 1  -- already_vaccinated
) consent_already_vaccinated ON consent_already_vaccinated.patient_id = p.id
  AND consent_already_vaccinated.programme_type = s_programme_type
  AND consent_already_vaccinated.academic_year = tl.academic_year

LEFT JOIN (
  SELECT DISTINCT patient_id, programme_type, team_id, academic_year
  FROM all_vaccinations_by_year
  WHERE outcome = 0
) vr_elsewhere_recorded ON vr_elsewhere_recorded.patient_id = p.id
  AND vr_elsewhere_recorded.programme_type = s_programme_type
  AND vr_elsewhere_recorded.academic_year = tl.academic_year
  AND (vr_elsewhere_recorded.team_id IS NULL OR vr_elsewhere_recorded.team_id != t.id)

LEFT JOIN (
  SELECT DISTINCT patient_id, programme_type, academic_year
  FROM all_vaccinations_by_year
  WHERE outcome IN (0, 4)
    AND programme_type != 'flu'
) vr_previous ON vr_previous.patient_id = p.id
  AND vr_previous.programme_type = s_programme_type
  AND vr_previous.academic_year < tl.academic_year

-- Left join patient consent statuses (LATERAL for better index usage)
LEFT JOIN LATERAL (
  SELECT consent_status, consent_vaccine_methods
  FROM patient_programme_statuses pps
  WHERE pps.patient_id = p.id
    AND pps.programme_type = s_programme_type
    AND pps.academic_year = tl.academic_year
  LIMIT 1
) pps ON true

-- Left join to check if parent refused consent (consent_refusal vaccination records)
LEFT JOIN (
  SELECT DISTINCT
    vr.patient_id,
    vr.programme_type,
    COALESCE(vr_tl.academic_year, EXTRACT(YEAR FROM (vr.performed_at_date))) AS academic_year
  FROM vaccination_records vr
  LEFT JOIN sessions vr_s ON vr_s.id = vr.session_id
  LEFT JOIN team_locations vr_tl ON vr_tl.id = vr_s.team_location_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 1 -- refused
    AND vr.source = 3 -- consent_refusal
) parent_refused ON parent_refused.patient_id = p.id
  AND parent_refused.programme_type = s_programme_type
  AND parent_refused.academic_year = tl.academic_year

-- Left join to check if child refused vaccination at session (not from consent_refusal)
LEFT JOIN (
  SELECT DISTINCT
    vr.patient_id,
    vr.programme_type,
    vr_tl.academic_year
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  INNER JOIN team_locations vr_tl ON vr_tl.id = vr_s.team_location_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 1 -- refused
    AND (vr.source IS NULL OR vr.source != 3) -- not consent_refusal
) child_refused ON child_refused.patient_id = p.id
  AND child_refused.programme_type = s_programme_type
  AND child_refused.academic_year = tl.academic_year

WHERE p.invalidated_at IS NULL
  AND p.restricted_at IS NULL
)
SELECT DISTINCT ON (patient_id, programme_type, team_id, academic_year)
  id,
  patient_id,
  patient_gender,
  programme_type,
  academic_year,
  team_id,
  team_name,
  is_archived,
  patient_school_local_authority_code,
  patient_local_authority_code,
  patient_school_id,
  patient_school_urn,
  patient_school_name,
  session_location_id,
  patient_year_group,
  has_any_vaccination,
  vaccinated_by_sais_current_year,
  vaccinated_elsewhere_declared_current_year,
  vaccinated_elsewhere_recorded_current_year,
  vaccinated_in_previous_years,
  sais_vaccinations_count,
  most_recent_vaccination_month,
  most_recent_vaccination_year,
  consent_status,
  consent_vaccine_methods,
  parent_refused_consent_current_year,
  child_refused_vaccination_current_year,
  vaccinated_nasal_current_year,
  vaccinated_injection_current_year,
  outside_cohort
FROM base_data
ORDER BY
  patient_id, programme_type, team_id, academic_year,
  (sais_vaccinations_count > 0) DESC,
  (outside_cohort = false) DESC,
  patient_school_id NULLS LAST
