# frozen_string_literal: true

class PatientSessions::VaccinationsController < PatientSessions::BaseController
  include TodaysBatchConcern

  before_action :set_todays_batch

  def create
    authorize VaccinationRecord.new(
                patient: @patient,
                session: @session,
                programme: @programme
              )

    draft_vaccination_record =
      DraftVaccinationRecord.new(request_session: session, current_user:)

    @vaccinate_form =
      VaccinateForm.new(
        current_user:,
        patient: @patient,
        session: @session,
        programme: @programme,
        todays_batch: @todays_batch,
        **vaccinate_form_params
      )

    if @vaccinate_form.save(draft_vaccination_record:)
      steps = draft_vaccination_record.wizard_steps

      steps.delete(:mmr_or_mmrv) unless draft_vaccination_record.programme.mmr_mmrv?
      steps.delete(:dose) # this can only be changed from confirmation page
      steps.delete(:identity) # this can only be changed from confirmation page
      steps.delete(:notes) # this is on the confirmation page
      steps.delete(:supplier) # this can only be changed from confirmation page

      steps.delete(:date_and_time)
      steps.delete(:outcome) if draft_vaccination_record.administered?
      if draft_vaccination_record.delivery_method.present? &&
           draft_vaccination_record.delivery_site.present?
        steps.delete(:delivery)
      end
      steps.delete(:vaccine) if draft_vaccination_record.vaccine.present?
      steps.delete(:batch) if draft_vaccination_record.batch.present?

      draft_vaccination_record.update!(first_active_wizard_step: steps.first)

      redirect_to draft_vaccination_record_path(
                    I18n.t(steps.first, scope: :wicked)
                  )
    else
      render "patient_sessions/programmes/show",
             layout: "full",
             status: :unprocessable_content
    end
  end

  private

  def vaccinate_form_params
    params.expect(
      vaccinate_form: %i[
        delivery_site
        dose_sequence
        identity_check_confirmed_by_other_name
        identity_check_confirmed_by_other_relationship
        identity_check_confirmed_by_patient
        pre_screening_confirmed
        pre_screening_notes
        supplied_by_user_id
        vaccine_id
        vaccine_method
      ]
    )
  end

  def set_todays_batch
    vaccine_method = vaccinate_form_params[:vaccine_method]
    return if vaccine_method.nil?

    id = todays_batch_id(programme: @programme, vaccine_method:)
    return if id.nil?

    @todays_batch =
      policy_scope(Batch)
        .where(vaccine: @session.vaccines)
        .not_archived
        .not_expired
        .find_by(id:)
  end
end
