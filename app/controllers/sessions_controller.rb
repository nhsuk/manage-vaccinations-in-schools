class SessionsController < ApplicationController
  before_action :set_session, only: %i[show make_in_progress]
  before_action :set_school, only: %i[show]

  layout "two_thirds", except: %i[index show]

  def create
    @session = Session.create! draft: true

    redirect_to session_edit_path(@session, :location)
  end

  def index
    @sessions_by_type = policy_scope(Session).active.group_by(&:type)
  end

  def show
    @patient_sessions =
      @session.patient_sessions.strict_loading.includes(:campaign, :consents)

    @counts = {
      with_consent_given: 0,
      with_consent_refused: 0,
      without_a_response: 0,
      needing_triage: 0,
      ready_to_vaccinate: 0,
      unmatched_responses: @session.location.consent_forms.unmatched.count
    }

    @patient_sessions.each do |s|
      @counts[:with_consent_given] += 1 if s.consent_given?
      @counts[:with_consent_refused] += 1 if s.consent_refused?
      @counts[:without_a_response] += 1 if s.no_consent?

      if s.consent_given_triage_needed? || s.triaged_kept_in_triage?
        @counts[:needing_triage] += 1
        @counts[:ready_to_vaccinate] += 1
      end

      @counts[:ready_to_vaccinate] += 1 if s.triaged_ready_to_vaccinate? ||
        s.added_to_session? || s.consent_given_triage_not_needed?
    end
  end

  def make_in_progress
    @session.update!(date: Time.zone.today)
    redirect_to session_path,
                flash: {
                  success: {
                    heading: "Session is now in progress"
                  }
                }
  end

  private

  def set_session
    @session = policy_scope(Session).find(params[:id])
  end

  def set_school
    @school = @session.location
  end
end
