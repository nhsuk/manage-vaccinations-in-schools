# frozen_string_literal: true

class AppPatientSummaryComponent < ViewComponent::Base
  erb_template <<-ERB
    <h3 class="nhsuk-heading-s nhsuk-u-margin-top-1">
      <%= patient.full_name %>
    </h3>
    
    <%= govuk_summary_list(rows:, classes:) %>
    
    <p class="nhsuk-body">
      <%= link_to "View full child record", patient_path(patient) %>
    </p>
  ERB

  def initialize(patient)
    super

    @patient = patient
  end

  private

  attr_reader :patient

  def rows
    [date_of_birth_row, address_row]
  end

  def classes
    %w[
      nhsuk-summary-list--no-border
      app-summary-list--full-width
      nhsuk-u-margin-bottom-2
    ]
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

  def address_row
    {
      key: {
        text: "Address"
      },
      value: {
        text: helpers.format_address_multi_line(patient)
      }
    }
  end
end
