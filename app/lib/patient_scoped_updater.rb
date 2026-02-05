# frozen_string_literal: true

class PatientScopedUpdater
  def initialize(patient_scope: nil, patient: nil)
    @patient_scope = (patient ? Patient.where(id: patient) : patient_scope)
  end

  # The following code is necessary to support an optimisation where we're
  #  updating a single patient by ID.
  #
  # This method allow us to check if the scope where clause is only checking
  #  the ID of the patient, meaning we can optimise out the `JOIN` and filter
  #  the table directly.
  #
  # For example, without this optimisation, a scope of `Patient.where(id: 1)`
  #  would result in the following SQL query:
  #
  # SELECT patient_id, team_id FROM patient_teams
  # JOIN patients ON patients.id = patient_teams.patient_id
  # WHERE patients.id = 1
  #
  # Whereas we know that the following SQL query is all we need in this case:
  #
  # SELECT patient_id, team_id FROM patient_teams
  # WHERE patient_teams.patient_id = 1

  def merge_patient_scope(scope)
    if is_patient_scope_id_only?
      scope.where(patient_id: patient_scope.select(:id))
    elsif patient_scope
      scope.joins(:patient).merge(patient_scope)
    else
      scope
    end
  end

  def is_patient_scope_id_only?
    @is_patient_scope_id_only ||= is_id_only_scope?(patient_scope)
  end

  def is_id_only_scope?(scope)
    if scope.nil? || scope.joins_values.any? ||
         scope.left_outer_joins_values.any?
      return false
    end

    values = scope.where_values_hash
    values.key?("id") && values.size == 1
  end
end
