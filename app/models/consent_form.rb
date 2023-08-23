# == Schema Information
#
# Table name: consent_forms
#
#  id          :bigint           not null, primary key
#  recorded_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  session_id  :bigint           not null
#
# Indexes
#
#  index_consent_forms_on_session_id  (session_id)
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id)
#

class ConsentForm < ApplicationRecord
  audited

  belongs_to :session
end
