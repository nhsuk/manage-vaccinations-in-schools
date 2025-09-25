# frozen_string_literal: true

class SessionProgrammesForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :session

  attribute :programme_ids, array: true, default: []

  validates :programme_ids, presence: true
  validate :cannot_remove_programmes

  def save
    return false if invalid?

    new_programme_ids = programme_ids - session.programme_ids

    ActiveRecord::Base.transaction do
      new_programme_ids.each do |programme_id|
        programme = Programme.find(programme_id)

        session.programmes << programme

        location = session.location

        next if location.location_programme_year_groups.exists?(programme:)
        session.location.create_default_programme_year_groups!(
          [programme],
          academic_year: session.academic_year
        )
      end
    end

    StatusUpdaterJob.perform_later(session:)

    true
  end

  def programme_ids=(values)
    super(values&.compact_blank&.map(&:to_i) || [])
  end

  private

  def cannot_remove_programmes
    if (session.programme_ids - programme_ids).present?
      errors.add(:programme_ids, :inclusion)
    end
  end
end
