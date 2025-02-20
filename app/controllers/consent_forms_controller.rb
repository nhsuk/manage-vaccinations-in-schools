# frozen_string_literal: true

require "pagy/extras/array"

class ConsentFormsController < ApplicationController
  include Pagy::Backend
  include PatientSortingConcern

  before_action :set_consent_form, except: :index
  before_action :set_patient, only: %i[edit_match update_match]

  layout "full"

  def index
    @pagy, @consent_forms = pagy(consent_form_scope.order(:recorded_at))
  end

  def show
    patients = policy_scope(Patient).to_a
    sort_and_filter_patients!(patients)
    @pagy, @patients = pagy_array(patients)
  end

  def edit_match
    render :match, layout: "two_thirds"
  end

  def update_match
    @consent_form.match_with_patient!(@patient, current_user:)

    session =
      @patient.sessions_for_current_academic_year.first ||
        @consent_form.original_session

    flash[:success] = {
      heading: "Consent matched for",
      heading_link_text: @patient.full_name,
      heading_link_href:
        session_patient_programme_path(
          session,
          @patient,
          session.programmes.first,
          section: "triage",
          tab: "given"
        )
    }

    redirect_to action: :index
  end

  def edit_archive
    render :archive, layout: "two_thirds"
  end

  def update_archive
    @consent_form.assign_attributes(archive_params)

    if @consent_form.save
      redirect_to consent_forms_path,
                  flash: {
                    success:
                      "Consent response from #{@consent_form.parent_full_name} archived"
                  }
    else
      render :archive, layout: "two_thirds", status: :unprocessable_entity
    end
  end

  def new_patient
    @patient =
      Patient.from_consent_form(@consent_form).tap(&:clear_changes_information)

    render layout: "two_thirds"
  end

  def create_patient
    patient = Patient.from_consent_form(@consent_form)

    ActiveRecord::Base.transaction do
      patient.save!

      school_move =
        if (school = @consent_form.school)
          SchoolMove.new(patient:, school:)
        else
          SchoolMove.new(
            patient:,
            home_educated: @consent_form.home_educated,
            organisation: @consent_form.organisation
          )
        end

      school_move.confirm!

      @consent_form.match_with_patient!(patient, current_user:)
    end

    if patient.nhs_number.nil?
      PatientNHSNumberLookupJob.perform_later(patient)
    else
      PatientUpdateFromPDSJob.perform_later(patient)
    end

    flash[:success] = "#{patient.full_name}’s record created from a consent \
                       response from #{@consent_form.parent_full_name}"

    redirect_to action: :index
  end

  private

  def consent_form_scope
    policy_scope(ConsentForm).unmatched.recorded.not_archived
  end

  def set_consent_form
    @consent_form = consent_form_scope.find(params[:id])
  end

  def set_patient
    @patient =
      policy_scope(Patient).includes(
        sessions_for_current_academic_year: :programmes
      ).find(params[:patient_id])
  end

  def archive_params
    params.expect(consent_form: :notes).merge(archived_at: Time.current)
  end
end
