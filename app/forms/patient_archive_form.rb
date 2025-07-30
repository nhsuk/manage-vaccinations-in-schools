# frozen_string_literal: true

class PatientArchiveForm
  include PatientMergeFormConcern

  attr_accessor :current_user, :archive_reason

  attribute :other_details, :string
  attribute :type, :string

  validates :nhs_number, nhs_number: true, if: :duplicate?

  validates :other_details,
            presence: true,
            length: {
              maximum: 300
            },
            if: :other?

  validates :type,
            inclusion: {
              in: %w[duplicate imported_in_error moved_out_of_area other]
            }

  def save
    return false unless valid?

    if duplicate?
      super
    elsif other?
      archive_reason.update!(type:, other_details:)
    else
      archive_reason.update!(type:, other_details: "")
    end
  end

  def duplicate? = type == "duplicate"

  def other? = type == "other"

  delegate :organisation, :patient, to: :archive_reason
end
