# frozen_string_literal: true

# == Schema Information
#
# Table name: archive_reasons
#
#  id                 :bigint           not null, primary key
#  other_details      :string           default(""), not null
#  type               :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  created_by_user_id :bigint
#  patient_id         :bigint           not null
#  team_id            :bigint           not null
#
# Indexes
#
#  index_archive_reasons_on_created_by_user_id      (created_by_user_id)
#  index_archive_reasons_on_patient_id              (patient_id)
#  index_archive_reasons_on_patient_id_and_team_id  (patient_id,team_id) UNIQUE
#  index_archive_reasons_on_team_id                 (team_id)
#  index_archive_reasons_on_team_id_and_patient_id  (team_id,patient_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (created_by_user_id => users.id)
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (team_id => teams.id)
#
class ArchiveReason < ApplicationRecord
  include ContributesToPatientTeams

  class ActiveRecord_Relation < ActiveRecord::Relation
    include ContributesToPatientTeams::Relation
  end

  self.inheritance_column = nil

  belongs_to :team
  belongs_to :patient
  belongs_to :created_by,
             class_name: "User",
             foreign_key: :created_by_user_id,
             optional: true

  enum :type,
       { imported_in_error: 0, moved_out_of_area: 1, deceased: 2, other: 3 },
       validate: true

  validates :other_details,
            presence: true,
            length: {
              maximum: 300
            },
            if: :other?
  validates :other_details, absence: true, unless: :other?
end
