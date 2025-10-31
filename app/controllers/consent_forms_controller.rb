# frozen_string_literal: true

class ConsentFormsController < ApplicationController
  include PatientSearchFormConcern

  before_action :set_patient_search_form, only: :search
  before_action :set_consent_form, except: :index
  before_action :set_patient, only: %i[edit_match update_match]

  def index
    consent_forms = policy_scope(ConsentForm).unmatched.order(:recorded_at)

    if (session_slug = params[:session_slug]).present?
      @session = policy_scope(Session).find_by(slug: session_slug)
      consent_forms = consent_forms.for_session(@session)
    end

    @pagy, @consent_forms = pagy(consent_forms)

    render layout: "full"
  end

  def show
    render layout: "three_quarters"
  end

  def search
    patients =
      @form.apply(
        policy_scope(Patient).includes(:school, parent_relationships: :parent)
      )

    @pagy, @patients = pagy(patients)

    render layout: "full"
  end

  def edit_match
    render :match, layout: "full"
  end

  def update_match
    @consent_form.match_with_patient!(@patient, current_user:)

    reset_count!

    session =
      @patient
        .sessions
        .includes(:location_programme_year_groups, :programmes)
        .has_programmes(@consent_form.programmes)
        .find_by(academic_year: AcademicYear.pending) || @consent_form.session

    programme = session.programmes_for(patient: @patient).first

    heading_link_href =
      if programme.nil?
        patient_path(@patient)
      else
        session_patient_programme_path(session, @patient, programme)
      end

    flash[:success] = {
      heading: "Consent matched for",
      heading_link_text: @patient.full_name,
      heading_link_href:
    }

    redirect_to action: :index
  end

  def edit_archive
    render :archive
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
      render :archive, status: :unprocessable_content
    end
  end

  def new_patient
    @patient =
      Patient.from_consent_form(@consent_form).tap(&:clear_changes_information)

    render :patient
  end

  def create_patient
    patient = Patient.from_consent_form(@consent_form)

    ActiveRecord::Base.transaction do
      patient.save!

      academic_year = @consent_form.academic_year

      school_move =
        if (school = @consent_form.school)
          SchoolMove.new(academic_year:, patient:, school:)
        else
          SchoolMove.new(
            academic_year:,
            patient:,
            home_educated: @consent_form.home_educated,
            team: @consent_form.team
          )
        end

      school_move.confirm!(user: current_user)

      @consent_form.match_with_patient!(patient, current_user:)

      reset_count!
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

  def set_consent_form
    @consent_form =
      policy_scope(ConsentForm)
        .includes(:programmes, :vaccines)
        .unmatched
        .find(params[:id])
  end

  def set_patient
    @patient =
      policy_scope(Patient).includes(
        parent_relationships: :parent,
        vaccination_records: :programme
      ).find(params[:patient_id])
  end

  def archive_params
    params.expect(consent_form: :notes).merge(archived_at: Time.current)
  end

  def reset_count!
    TeamCachedCounts.new(current_team).reset_unmatched_consent_responses!
  end
end
