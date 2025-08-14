# frozen_string_literal: true

class DraftSessionDates
  include RequestSessionPersistable
  include WizardStepConcern
  include ActiveRecord::AttributeMethods::Serialization

  def request_session_key
    "draft_session_dates"
  end

  attribute :session_id, :integer
  attribute :current_user_id, :integer

  def initialize(current_user:, **attributes)
    @current_user = current_user
    super(**attributes)
  end

  serialize :session_dates_attributes_json, coder: JSON

  def wizard_steps
    %i[dates]
  end

  on_wizard_step :dates, exact: true do
    validate :validate_session_dates, on: %i[update continue]
  end

  def session
    return nil if session_id.nil?

    SessionPolicy::Scope.new(@current_user, Session).resolve.find(session_id)
  end

  def session=(value)
    self.session_id = value.id
  end

  def session_dates
    @session_dates ||= build_session_dates_from_attributes
  end

  def non_destroyed_session_dates_count
    session_dates_attributes.count { |_, attrs| attrs["_destroy"] != "true" }
  end

  def session_dates_attributes
    @session_dates_attributes ||=
      JSON.parse(session_dates_attributes_json || "{}")
  end

  def session_dates_attributes=(attributes)
    @session_dates_attributes = attributes
    self.session_dates_attributes_json = attributes
    @session_dates = nil # Reset cached session dates
  end

  def write_to!(session)
    return unless session_id == session.id

    ActiveRecord::Base.transaction do
      delete_marked_session_dates(session)
      create_or_update_session_dates(session)
      update_session_notifications(session)
    end
  end

  private

  def delete_marked_session_dates(session)
    session_dates_attributes.each_value do |attrs|
      next unless attrs["_destroy"] == "true" && attrs["id"].present?

      session_date = session.session_dates.find_by(id: attrs["id"])
      session_date&.destroy! unless session_date&.session_attendances&.any?
    end
  end

  def create_or_update_session_dates(session)
    session_dates_attributes.each_value do |attrs|
      next if attrs["_destroy"] == "true"

      date_value = parse_date_from_attributes(attrs)
      next unless date_value

      if attrs["id"].present?
        update_existing_session_date(session, attrs["id"], date_value)
      else
        session.session_dates.create!(value: date_value)
      end
    end
  end

  def update_existing_session_date(session, id, date_value)
    session_date = session.session_dates.find_by(id: id)
    session_date&.update!(value: date_value)
  end

  def update_session_notifications(session)
    session.set_notification_dates
    session.save!
  end

  def reset_unused_fields
    # No unused fields to reset for session dates
  end

  def build_session_dates_from_attributes
    dates = []

    if session_dates_attributes.present?
      session_dates_attributes.each_value do |attrs|
        next if attrs["_destroy"] == "true"

        if attrs["id"].present?
          existing_date = session&.session_dates&.find_by(id: attrs["id"])
          parsed_date = parse_date_from_attributes(attrs)
          dates << DraftSessionDate.new(
            id: attrs["id"],
            value: parsed_date || existing_date.value,
            session: session,
            persisted: true
          )
        else
          parsed_date = parse_date_from_attributes(attrs)
          dates << DraftSessionDate.new(
            value: parsed_date,
            session: session,
            persisted: false
          )
        end
      end
    end

    dates
  end

  class DraftSessionDate
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :id, :integer
    attribute :value, :date

    attr_accessor :session, :persisted_state

    def initialize(session:, persisted: false, **attributes)
      @session = session
      @persisted_state = persisted
      super(attributes)
    end

    def persisted?
      @persisted_state
    end

    def session_attendances
      return [] unless persisted? && id

      session&.session_dates&.find_by(id: id)&.session_attendances || []
    end
  end

  def parse_date_from_attributes(attrs)
    return attrs["value"] if attrs["value"].is_a?(Date)

    if attrs["value(1i)"] && attrs["value(2i)"] && attrs["value(3i)"]
      begin
        Date.new(
          attrs["value(1i)"].to_i,
          attrs["value(2i)"].to_i,
          attrs["value(3i)"].to_i
        )
      rescue StandardError
        nil
      end
    end
  end

  def validate_session_dates
    attrs_hash = session_dates_attributes

    accepted_dates = []
    has_valid_date = false

    attrs_hash.each_value do |attrs|
      next if attrs["_destroy"] == "true"

      date_value = parse_date_from_attributes(attrs)

      if date_value.nil?
        if attrs["value(1i)"].present? || attrs["value(2i)"].present? ||
             attrs["value(3i)"].present? || attrs["value"].present?
          errors.add(:base, "Enter a valid date")
        end
        next
      end

      has_valid_date = true

      if accepted_dates.include?(date_value)
        errors.add(:base, "Session dates must be unique")
        next
      end

      accepted_dates << date_value
    end

    errors.add(:base, "Enter a date") unless has_valid_date
  end
end
