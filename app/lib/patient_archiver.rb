# frozen_string_literal: true

class PatientArchiver
  def initialize(patient:, team:, type:, other_details: nil)
    @patient = patient
    @team = team
    @type = type
    @other_details = other_details
  end

  def call
    ActiveRecord::Base.transaction do
      if type == "other"
        archive_reason.update!(type:, other_details:)
      else
        archive_reason.update!(type:, other_details: "")
      end

      patient.clear_pending_sessions!(team:)
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :patient, :team, :type, :other_details

  def archive_reason
    @archive_reason ||= ArchiveReason.find_or_create_by(team:, patient:)
  end
end
