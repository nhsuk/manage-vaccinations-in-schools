# frozen_string_literal: true

class Notifier::Patient
  extend ActiveSupport::Concern

  def initialize(patient)
    @patient = patient
  end

  ##
  # Send a clinic initiation email and SMS to the parents of this patient.
  #
  # This determines the correct type of invitation to use (either an initial
  # invitation or a subsequent invitation) based on the previous invitations
  # which have been sent:
  #
  # +include_vaccinated_programmes+ allows for the sending of invitations for
  # programmes where the patient has already been vaccinated.
  #
  # +include_already_invited_programmes+ allows for the sending of invitations
  # for programmes where the patient has already been invited for in the past.
  #
  def send_clinic_invitation(
    programmes,
    team:,
    academic_year:,
    sent_by:,
    include_vaccinated_programmes: false,
    include_already_invited_programmes: true
  )
    return unless send_notification?(team:)

    programme_types =
      programme_types_to_send_for(
        programmes,
        team:,
        academic_year:,
        include_vaccinated_programmes:,
        include_already_invited_programmes:
      )

    return if programme_types.empty?

    type = clinic_invitation_type(programme_types, team:, academic_year:)

    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    ClinicNotification.create!(
      patient:,
      programme_types:,
      team:,
      academic_year:,
      type:,
      sent_at: Time.current,
      sent_by:
    )

    template_name = find_template_name(type, team:)

    params = { academic_year:, patient:, programme_types:, sent_by:, team: }

    parents.each do |parent|
      EmailDeliveryJob.perform_later(template_name, parent:, **params)
      SMSDeliveryJob.perform_later(template_name, parent:, **params)
    end
  end

  private

  attr_reader :patient

  def send_notification?(team:)
    patient.send_notifications?(team:, send_to_archived: true) &&
      parents.present?
  end

  def parents
    @parents ||= patient.parents.select(&:contactable?).uniq
  end

  def programme_types_to_send_for(
    programmes,
    team:,
    academic_year:,
    include_vaccinated_programmes: false,
    include_already_invited_programmes: true
  )
    programmes_to_send_for =
      programmes.select do |programme|
        unless include_vaccinated_programmes
          is_vaccinated =
            patient.programme_status(programme, academic_year:).vaccinated?

          next false if is_vaccinated
        end

        unless include_already_invited_programmes
          already_invited =
            patient.clinic_notifications.any? do
              it.team_id == team.id && it.academic_year == academic_year &&
                it.programme_types.include?(programme.type)
            end

          next false if already_invited
        end

        true
      end

    programmes_to_send_for.map(&:type)
  end

  def clinic_invitation_type(programme_types, team:, academic_year:)
    already_sent_initial_invitation_to_all_programmes =
      programme_types.all? do |programme_type|
        patient.clinic_notifications.any? do
          it.team_id == team.id && it.academic_year == academic_year &&
            it.initial_invitation? &&
            it.programme_types.include?(programme_type)
        end
      end

    if already_sent_initial_invitation_to_all_programmes
      :subsequent_invitation
    else
      :initial_invitation
    end
  end

  def find_template_name(type, team:)
    template_names = [
      :"clinic_#{type}_#{team.organisation.ods_code.downcase}",
      :"clinic_#{type}"
    ]

    template_names.find { GOVUK_NOTIFY_EMAIL_TEMPLATES.key?(it) }
  end
end
