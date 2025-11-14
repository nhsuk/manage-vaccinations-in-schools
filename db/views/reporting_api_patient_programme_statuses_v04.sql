WITH vaccination_summary AS (
  SELECT
    vr.patient_id,
    vr.programme_id,
    vr_s.team_id,
    vr_s.academic_year,
    COUNT(*) FILTER (WHERE vr.outcome = 0) AS sais_vaccinations_count,
    BOOL_OR(vr.outcome = 0) AS has_sais_vaccination,
    MAX(vr.performed_at) FILTER (WHERE vr.outcome = 0) AS most_recent_vaccination,
    BOOL_OR(vr.outcome = 0 AND vr.delivery_method = 2) AS has_nasal,
    BOOL_OR(vr.outcome = 0 AND vr.delivery_method IN (0, 1)) AS has_injection
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  WHERE vr.discarded_at IS NULL
  GROUP BY vr.patient_id, vr.programme_id, vr_s.team_id, vr_s.academic_year
),
all_vaccinations_by_year AS (
  SELECT
    vr.patient_id,
    vr.programme_id,
    vr_s.academic_year,
    vr_s.team_id,
    vr.outcome,
    vr.source,
    prog_vr.type AS programme_type
  FROM vaccination_records vr
  INNER JOIN sessions vr_s ON vr_s.id = vr.session_id
  INNER JOIN programmes prog_vr ON prog_vr.id = vr.programme_id
  WHERE vr.discarded_at IS NULL

  UNION ALL

  SELECT
    vr.patient_id,
    vr.programme_id,
    CASE
      WHEN EXTRACT(MONTH FROM vr.performed_at) >= 9
      THEN EXTRACT(YEAR FROM vr.performed_at)::integer
      ELSE EXTRACT(YEAR FROM vr.performed_at)::integer - 1
    END AS academic_year,
    NULL AS team_id,
    vr.outcome,
    vr.source,
    prog_vr.type AS programme_type
  FROM vaccination_records vr
  INNER JOIN programmes prog_vr ON prog_vr.id = vr.programme_id
  WHERE vr.discarded_at IS NULL
    AND vr.source IN (1, 2)
    AND vr.session_id IS NULL
),
base_data AS (
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
  -- Archive status - check if there's an archive reason for this patient-team pair
  (ar.patient_id IS NOT NULL) AS is_archived,
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
    THEN s.academic_year - p.birth_academic_year - 5 -- See AGE_CHILDREN_START_SCHOOL
    ELSE NULL
  END AS patient_year_group,
  -- Vaccination status booleans
  (vr_any.patient_id IS NOT NULL OR vr_previous.patient_id IS NOT NULL) AS has_any_vaccination,
  (vaccination_summary.has_sais_vaccination) AS vaccinated_by_sais_current_year,
  (vr_elsewhere_declared.patient_id IS NOT NULL AND vr_elsewhere_recorded.patient_id IS NULL) AS vaccinated_elsewhere_declared_current_year,
  (vr_elsewhere_recorded.patient_id IS NOT NULL) AS vaccinated_elsewhere_recorded_current_year,
  (vr_previous.patient_id IS NOT NULL) AS vaccinated_in_previous_years,
  -- Vaccination counts
  COALESCE(vaccination_summary.sais_vaccinations_count, 0) AS sais_vaccinations_count,
  EXTRACT(MONTH FROM vaccination_summary.most_recent_vaccination) AS most_recent_vaccination_month,
  EXTRACT(YEAR FROM vaccination_summary.most_recent_vaccination) AS most_recent_vaccination_year,
  -- Consent information
  COALESCE(pcs.status, 0) AS consent_status,
  pcs.vaccine_methods AS consent_vaccine_methods,
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
  SELECT
    pl.patient_id,
    pl.location_id,
    s.id AS session_id,
    s.academic_year,
    t.id AS team_id,
    prog.id AS programme_id
  FROM patient_locations pl
  INNER JOIN sessions s ON s.location_id = pl.location_id AND s.academic_year = pl.academic_year
  INNER JOIN teams t ON t.id = s.team_id
  INNER JOIN session_programmes sp ON sp.session_id = s.id
  INNER JOIN programmes prog ON prog.id = sp.programme_id

  UNION ALL

  -- Part 2: Patients with vaccinations administered by teams where NOT enrolled
  -- (only creates rows when patient doesn't have enrollment with this team)
  SELECT DISTINCT
    vr.patient_id,
    s.location_id,
    vr.session_id,
    s.academic_year,
    t.id AS team_id,
    vr.programme_id
  FROM vaccination_records vr
  INNER JOIN sessions s ON s.id = vr.session_id
  INNER JOIN teams t ON t.id = s.team_id
  WHERE vr.discarded_at IS NULL
    AND vr.outcome = 0 -- administered
    -- Only include if patient is NOT enrolled with this team in this academic year
    AND NOT EXISTS (
      SELECT 1
      FROM patient_locations pl_check
      INNER JOIN sessions s_check ON s_check.location_id = pl_check.location_id
        AND s_check.team_id = t.id
        AND s_check.academic_year = pl_check.academic_year
      WHERE pl_check.patient_id = vr.patient_id
        AND pl_check.academic_year = s.academic_year
    )
) patient_team_prog ON patient_team_prog.patient_id = p.id
-- Left join patient_locations to allow for patients who moved out but were vaccinated
LEFT JOIN patient_locations pl ON pl.patient_id = p.id
  AND pl.location_id = patient_team_prog.location_id
  AND pl.academic_year = patient_team_prog.academic_year
INNER JOIN sessions s ON s.id = patient_team_prog.session_id
INNER JOIN teams t ON t.id = patient_team_prog.team_id
INNER JOIN programmes prog ON prog.id = patient_team_prog.programme_id

-- Left join to check if patient is archived for this team
LEFT JOIN archive_reasons ar ON ar.patient_id = p.id AND ar.team_id = t.id

-- Left join patient school for local authority info and organisation
LEFT JOIN locations school ON school.id = p.school_id
LEFT JOIN subteams school_subteam ON school_subteam.id = school.subteam_id
LEFT JOIN teams school_team ON school_team.id = school_subteam.team_id
LEFT JOIN organisations patient_school_org ON patient_school_org.id = school_team.organisation_id
LEFT JOIN local_authorities school_la ON school_la.gias_code = school.gias_local_authority_code

-- Left join current patient location for organisation (fallback if no school)
-- Use vaccination location if pl is NULL (not enrolled), otherwise use enrollment location
LEFT JOIN locations current_location ON current_location.id =
  CASE
    WHEN pl.patient_id IS NULL THEN patient_team_prog.location_id
    ELSE pl.location_id
  END
LEFT JOIN subteams current_location_subteam ON current_location_subteam.id = current_location.subteam_id
LEFT JOIN teams current_location_team ON current_location_team.id = current_location_subteam.team_id
LEFT JOIN organisations patient_location_org ON patient_location_org.id = current_location_team.organisation_id

LEFT JOIN vaccination_summary ON vaccination_summary.patient_id = p.id
  AND vaccination_summary.programme_id = prog.id
  AND vaccination_summary.team_id = t.id
  AND vaccination_summary.academic_year = s.academic_year

LEFT JOIN (
  SELECT DISTINCT patient_id, programme_id, academic_year
  FROM all_vaccinations_by_year
  WHERE outcome IN (0, 4)
) vr_any ON vr_any.patient_id = p.id AND vr_any.programme_id = prog.id AND vr_any.academic_year = s.academic_year

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

LEFT JOIN (
  SELECT DISTINCT patient_id, programme_id, team_id, academic_year
  FROM all_vaccinations_by_year
  WHERE outcome = 0
) vr_elsewhere_recorded ON vr_elsewhere_recorded.patient_id = p.id
  AND vr_elsewhere_recorded.programme_id = prog.id
  AND vr_elsewhere_recorded.academic_year = s.academic_year
  AND (vr_elsewhere_recorded.team_id IS NULL OR vr_elsewhere_recorded.team_id != t.id)

LEFT JOIN (
  SELECT DISTINCT patient_id, programme_id, academic_year
  FROM all_vaccinations_by_year
  WHERE outcome IN (0, 4)
    AND (team_id IS NOT NULL OR programme_type != 'flu')
) vr_previous ON vr_previous.patient_id = p.id
  AND vr_previous.programme_id = prog.id
  AND vr_previous.academic_year < s.academic_year

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

WHERE p.invalidated_at IS NULL
  AND p.restricted_at IS NULL
)
SELECT DISTINCT ON (patient_id, programme_id, team_id, academic_year)
  id,
  patient_id,
  patient_gender,
  programme_id,
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
  patient_id, programme_id, team_id, academic_year,
  (sais_vaccinations_count > 0) DESC,
  (outside_cohort = false) DESC,
  patient_school_id NULLS LAST
