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
FactoryBot.define do
  factory :session_date do
    session
    value { Date.current }
  end
end
