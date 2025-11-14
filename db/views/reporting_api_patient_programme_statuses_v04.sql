WITH base_data AS (
  SELECT
    -- Unique identifier for concurrent refresh support
    CONCAT(p.id, '-', prog.id, '-', t.id, '-', s.academic_year) AS id,
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
  prog.id AS programme_id,
  prog.type AS programme_type,
  s.academic_year,
  -- Team info
  t.id AS team_id,
  t.name AS team_name,
  -- Patient's current organisation (where enrolled)
  COALESCE(patient_school_org.id, patient_location_org.id) AS organisation_id,
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
  pl.location_id AS session_location_id,
  -- Calculate patient year group for the academic year
  CASE
    WHEN p.birth_academic_year IS NOT NULL
    THEN s.academic_year - p.birth_academic_year - 5 -- See AGE_CHILDREN_START_SCHOOL
    ELSE NULL
  END AS patient_year_group,
  -- Vaccination status booleans
  CASE
    WHEN vr_any.patient_id IS NOT NULL THEN true
    ELSE false
  END AS has_any_vaccination,
  CASE
    WHEN vr_sais_current.patient_id IS NOT NULL THEN true
    ELSE false
  END AS vaccinated_by_sais_current_year,
  CASE
    WHEN vr_elsewhere_declared.patient_id IS NOT NULL AND vr_elsewhere_recorded.patient_id IS NULL THEN true
    ELSE false
  END AS vaccinated_elsewhere_declared_current_year,
  CASE
    WHEN vr_elsewhere_recorded.patient_id IS NOT NULL THEN true
    ELSE false
  END AS vaccinated_elsewhere_recorded_current_year,
  CASE
    WHEN vr_previous.patient_id IS NOT NULL THEN true
    ELSE false
  END AS vaccinated_in_previous_years,
  -- Vaccination counts
  COALESCE(vr_counts.sais_vaccinations_count, 0) AS sais_vaccinations_count,
  vr_recent.most_recent_vaccination_month,
  vr_recent.most_recent_vaccination_year,
  -- Consent information
  COALESCE(pcs.status, 0) AS consent_status,
  pcs.vaccine_methods AS consent_vaccine_methods,
  CASE
    WHEN parent_refused.patient_id IS NOT NULL THEN true
    ELSE false
  END AS parent_refused_consent_current_year,
  CASE
    WHEN child_refused.patient_id IS NOT NULL THEN true
    ELSE false
  END AS child_refused_vaccination_current_year,
  -- Vaccination by delivery method (flu programme)
  CASE
    WHEN vr_nasal_current.patient_id IS NOT NULL THEN true
    ELSE false
  END AS vaccinated_nasal_current_year,
  CASE
    WHEN vr_injection_current.patient_id IS NOT NULL THEN true
    ELSE false
  END AS vaccinated_injection_current_year,
  -- Row number for deduplication (replaces DISTINCT ON)
  ROW_NUMBER() OVER (
    PARTITION BY p.id, prog.id, t.id, s.academic_year
    ORDER BY patient_school_org.id NULLS LAST
  ) AS rn

FROM patients p
-- Join to get team-patient-programme relationships via sessions
INNER JOIN patient_locations pl ON pl.patient_id = p.id
INNER JOIN sessions s ON s.location_id = pl.location_id AND s.academic_year = pl.academic_year
INNER JOIN teams t ON t.id = s.team_id
INNER JOIN session_programmes sp ON sp.session_id = s.id
INNER JOIN programmes prog ON prog.id = sp.programme_id

-- Left join patient school for local authority info and organisation
LEFT JOIN locations school ON school.id = p.school_id
LEFT JOIN subteams school_subteam ON school_subteam.id = school.subteam_id
LEFT JOIN teams school_team ON school_team.id = school_subteam.team_id
LEFT JOIN organisations patient_school_org ON patient_school_org.id = school_team.organisation_id
LEFT JOIN local_authorities school_la ON school_la.gias_code = school.gias_local_authority_code

-- Left join current patient location for organisation (fallback if no school)
LEFT JOIN locations current_location ON current_location.id = pl.location_id
LEFT JOIN subteams current_location_subteam ON current_location_subteam.id = current_location.subteam_id
LEFT JOIN teams current_location_team ON current_location_team.id = current_location_subteam.team_id
LEFT JOIN organisations patient_location_org ON patient_location_org.id = current_location_team.organisation_id

-- Left join to check if patient has any vaccination (administered or already_had) in current academic year
LEFT JOIN (
  SELECT DISTINCT vr.patient_id, vr.programme_id, vr_s.academic_year
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome IN (0, 4) -- administered or already_had
) vr_any ON vr_any.patient_id = p.id AND vr_any.programme_id = prog.id AND vr_any.academic_year = s.academic_year

-- Left join to check if patient was vaccinated by SAIS in current academic year
LEFT JOIN (
  SELECT DISTINCT vr.patient_id, vr.programme_id, vr_s.academic_year
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 0 -- administered
) vr_sais_current ON vr_sais_current.patient_id = p.id
  AND vr_sais_current.programme_id = prog.id
  AND vr_sais_current.academic_year = s.academic_year

-- Left join to check if patient declared they were already vaccinated elsewhere
LEFT JOIN (
  SELECT DISTINCT vr.patient_id, vr.programme_id, COALESCE(vr_s.academic_year, EXTRACT(YEAR FROM vr.performed_at)) AS academic_year
  FROM vaccination_records vr
  LEFT JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 4 -- already_had (declared elsewhere)
) vr_elsewhere_declared ON vr_elsewhere_declared.patient_id = p.id
  AND vr_elsewhere_declared.programme_id = prog.id
  AND vr_elsewhere_declared.academic_year = s.academic_year

-- Left join to check if patient has externally recorded vaccination (from uploads/NHS API)
LEFT JOIN (
  SELECT DISTINCT vr.patient_id, vr.programme_id, EXTRACT(YEAR FROM vr.performed_at) AS academic_year
  FROM vaccination_records vr
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 0 -- administered (actual vaccination record)
    AND vr.source IN (1, 2) -- historical_upload or nhs_immunisations_api
) vr_elsewhere_recorded ON vr_elsewhere_recorded.patient_id = p.id
  AND vr_elsewhere_recorded.programme_id = prog.id
  AND vr_elsewhere_recorded.academic_year = s.academic_year

-- Left join to check if patient was vaccinated in previous years
LEFT JOIN (
  SELECT DISTINCT vr.patient_id, vr.programme_id, vr_s.academic_year
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome IN (0, 4) -- administered or already_had
) vr_previous ON vr_previous.patient_id = p.id
  AND vr_previous.programme_id = prog.id
  AND vr_previous.academic_year < s.academic_year

-- Left join to count SAIS vaccinations (administered by current team in current academic year)
LEFT JOIN (
  SELECT
    vr.patient_id,
    vr.programme_id,
    vr_s.team_id,
    vr_s.academic_year,
    COUNT(*) AS sais_vaccinations_count
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 0 -- administered
  GROUP BY vr.patient_id, vr.programme_id, vr_s.team_id, vr_s.academic_year
) vr_counts ON vr_counts.patient_id = p.id AND vr_counts.programme_id = prog.id
  AND vr_counts.team_id = t.id AND vr_counts.academic_year = s.academic_year

-- Left join to get most recent vaccination date for time series (by current team only)
LEFT JOIN (
  SELECT
    vr.patient_id,
    vr.programme_id,
    vr_s.team_id,
    EXTRACT(MONTH FROM MAX(vr.performed_at)) AS most_recent_vaccination_month,
    EXTRACT(YEAR FROM MAX(vr.performed_at)) AS most_recent_vaccination_year
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 0 -- administered
  GROUP BY vr.patient_id, vr.programme_id, vr_s.team_id
) vr_recent ON vr_recent.patient_id = p.id AND vr_recent.programme_id = prog.id AND vr_recent.team_id = t.id

-- Left join patient consent statuses (LATERAL for better index usage)
LEFT JOIN LATERAL (
  SELECT status, vaccine_methods
  FROM patient_consent_statuses pcs
  WHERE pcs.patient_id = p.id
    AND pcs.programme_id = prog.id
    AND pcs.academic_year = s.academic_year
  LIMIT 1
) pcs ON true

-- Left join to check if parent refused consent (consent_refusal vaccination records)
LEFT JOIN (
  SELECT DISTINCT
    vr.patient_id,
    vr.programme_id,
    COALESCE(vr_s.academic_year, EXTRACT(YEAR FROM vr.performed_at)) AS academic_year
  FROM vaccination_records vr
  LEFT JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 1 -- refused
    AND vr.source = 3 -- consent_refusal
) parent_refused ON parent_refused.patient_id = p.id
  AND parent_refused.programme_id = prog.id
  AND parent_refused.academic_year = s.academic_year

-- Left join to check if child refused vaccination at session (not from consent_refusal)
LEFT JOIN (
  SELECT DISTINCT
    vr.patient_id,
    vr.programme_id,
    vr_s.academic_year
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 1 -- refused
    AND (vr.source IS NULL OR vr.source != 3) -- not consent_refusal
) child_refused ON child_refused.patient_id = p.id
  AND child_refused.programme_id = prog.id
  AND child_refused.academic_year = s.academic_year

-- Left join to check if patient was vaccinated with nasal spray in current academic year
LEFT JOIN (
  SELECT DISTINCT vr.patient_id, vr.programme_id, vr_s.academic_year
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 0 -- administered
    AND vr.delivery_method = 2 -- nasal_spray
) vr_nasal_current ON vr_nasal_current.patient_id = p.id
  AND vr_nasal_current.programme_id = prog.id
  AND vr_nasal_current.academic_year = s.academic_year

-- Left join to check if patient was vaccinated with injection in current academic year
LEFT JOIN (
  SELECT DISTINCT vr.patient_id, vr.programme_id, vr_s.academic_year
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 0 -- administered
    AND vr.delivery_method IN (0, 1) -- intramuscular or subcutaneous
) vr_injection_current ON vr_injection_current.patient_id = p.id
  AND vr_injection_current.programme_id = prog.id
  AND vr_injection_current.academic_year = s.academic_year

WHERE p.invalidated_at IS NULL
  AND p.restricted_at IS NULL
)
SELECT
  id,
  patient_id,
  patient_gender,
  programme_id,
  programme_type,
  academic_year,
  team_id,
  team_name,
  organisation_id,
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
  vaccinated_injection_current_year
FROM base_data
WHERE rn = 1
