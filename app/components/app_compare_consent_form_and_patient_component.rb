# frozen_string_literal: true

class AppCompareConsentFormAndPatientComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="nhsuk-grid-row nhsuk-card-group">
      <div class="nhsuk-grid-column-one-half nhsuk-card-group__item">
        <%= render AppCardComponent.new(heading_level: 2, colour: "blue") do |card| %>
          <% card.with_heading { "Consent response" } %>
          <%= govuk_summary_list(rows: consent_form_rows) %>
        <% end %>
      </div>

      <div class="nhsuk-grid-column-one-half nhsuk-card-group__item">
        <%= render AppCardComponent.new(heading_level: 2, colour: "blue") do |card| %>
          <% card.with_heading { "Child record" } %>
          <%= govuk_summary_list(rows: patient_rows) %>
        <% end %>
      </div>
    </div>
  ERB

  def initialize(consent_form:, patient:)
    @consent_form = consent_form
    @patient = patient
  end

  def consent_form_rows
    [
      {
        key: {
          text: "Full name"
        },
        value: {
          text: highlight(consent_form.full_name, unless: full_name_match?)
        }
      },
      if include_preferred_full_name_row?
        {
          key: {
            text: "Preferred name"
          },
          value: {
            text:
              highlight(
                consent_form.preferred_full_name,
                unless: preferred_full_name_match?
              )
          }
        }
      end,
      {
        key: {
          text: "Date of birth"
        },
        value: {
          text:
            highlight(
              consent_form.date_of_birth.to_fs(:long),
              unless: date_of_birth_match?
            )
        }
      },
      {
        key: {
          text: "Address"
        },
        value: {
          text:
            highlight(
              helpers.format_address_multi_line(consent_form),
              unless: address_match?
            )
        }
      },
      {
        key: {
          text: "School"
        },
        value: {
          text:
            highlight(
              helpers.patient_school(consent_form),
              unless: school_match?
            )
        }
      },
      {
        key: {
          text: "Parent"
        },
        value: {
          text:
            helpers.format_parent_with_relationship(
              consent_form.parent_relationship
            )
        }
      }
    ].compact
  end

  def patient_rows
    [
      { key: { text: "Full name" }, value: { text: patient.full_name } },
      if include_preferred_full_name_row?
        {
          key: {
            text: "Preferred name"
          },
          value: {
            text: patient.preferred_full_name
          }
        }
      end,
      {
        key: {
          text: "Date of birth"
        },
        value: {
          text: patient.date_of_birth.to_fs(:long)
        }
      },
      {
        key: {
          text: "Address"
        },
        value: {
          text: helpers.format_address_multi_line(patient)
        }
      },
      {
        key: {
          text: "School"
        },
        value: {
          text: helpers.patient_school(patient)
        }
      },
      if patient.parent_relationships.any?
        {
          key: {
            text: "Parents"
          },
          value: {
            text: helpers.patient_parents(patient)
          }
        }
      end
    ].compact
  end

  private

  attr_reader :heading, :consent_form, :patient

  def include_preferred_full_name_row?
    consent_form.has_preferred_name? || patient.has_preferred_name?
  end

  def full_name_match?
    consent_form.full_name == patient.full_name
  end

  def preferred_full_name_match?
    consent_form.preferred_full_name == patient.preferred_full_name
  end

  def date_of_birth_match?
    consent_form.date_of_birth == patient.date_of_birth
  end

  def address_match?
    consent_form.address_parts == patient.address_parts
  end

  def school_match?
    consent_form.home_educated == patient.home_educated &&
      consent_form.school == patient.school
  end

  def highlight(text, opts)
    opts[:unless] ? text : tag.mark(text, class: "app-highlight")
  end
end
