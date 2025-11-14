# frozen_string_literal: true

# == Schema Information
#
# Table name: session_programme_year_groups
#
#  programme_type :enum             not null, primary key
#  year_group     :integer          not null, primary key
#  session_id     :bigint           not null, primary key
#
# Indexes
#
#  index_session_programme_year_groups_on_session_id  (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id) ON DELETE => cascade
#
class SessionProgrammeYearGroup < ApplicationRecord
  self.primary_key = %i[session_id programme_type year_group]

  belongs_to :session

  scope :pluck_year_groups,
        -> { distinct.order(:year_group).pluck(:year_group) }

  scope :pluck_birth_academic_years,
        -> do
          joins(:session)
            .distinct
            .order(:"sessions.academic_year", :year_group)
            .pluck(:"sessions.academic_year", :year_group)
            .map { _2.to_birth_academic_year(academic_year: _1) }
        end

  delegate :academic_year, to: :session

  def programme=(value)
    self.programme_type = value.type
  end
end
