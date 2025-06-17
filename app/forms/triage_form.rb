# frozen_string_literal: true

class TriageForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :patient_session, :programme, :current_user

  attribute :status, :string
  attribute :notes, :string

  validates :status, inclusion: { in: Triage.statuses.keys }
  validates :notes, length: { maximum: 1000 }

  def save
    Triage.create!(triage_attributes) if valid?
  end

  def save!
    Triage.create!(triage_attributes)
  end

  private

  delegate :organisation, :patient, to: :patient_session

  def triage_attributes
    {
      notes:,
      organisation:,
      patient:,
      performed_by: current_user,
      programme:,
      status:,
      vaccine_method: "injection"
    }
  end
end
