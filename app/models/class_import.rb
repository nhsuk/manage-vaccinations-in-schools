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
#  session_id                   :bigint           not null
#  team_id                      :bigint           not null
#  uploaded_by_user_id          :bigint           not null
#
# Indexes
#
#  index_class_imports_on_session_id           (session_id)
#  index_class_imports_on_team_id              (team_id)
#  index_class_imports_on_uploaded_by_user_id  (uploaded_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (session_id => sessions.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (uploaded_by_user_id => users.id)
#
class ClassImport < PatientImport
  include CSVImportable

  belongs_to :session

  has_and_belongs_to_many :parent_relationships
  has_and_belongs_to_many :parents
  has_and_belongs_to_many :patients

  private

  def parse_row(data)
    ClassImportRow.new(data:, session:)
  end

  def link_records(*records)
    records.each do |record|
      record.class_imports << self unless record.class_imports.exists?(id)
    end
  end

  def record_rows
    super

    session.create_patient_sessions! unless session.completed?

    (session.patients - patients).each do |unknown_patient|
      unknown_patient.update!(school: nil)
    end
  end
end
