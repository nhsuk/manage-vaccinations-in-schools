# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_notifications
#
#  id              :bigint           not null, primary key
#  programme_types :enum             not null, is an Array
#  sent_at         :datetime         not null
#  type            :integer          not null
#  patient_id      :bigint           not null
#  sent_by_user_id :bigint
#  session_id      :bigint           not null
#
# Indexes
#
#  index_consent_notifications_on_patient_id       (patient_id)
#  index_consent_notifications_on_programme_types  (programme_types) USING gin
#  index_consent_notifications_on_sent_by_user_id  (sent_by_user_id)
#  index_consent_notifications_on_session_id       (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (sent_by_user_id => users.id)
#  fk_rails_...  (session_id => sessions.id)
#
class ConsentNotification < ApplicationRecord
  include HasManyProgrammes
  include Sendable

  self.inheritance_column = nil

  belongs_to :patient
  belongs_to :session

  has_one :team, through: :session

  delegate :academic_year, to: :session

  enum :type,
       { request: 0, initial_reminder: 1, subsequent_reminder: 2 },
       validate: true

  scope :reminder, -> { initial_reminder.or(subsequent_reminder) }

  def reminder? = initial_reminder? || subsequent_reminder?

  def sent_by_user? = sent_by != nil

  def sent_by_background_job? = sent_by.nil?

  def automated_reminder? = sent_by_background_job? && reminder?

  def manual_reminder? = sent_by_user? && reminder?

  def self.create_and_send!(
    patient:,
    programmes:,
    session:,
    type:,
    current_user: nil
  )
    parents = patient.parents.select(&:contactable?)

    return if parents.empty?

    # We create a record in the database first to avoid sending duplicate emails/texts.
    # If a problem occurs while the emails/texts are sent, they will be in the job
    # queue and restarted at a later date.

    ConsentNotification.create!(
      programmes:,
      patient:,
      session:,
      type:,
      sent_at: Time.current,
      sent_by: current_user
    )

    email_template, sms_template =
      generate_templates(programmes:, patient:, session:, type:)

    programme_types = programmes.map(&:type)
    disease_types = programmes.flat_map(&:disease_types).presence

    parents.each do |parent|
      EmailDeliveryJob.perform_later(
        email_template,
        disease_types:,
        parent:,
        patient:,
        programme_types:,
        session:,
        sent_by: current_user
      )

      SMSDeliveryJob.perform_later(
        sms_template,
        disease_types:,
        parent:,
        patient:,
        programme_types:,
        session:,
        sent_by: current_user
      )
    end
  end

  def self.generate_templates(programmes:, patient:, session:, type:)
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
          resolve_template(
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
          resolve_template(
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

  def self.resolve_template(
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
end
