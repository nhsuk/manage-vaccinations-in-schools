# frozen_string_literal: true

# == Schema Information
#
# Table name: class_imports
#
#  id                           :bigint           not null, primary key
#  changed_record_count         :integer
#  csv_data                     :text
#  csv_filename                 :text
#  csv_removed_at               :datetime
#  exact_duplicate_record_count :integer
#  new_record_count             :integer
#  recorded_at                  :datetime
#  rows_count                   :integer
#  serialized_errors            :json
#  status                       :integer          default("pending_import"), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  organisation_id              :bigint           not null
#  session_id                   :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_class_imports_on_organisation_id      (organisation_id)
#  index_class_imports_on_session_id           (session_id)
#  index_class_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (session_id => sessions.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class ClassImport < PatientImport
  include CSVImportable

  belongs_to :session

  has_and_belongs_to_many :parent_relationships
  has_and_belongs_to_many :parents

  private

  def parse_row(data)
    ClassImportRow.new(data:, session:)
  end

  def postprocess_rows!
    # Remove patients already in the session but not in the class list.

    return if session.closed?

    # Add newly imported patients to the session
    session.create_patient_sessions!

    # Remove unknown patients from the session and school
    unknown_patients = session.patients - patients

    session
      .patient_sessions
      .where(patient: unknown_patients, proposed_session_id: nil)
      .update_all(proposed_session_id: organisation.generic_clinic_session.id)
  end
end
