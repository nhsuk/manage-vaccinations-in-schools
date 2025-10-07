SELECT DISTINCT
  -- Unique identifier for concurrent refresh support
  CONCAT(p.id, '-', prog.id, '-', t.id, '-', s.academic_year) AS id,
  -- Patient identifiers (minimal)
  p.id AS patient_id,
  p.gender_code AS patient_gender_code,
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
  COALESCE(la.mhclg_code, '') AS patient_local_authority_code,
  -- Calculate patient year group for the academic year
  CASE
    WHEN p.birth_academic_year IS NOT NULL
    THEN s.academic_year - p.birth_academic_year
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
    WHEN vr_elsewhere_declared.patient_id IS NOT NULL THEN true
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
  vr_recent.most_recent_vaccination_year

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

-- Left join patient postcode for local authority info via postcode lookup
LEFT JOIN local_authority_postcodes lap ON lap.value = p.address_postcode
LEFT JOIN local_authorities la ON la.gss_code = lap.gss_code

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

-- Left join to count SAIS vaccinations (administered)
LEFT JOIN (
  SELECT
    vr.patient_id,
    vr.programme_id,
    COUNT(*) AS sais_vaccinations_count
  FROM vaccination_records vr
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 0 -- administered
  GROUP BY vr.patient_id, vr.programme_id
) vr_counts ON vr_counts.patient_id = p.id AND vr_counts.programme_id = prog.id

-- Left join to get most recent vaccination date for time series
LEFT JOIN (
  SELECT
    vr.patient_id,
    vr.programme_id,
    EXTRACT(MONTH FROM MAX(vr.performed_at)) AS most_recent_vaccination_month,
    EXTRACT(YEAR FROM MAX(vr.performed_at)) AS most_recent_vaccination_year
  FROM vaccination_records vr
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 0 -- administered
  GROUP BY vr.patient_id, vr.programme_id
) vr_recent ON vr_recent.patient_id = p.id AND vr_recent.programme_id = prog.id

WHERE p.invalidated_at IS NULL
  AND p.restricted_at IS NULL
