# frozen_string_literal: true

module ParentInterface
  class ConsentFormsController < ConsentForms::BaseController
    include ConsentFormMailerConcern

    skip_before_action :set_consent_form, only: %i[start create deadline_passed]
    skip_before_action :authenticate_consent_form_user!,
                       only: %i[start create deadline_passed]

    before_action :clear_session_edit_variables, only: %i[confirm]
    before_action :check_if_past_deadline, except: %i[deadline_passed]

    def start
      # TODO: handle multiple programmes
      @programme = @session.programmes.first
    end

    def create
      # TODO: handle multiple programmes
      programme = @session.programmes.first

      consent_form = @session.consent_forms.create!(programme:)

      session[:consent_form_id] = consent_form.id

      redirect_to session_parent_interface_consent_form_edit_path(
                    @session,
                    consent_form,
                    :name
                  )
    end

    def cannot_consent_school
    end

    def cannot_consent_responsibility
    end

    def deadline_passed
    end

    def confirm
    end

    def record
      ActiveRecord::Base.transaction do
        @consent_form.update!(recorded_at: Time.zone.now)
      end

      session.delete(:consent_form_id)

      send_consent_form_confirmation(@consent_form)

      ConsentFormMatchingJob.perform_later(@consent_form)
    end

    private

    def clear_session_edit_variables
      session.delete(:follow_up_changes_start_page)
    end

    def check_if_past_deadline
      return if @session.open_for_consent?

      redirect_to action: :deadline_passed
    end
  end
end
