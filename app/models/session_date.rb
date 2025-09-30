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

  has_many :gillick_assessments, dependent: :restrict_with_error
  has_many :pre_screenings, dependent: :restrict_with_error

  has_one :location, through: :session
  has_many :attendance_records, -> { where(date: it.value) }, through: :location

  scope :for_session, -> { where("session_id = sessions.id") }

  scope :today, -> { where(value: Date.current) }

  delegate :today?, :past?, :future?, to: :value

  def today_or_past? = today? || past?

  def today_or_future? = today? || future?

  def has_been_attended?
    gillick_assessments.any? || pre_screenings.any? || attendance_records.any?
  end
end
