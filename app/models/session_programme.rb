# frozen_string_literal: true

# == Schema Information
#
# Table name: session_programmes
#
#  id           :bigint           not null, primary key
#  programme_id :bigint           not null
#  session_id   :bigint           not null
#
# Indexes
#
#  index_session_programmes_on_programme_id                 (programme_id)
#  index_session_programmes_on_session_id_and_programme_id  (session_id,programme_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (programme_id => programmes.id) ON DELETE => cascade
#  fk_rails_...  (session_id => sessions.id) ON DELETE => cascade
#
class SessionProgramme < ApplicationRecord
  audited associated_with: :session

  belongs_to :session
  belongs_to :programme
end
