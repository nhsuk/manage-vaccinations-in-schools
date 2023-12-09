class NurseConsentsController < ApplicationController
  before_action :set_session
  before_action :set_patient
  before_action :set_patient_session
  before_action :check_for_existing_gillick_assessment,
                only: %i[assessing_gillick edit_gillick]
  before_action :set_draft_consent, only: %i[assessing_gillick create new]
  before_action :get_draft_consent, except: %i[assessing_gillick create new]
  before_action :set_draft_triage, only: %i[edit_questions edit_confirm update]

  layout "two_thirds"

  def new
    render :edit_who
  end

  def create
    health_questions =
      Consent::HEALTH_QUESTIONS.fetch(:hpv).map { |question| { question: } }

    if consent_who_params.present?
      @draft_consent.assign_attributes(
        consent_who_params.merge(route: "phone", health_questions:)
      )
      if @draft_consent.save(context: :edit_who)
        redirect_to action: :edit_consent
      else
        render :edit_who
      end
    else
      # If the params are missing, assume this is the Gillick competence route.
      # This feels like it could be more explicit.
      @draft_consent.update!(route: "self_consent", health_questions:)

      redirect_to action: :edit_gillick
    end
  end

  def update
    if consent_who_params.present?
      @draft_consent.assign_attributes(consent_who_params)
      if @draft_consent.save(context: :edit_who)
        redirect_to action: :edit_consent
      else
        render :edit_who
      end
    end

    if consent_agree_params.present?
      @draft_consent.assign_attributes(consent_agree_params)
      if @draft_consent.save(context: :edit_consent)
        # Reset the reason for refusal so the user has to pick it again.
        # Otherwise it will be pre-filled with the previous value.
        @draft_consent.update! reason_for_refusal: nil

        if @draft_consent.response_given?
          redirect_to action: :edit_questions
        elsif @draft_consent.response_refused?
          redirect_to action: :edit_reason
        else
          redirect_to action: :edit_confirm
        end
      else
        render :edit_consent
      end
    end

    if consent_reason_params.present?
      @draft_consent.assign_attributes(consent_reason_params)
      if @draft_consent.save(context: :edit_reason)
        redirect_to action: :edit_confirm
      else
        render :edit_reason
      end
    end

    if consent_health_questions_params.present?
      @draft_consent.health_questions.each_with_index do |hq, index|
        hq.merge! consent_health_questions_params["question_#{index}"]
      end

      # TODO: Handle validation
      @draft_consent.save!

      @draft_triage.assign_attributes consent_triage_params[:triage].merge(
                                        user: current_user
                                      )
      if @draft_triage.save(context: :edit_questions)
        redirect_to action: :edit_confirm
      else
        render :edit_questions
      end
    end
  end

  def update_gillick
    @patient_session.assign_attributes(patient_session_gillick_params)
    if @patient_session.save(context: :edit_gillick)
      if @patient_session.gillick_competent?
        redirect_to action: :edit_consent
      else
        ActiveRecord::Base.transaction do
          @draft_consent.update!(
            recorded_at: Time.zone.now,
            response: "not_provided"
          )
          @patient_session.do_gillick_assessment!
        end

        redirect_to session_patient_vaccinations_path(@session, @patient),
                    flash: {
                      success: {
                        body:
                          "Gillick assessment saved for #{@patient.full_name}"
                      }
                    }
      end
    else
      render :edit_gillick
    end
  end

  def assessing_gillick
  end

  def edit_who
  end

  def edit_gillick
  end

  def edit_consent
  end

  def edit_reason
  end

  def edit_questions
  end

  def edit_confirm
  end

  def record
    unless @draft_consent.response_not_provided?
      ActiveRecord::Base.transaction do
        @draft_consent.update!(recorded_at: Time.zone.now)
        @patient_session.do_consent!
        @patient_session.do_triage! if @patient_session.triage.present?
      end
    end

    if @patient_session.triaged_ready_to_vaccinate? &&
         params[:route] == "vaccinations"
      redirect_to new_session_patient_vaccinations_path(@session, @patient)
    elsif @draft_consent.via_self_consent?
      redirect_to session_patient_vaccinations_path(@session, @patient),
                  flash: {
                    success: {
                      heading:
                        "Gillick assessment saved for #{@patient.full_name}"
                    }
                  }
    else
      redirect_path =
        case params[:route]
        when "triage"
          triage_session_path(@session)
        when "vaccinations"
          vaccinations_session_path(@session)
        else
          consents_session_path(@session)
        end

      redirect_to redirect_path,
                  flash: {
                    success: {
                      heading: "Consent saved for #{@patient.full_name}",
                      body:
                        ActionController::Base.helpers.link_to(
                          "View child record",
                          session_patient_triage_path(@session, @patient)
                        )
                    }
                  }
    end
  end

  private

  def set_session
    @session = Session.find(params.fetch(:session_id))
  end

  def set_patient
    @patient = @session.patients.find(params.fetch(:patient_id))
  end

  def set_patient_session
    @patient_session = @patient.patient_sessions.find_by(session: @session)
  end

  def set_draft_consent
    if @patient.consents.not_response_not_provided.any?
      raise UnprocessableEntity
    end

    @draft_consent =
      @patient.consents.find_or_initialize_by(
        recorded_at: nil,
        campaign: @session.campaign
      )
  end

  def get_draft_consent
    @draft_consent =
      @patient.consents.find_by(recorded_at: nil, campaign: @session.campaign)

    raise UnprocessableEntity unless @draft_consent
  end

  def set_draft_triage
    @draft_triage =
      Triage.find_or_initialize_by(patient_session: @patient_session)
  end

  def check_for_existing_gillick_assessment
    raise UnprocessableEntity unless @patient_session.gillick_competent.nil?
  end

  def patient_session_gillick_params
    params.fetch(:patient_session, {}).permit(
      :gillick_competent,
      :gillick_competence_notes
    )
  end

  def consent_who_params
    params.fetch(:consent, {}).permit(
      :parent_name,
      :parent_phone,
      :parent_relationship,
      :parent_relationship_other
    )
  end

  def consent_agree_params
    params.fetch(:consent, {}).permit(:response)
  end

  def consent_reason_params
    params.fetch(:consent, {}).permit(
      :reason_for_refusal,
      :reason_for_refusal_other
    )
  end

  def consent_health_questions_params
    params.fetch(:consent, {}).permit(
      question_0: %i[notes response],
      question_1: %i[notes response],
      question_2: %i[notes response],
      question_3: %i[notes response]
    )
  end

  def consent_triage_params
    params.fetch(:consent, {}).permit(triage: %i[notes status])
  end
end
