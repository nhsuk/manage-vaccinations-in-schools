# frozen_string_literal: true

class AppPatientSessionCardComponent < ViewComponent::Base
  def initialize(patient_session, programme:)
    super

    @patient_session = patient_session
    @programme = programme
  end

  def call
    render AppCardComponent.new(patient: true) do |card|
      card.with_heading { patient.full_name }
      govuk_summary_list(rows:)
    end
  end

  private

  attr_reader :patient_session, :programme

  delegate :patient, to: :patient_session

  def rows
    [date_of_birth_row, year_group_row, status_row]
  end

  def date_of_birth_row
    {
      key: {
        text: "Date of birth"
      },
      value: {
        text: patient.date_of_birth.to_fs(:long)
      }
    }
  end

  def year_group_row
    {
      key: {
        text: "Year group"
      },
      value: {
        text: helpers.format_year_group(patients.year_group)
      }
    }
  end

  def status_row
    {
      key: {
        text: "Status"
      },
      value: {
        text: patient_session.status(programme:)
      }
    }
  end
end
