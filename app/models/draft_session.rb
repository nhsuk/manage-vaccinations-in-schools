# frozen_string_literal: true

class DraftSession
  include RequestSessionPersistable
  include EditableWrapper
  include WizardStepConcern

  include ActiveRecord::AttributeMethods::Serialization
  include Consentable
  include DaysBeforeToWeeksBefore
  include Delegatable

  attribute :days_before_consent_reminders, :integer
  attribute :location_id, :integer
  attribute :national_protocol_enabled, :boolean
  attribute :programme_ids, array: true, default: []
  attribute :psd_enabled, :boolean
  attribute :requires_registration, :boolean
  attribute :send_consent_requests_at, :date
  attribute :send_invitations_at, :date
  attribute :session_dates, array: true, default: []

  serialize :session_dates, coder: DraftSessionDate::ArraySerializer

  def initialize(current_user:, **attributes)
    @current_user = current_user
    super(**attributes)
  end

  def wizard_steps
    steps = %i[dates programmes]

    if include_notification_steps?
      steps += %i[consent_requests consent_reminders] if location.school?
      steps << :invitations if location.clinic?
    end

    steps << :register_attendance

    steps << :delegation if supports_delegation?

    steps + %i[confirm]
  end

  on_wizard_step :dates, exact: true do
    validate :valid_session_dates
  end

  on_wizard_step :programmes, exact: true do
    validates :programme_ids, presence: true
    validate :cannot_remove_programmes
  end

  on_wizard_step :consent_requests, exact: true do
    validates :send_consent_requests_at,
              presence: true,
              comparison: {
                greater_than_or_equal_to: :earliest_send_notifications_at,
                less_than_or_equal_to: :latest_send_consent_requests_at
              }
  end

  on_wizard_step :consent_reminders, exact: true do
    validates :weeks_before_consent_reminders,
              presence: true,
              comparison: {
                greater_than_or_equal_to: 1,
                less_than_or_equal_to: :maximum_weeks_before_consent_reminders
              }
  end

  on_wizard_step :invitations, exact: true do
    validates :send_invitations_at,
              presence: true,
              comparison: {
                greater_than_or_equal_to: :earliest_send_notifications_at,
                less_than: :earliest_date
              }
  end

  def session
    return nil if editing_id.nil?

    @session ||=
      SessionPolicy::Scope.new(@current_user, Session).resolve.find(editing_id)
  end

  def location
    return nil if location_id.nil?

    @location ||=
      LocationPolicy::Scope
        .new(@current_user, Location)
        .resolve
        .find(location_id)
  end

  def programmes
    ProgrammePolicy::Scope
      .new(@current_user, Programme)
      .resolve
      .where(id: programme_ids)
  end

  def programme_ids=(values)
    super(values&.compact_blank&.map(&:to_i) || [])
  end

  def dates = session_dates.map(&:value).compact

  def set_notification_dates
    if earliest_date
      if location.clinic?
        self.days_before_consent_reminders = nil
        self.send_consent_requests_at = nil
        self.send_invitations_at =
          earliest_date - team.days_before_invitations.days
      else
        self.days_before_consent_reminders = team.days_before_consent_reminders
        self.send_consent_requests_at =
          earliest_date - team.days_before_consent_requests.days
        self.send_invitations_at = nil
      end
    else
      self.days_before_consent_reminders = nil
      self.send_consent_requests_at = nil
      self.send_invitations_at = nil
    end
  end

  def read_from!(session)
    self.session_dates =
      session.session_dates.map do |session_date|
        DraftSessionDate.new(id: session_date.id, value: session_date.value)
      end

    session_dates << SessionDate.new if session_dates.empty?

    super(session)
  end

  def write_to!(session)
    super(session)

    new_programme_ids.each do |programme_id|
      session.session_programmes.build(programme_id:)
    end

    session.session_dates.each do |session_date|
      unless session_dates.any? { it.id == session_date.id }
        session_date.mark_for_destruction
      end
    end

    session_dates.each do |session_date|
      value = session_date.value

      if session_date.persisted?
        session.session_dates.find { it.id == session_date.id }.value = value
      elsif value.present?
        session.session_dates.build(value:)
      end
    end
  end

  def create_location_programme_year_groups!
    new_programmes =
      new_programme_ids
        .map { Programme.find(it) }
        .reject do |programme|
          location.location_programme_year_groups.exists?(programme:)
        end

    location.create_default_programme_year_groups!(
      new_programmes,
      academic_year:
    )
  end

  private

  delegate :academic_year, :team, to: :session

  def request_session_key = "session"

  def readable_attribute_names
    super - %w[session_dates]
  end

  def writable_attribute_names
    super - %w[location_id session_dates programme_ids]
  end

  def include_notification_steps?
    dates.present? && session.consent_notifications.empty? &&
      session.session_notifications.empty?
  end

  def new_programme_ids
    @new_programme_ids ||= programme_ids - session.programme_ids
  end

  def valid_session_dates
    session_dates.each_with_index do |session_date, index|
      value = session_date.value

      next if value.nil?

      if value < earliest_possible_session_date_value
        session_date.errors.add(
          :value,
          :greater_than_or_equal_to,
          count: earliest_possible_session_date_value
        )
      elsif value > latest_possible_session_date_value
        session_date.errors.add(
          :value,
          :less_than_or_equal_to,
          count: latest_possible_session_date_value
        )
      elsif session_dates[...index].any? { it.value == value }
        session_date.errors.add(:value, :taken)
      end
    end

    return if session_dates.all? { it.errors.empty? }

    session_dates.each_with_index do |session_date, index|
      session_date.errors.messages.each do |field, messages|
        messages.each do |message|
          errors.add("session-date-#{index}-#{field}", message)
        end
      end
    end
  end

  def cannot_remove_programmes
    if (session.programme_ids - programme_ids).present?
      errors.add(:programme_ids, :inclusion)
    end
  end

  def earliest_date = dates.min

  def earliest_send_notifications_at
    earliest_date - 3.months
  end

  def latest_send_consent_requests_at
    earliest_date - days_before_consent_reminders.days - 1
  end

  def maximum_weeks_before_consent_reminders
    return nil if earliest_date.nil? || send_consent_requests_at.nil?
    (earliest_date - send_consent_requests_at).to_i / 7
  end

  def earliest_possible_session_date_value
    Date.new(@session.academic_year, 9, 1)
  end

  def latest_possible_session_date_value
    Date.new(@session.academic_year + 1, 8, 31)
  end
end
