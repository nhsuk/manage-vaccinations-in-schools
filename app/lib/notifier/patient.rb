# frozen_string_literal: true

class Notifier::Patient
  extend ActiveSupport::Concern

  def initialize(patient)
    @patient = patient
  end

  ##
  # Send a consent request email and SMS to the parents of this patient.
  def send_consent_request(programmes, session:, sent_by:)
    send_consent_notification(programmes, type: :request, session:, sent_by:)
  end

  ##
  # Send a consent reminder email and SMS to the parents of this patient.
  #
  # This determines whether to send the initial reminder or subsequent
  # reminder based on what has already been sent to this patient.
  def send_consent_reminder(programmes, session:, sent_by:)
    already_sent_initial_reminder =
      programmes.all? do |programme|
        patient
          .consent_notifications
          .select { it.programmes.include?(programme) }
          .any?(&:initial_reminder?)
      end

    type =
      already_sent_initial_reminder ? :subsequent_reminder : :initial_reminder

    send_consent_notification(programmes, type:, session:, sent_by:)
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
      programme_types_to_send_clinic_invitation_for(
        programmes,
        team:,
        academic_year:,
        include_vaccinated_programmes:,
        include_already_invited_programmes:
      )

    return if programme_types.empty?

    type = clinic_invitation_type(programme_types, team:, academic_year:)

    ClinicNotification.create!(
      patient:,
      programme_types:,
      team:,
      academic_year:,
      type:,
      sent_at: Time.current,
      sent_by:
    )

    template_name = find_clinic_template_name(type, team:)

    params = { academic_year:, patient:, programme_types:, sent_by:, team: }

    parents.each do |parent|
      EmailDeliveryJob.perform_later(template_name, parent:, **params)
      SMSDeliveryJob.perform_later(template_name, parent:, **params)
    end
  end

  private

  attr_reader :patient

  def send_notification?(team:)
    patient.send_notifications?(team:) && parents.present?
  end

  def parents
    @parents ||= patient.parents.select(&:contactable?).uniq
  end

  def filter_programmes_notify_parents(programmes)
    programmes.select do |programme|
      patient.vaccination_records.none? do
        it.notify_parents == false && it.programme == programme
      end
    end
  end

  def send_consent_notification(programmes, type:, session:, sent_by:)
    return unless send_notification?(team: session.team)

    programmes_to_send_for = filter_programmes_notify_parents(programmes)

    return if programmes_to_send_for.empty?

    ConsentNotification.create!(
      programmes: programmes_to_send_for,
      patient:,
      session:,
      type:,
      sent_at: Time.current,
      sent_by:
    )

    email_template, sms_template =
      generate_consent_templates(
        programmes: programmes_to_send_for,
        patient:,
        session:,
        type:
      )

    programme_types = programmes_to_send_for.map(&:type)
    disease_types = programmes_to_send_for.flat_map(&:disease_types).presence

    parents.each do |parent|
      EmailDeliveryJob.perform_later(
        email_template,
        disease_types:,
        parent:,
        patient:,
        programme_types:,
        session:,
        sent_by:
      )

      SMSDeliveryJob.perform_later(
        sms_template,
        disease_types:,
        parent:,
        patient:,
        programme_types:,
        session:,
        sent_by:
      )
    end
  end

  def generate_consent_templates(programmes:, patient:, session:, type:)
    is_school = session.location.school?
    base_template = :"consent_#{is_school ? "school" : "clinic"}_#{type}"

    # We can only handle a single programme group or variant in the template.
    group = ProgrammeGrouper.call(programmes).keys.sole
    variant =
      if programmes.count == 1
        programmes.sole.variant_for(patient:).variant_type
      end

    email_template =
      if is_school
        template =
          resolve_consent_template(
            base_template:,
            group:,
            variant:,
            session:,
            channel: :email
          )
        if template.blank?
          raise(
            "Missing email template for consent notification: #{base_template} " \
              "with group=#{group.inspect} variant=#{variant.inspect} " \
              "outbreak=#{is_outbreak.inspect}"
          )
        end
        template
      else
        base_template
      end

    sms_template =
      if type == :request
        template =
          resolve_consent_template(
            base_template:,
            group:,
            variant:,
            session:,
            channel: :sms
          )
        template || base_template
      elsif is_school
        :consent_school_reminder
      end

    [email_template, sms_template]
  end

  def resolve_consent_template(
    base_template:,
    group:,
    variant:,
    session:,
    channel:
  )
    renderer = NotifyTemplateRenderer.for(channel)
    is_outbreak = session.outbreak

    combinations = [([group, :outbreak] if is_outbreak), [group]]
    if variant.present? && variant != group
      combinations.prepend(([variant, :outbreak] if is_outbreak), [variant])
    end
    combinations.compact!

    combinations
      .lazy
      .map { |parts| :"#{base_template}_#{parts.join("_")}" }
      .detect { renderer.template_exists?(it, source: :any) }
  end

  def programme_types_to_send_clinic_invitation_for(
    programmes,
    team:,
    academic_year:,
    include_vaccinated_programmes: false,
    include_already_invited_programmes: true
  )
    programmes_to_send_for =
      filter_programmes_notify_parents(programmes).select do |programme|
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

  def find_clinic_template_name(type, team:)
    template_names = [
      :"clinic_#{type}_#{team.organisation.ods_code.downcase}",
      :"clinic_#{type}"
    ]

    template_names.find { GOVUK_NOTIFY_EMAIL_TEMPLATES.key?(it) }
  end
end
