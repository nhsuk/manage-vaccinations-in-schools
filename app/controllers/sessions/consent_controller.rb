# frozen_string_literal: true

class Sessions::ConsentController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_session
  before_action :set_patient_search_form

  layout "full"

  def show
    statuses_except_not_required =
      Patient::ConsentStatus.statuses.keys - %w[not_required]

    @statuses =
      insert_status_for_programmes(
        statuses_except_not_required,
        @session.programmes
      )

    scope =
      @session
        .patients
        .includes(:consent_statuses, :triage_statuses, { notes: :created_by })
        .has_consent_status(
          statuses_except_not_required,
          programme: @form.programmes,
          academic_year: @session.academic_year
        )

    patients = @form.apply(scope)
    @pagy, @patients = pagy(patients)
  end

  private

  def set_session
    @session =
      policy_scope(Session).includes(programmes: :vaccines).find_by!(
        slug: params[:session_slug]
      )
  end

  def insert_status_for_programmes(statuses, programmes)
    insert_index = statuses.index("given") + 1

    # TODO: Make this more generic, rather than specific to programme
    #  combinations.

    result = statuses.dup

    if programmes.any?(&:flu?)
      result.insert(
        insert_index,
        "given_nasal",
        "given_injection_without_gelatine"
      )
    end

    if programmes.any?(&:mmr?) && programmes.none?(&:flu?)
      result.insert(insert_index, "given_injection_without_gelatine")
    end

    result.delete("given") if programmes.all?(&:flu?)

    result
  end
end
