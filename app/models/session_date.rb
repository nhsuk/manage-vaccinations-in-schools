# frozen_string_literal: true

# == Schema Information
#
# Table name: session_dates
#
#  id         :bigint           not null, primary key
#  value      :date             not null
#  session_id :bigint           not null
#
# Indexes
#
#  index_session_dates_on_session_id_and_value  (session_id,value) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id)
#
class SessionDate < ApplicationRecord
  audited associated_with: :session

  belongs_to :session

  has_many :session_attendances, dependent: :restrict_with_error
  has_many :pre_screenings, dependent: :restrict_with_error

  scope :for_session, -> { where("session_id = sessions.id") }

  scope :today, -> { where(value: Date.current) }

  validates :value,
            uniqueness: {
              scope: :session
            },
            comparison: {
              greater_than_or_equal_to: :earliest_possible_value,
              less_than_or_equal_to: :latest_possible_value
            }

  delegate :today?, :past?, :future?, to: :value

  def today_or_past?
    today? || past?
  end

  def today_or_future?
    today? || future?
  end

  private

  def earliest_possible_value
    Date.new((session || Date.current).academic_year, 9, 1)
  end

  def latest_possible_value
    Date.new((session || Date.current).academic_year + 1, 8, 31)
  end
end
