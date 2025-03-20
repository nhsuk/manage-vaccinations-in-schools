# frozen_string_literal: true

class VaccinationsController < ApplicationController
  include TodaysBatchConcern
  include VaccinationMailerConcern

  before_action :set_session
  before_action :set_patient
  before_action :set_patient_session
  before_action :set_programme
  before_action :set_todays_batch

  after_action :verify_authorized

  def create
    authorize VaccinationRecord

    draft_vaccination_record =
      DraftVaccinationRecord.new(request_session: session, current_user:)

    @vaccinate_form =
      VaccinateForm.new(
        patient_session: @patient_session,
        current_user:,
        todays_batch: @todays_batch,
        **vaccinate_form_params
      )

    if @vaccinate_form.save(draft_vaccination_record:)
      steps = draft_vaccination_record.wizard_steps

      steps.delete(:notes) # this is on the confirmation page

      steps.delete(:date_and_time)
      steps.delete(:outcome) if draft_vaccination_record.administered?
      if draft_vaccination_record.delivery_method.present? &&
           draft_vaccination_record.delivery_site.present?
        steps.delete(:delivery)
      end
      steps.delete(:vaccine) if draft_vaccination_record.vaccine.present?
      steps.delete(:batch) if draft_vaccination_record.batch.present?

      redirect_to draft_vaccination_record_path(
                    I18n.t(steps.first, scope: :wicked)
                  )
    else
      render "patient_sessions/show", status: :unprocessable_entity
    end
  end

  private

  def vaccinate_form_params
    params.expect(
      vaccinate_form: %i[
        administered
        delivery_method
        delivery_site
        dose_sequence
        feeling_well
        knows_vaccination
        no_allergies
        not_already_had
        not_pregnant
        not_taking_medication
        pre_screening_notes
        programme_id
        vaccine_id
      ]
    )
  end

  def set_session
    @session =
      policy_scope(Session).includes(:location, :programmes).find_by!(
        slug: params[:session_slug] || params[:slug]
      )
  end

  def set_patient
    @patient =
      policy_scope(Patient).find(
        params.fetch(:patient_id) { params.fetch(:id) }
      )
  end

  def set_patient_session
    @patient_session =
      @patient
        .patient_sessions
        .includes(
          :gillick_assessments,
          :session_attendances,
          :organisation,
          patient: {
            parent_relationships: :parent
          },
          session: :programmes
        )
        .find_by!(session: @session)

    @outcomes = Outcomes.new(patient_session: @patient_session)
  end

  def set_programme
    if @patient_session.present?
      @programme =
        @patient_session.programmes.find { it.type == params[:programme_type] }

      raise ActiveRecord::RecordNotFound if @programme.nil?
    else
      @programme =
        @session.programmes.find_by(type: params[:programme_type]) ||
          @session.programmes.first
    end
  end

  def set_todays_batch
    @todays_batch =
      policy_scope(Batch)
        .where(vaccine: @session.vaccines)
        .not_archived
        .not_expired
        .find_by(id: todays_batch_id(programme: @programme))
  end
end
