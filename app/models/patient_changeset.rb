# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_changesets
#
#  id              :bigint           not null, primary key
#  import_type     :string           not null
#  pending_changes :jsonb            not null
#  row_number      :integer          not null
#  status          :integer          default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  import_id       :bigint           not null
#  patient_id      :bigint
#  school_id       :bigint
#
# Indexes
#
#  index_patient_changesets_on_import      (import_type,import_id)
#  index_patient_changesets_on_patient_id  (patient_id)
#  index_patient_changesets_on_status      (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id)
#  fk_rails_...  (school_id => locations.id)
#
class PatientChangeset < ApplicationRecord
  attribute :pending_changes,
            :jsonb,
            default: {
              child: {
              },
              parent_1: {
              },
              parent_2: {
              },
              pds: {
              }
            }

  belongs_to :import, polymorphic: true
  belongs_to :school, class_name: "Location", optional: true

  enum :status, { pending: 0, processed: 1 }, validate: true

  def self.from_import_row(row:, import:, row_number:)
    create!(
      import:,
      row_number:,
      pending_changes: {
        child: row.import_attributes,
        parent_1_relationship: row.parent_1_relationship,
        parent_1: {
          name: row.parent_1_name,
          email: row.parent_1_email,
          phone: row.parent_1_phone
        },
        parent_2_relationship: row.parent_2_relationship,
        parent_2: {
          name: row.parent_2_name,
          email: row.parent_2_email,
          phone: row.parent_2_phone
        }
      }
    )
  end
end
