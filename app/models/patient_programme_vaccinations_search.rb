# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_programme_vaccinations_searches
#
#  id               :bigint           not null, primary key
#  last_searched_at :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  patient_id       :bigint           not null
#  programme_id     :bigint           not null
#
# Indexes
#
#  idx_on_last_searched_at_96aaa59442                             (last_searched_at)
#  index_patient_programme_vaccinations_searches_on_patient_id    (patient_id)
#  index_patient_programme_vaccinations_searches_on_programme_id  (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (programme_id => programmes.id)
#
class PatientProgrammeVaccinationsSearch < ApplicationRecord
  belongs_to :patient
  belongs_to :programme
end
