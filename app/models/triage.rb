# frozen_string_literal: true

# == Schema Information
#
# Table name: triages
#
#  id                   :bigint           not null, primary key
#  academic_year        :integer          not null
#  invalidated_at       :datetime
#  notes                :text             default(""), not null
#  status               :integer          not null
#  vaccine_method       :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#  team_id              :bigint           not null
#
# Indexes
#
#  index_triages_on_academic_year         (academic_year)
#  index_triages_on_patient_id            (patient_id)
#  index_triages_on_performed_by_user_id  (performed_by_user_id)
#  index_triages_on_programme_id          (programme_id)
#  index_triages_on_team_id               (team_id)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#  fk_rails_...  (team_id => teams.id)
#
class Triage < ApplicationRecord
  include Invalidatable
  include Notable
  include PerformableByUser

  audited associated_with: :patient

  belongs_to :patient
  belongs_to :programme
  belongs_to :team

  enum :status,
       {
         safe_to_vaccinate: 0,
         do_not_vaccinate: 1,
         keep_in_triage: 2,
         delay_vaccination: 3
       },
       validate: true

  enum :vaccine_method,
       { injection: 0, nasal: 1 },
       validate: {
         if: :safe_to_vaccinate?
       }
end
