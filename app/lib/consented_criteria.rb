# frozen_string_literal: true

class ConsentedCriteria
  def initialize(programme:, patient:)
    @programme = programme
    @patient = patient
    @consents = patient.consents
  end

  def call
    consents_for_programme = consents.select { it.programme_id == programme.id }

    if programme.seasonal?
      consents_for_programme.any?(&:submitted_this_academic_year?)
    else
      return true if consents_for_programme.any?
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :programme, :patient, :consents
end
