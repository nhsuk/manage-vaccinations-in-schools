# frozen_string_literal: true

# == Schema Information
#
# Table name: triage
#
#  id                   :bigint           not null, primary key
#  invalidated_at       :datetime
#  notes                :text             default(""), not null
#  status               :integer          not null
#  vaccine_method       :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  organisation_id      :bigint           not null
#  patient_id           :bigint           not null
#  performed_by_user_id :bigint           not null
#  programme_id         :bigint           not null
#
# Indexes
#
#  index_triage_on_organisation_id       (organisation_id)
#  index_triage_on_patient_id            (patient_id)
#  index_triage_on_performed_by_user_id  (performed_by_user_id)
#  index_triage_on_programme_id          (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (performed_by_user_id => users.id)
#  fk_rails_...  (programme_id => programmes.id)
#
class Triage < ApplicationRecord
  include BelongsToAcademicYear
  include Invalidatable

  self.table_name = "triage"

  audited associated_with: :patient

  belongs_to :patient
  belongs_to :programme
  belongs_to :organisation

  belongs_to :performed_by,
             class_name: "User",
             foreign_key: :performed_by_user_id

  enum :status,
       {
         ready_to_vaccinate: 0,
         do_not_vaccinate: 1,
         needs_follow_up: 2,
         delay_vaccination: 3
       },
       validate: true

  enum :vaccine_method,
       { injection: 0, nasal: 1 },
       validate: {
         if: :ready_to_vaccinate?
       }

  encrypts :notes

  academic_year_attribute :created_at
end
