# frozen_string_literal: true

class AppVaccinationCheckAndConfirmComponent < ViewComponent::Base
  def initialize(vaccination_record, current_user:, change_links: {})
    super

    @vaccination_record = vaccination_record
    @batch = vaccination_record.batch
    @patient = vaccination_record.patient
    @session = vaccination_record.session
    @vaccine = vaccination_record.vaccine

    @current_user = current_user
    @change_links = change_links
  end

  def call
    govuk_summary_list(
      actions: @change_links.present?,
      classes: "app-summary-list--no-bottom-border"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Child" }
        row.with_value { @patient.full_name }
      end

      if @vaccination_record.administered?
        summary_list.with_row do |row|
          row.with_key { "Vaccine" }
          row.with_value { @vaccination_record.programme.name }
        end

        summary_list.with_row do |row|
          row.with_key { "Brand" }
          row.with_value { "#{@vaccine.brand} (#{@vaccine.method})" }
        end

        summary_list.with_row do |row|
          row.with_key { "Batch" }
          row.with_value do
            "#{@batch.name} (expires #{@batch.expiry.to_fs(:long)})"
          end
          if (href = @change_links[:batch])
            row.with_action(
              text: "Change",
              href:,
              visually_hidden_text: "batch"
            )
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Method" }
          row.with_value do
            @vaccination_record.human_enum_name(:delivery_method)
          end
          if (href = @change_links[:delivery_method])
            row.with_action(
              text: "Change",
              href:,
              visually_hidden_text: "method"
            )
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Site" }
          row.with_value { @vaccination_record.human_enum_name(:delivery_site) }
          if (href = @change_links[:delivery_site])
            row.with_action(text: "Change", href:, visually_hidden_text: "site")
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Outcome" }
          row.with_value { "Vaccinated" }

          if (href = @change_links[:outcome])
            row.with_action(
              text: "Change",
              href:,
              visually_hidden_text: "outcome"
            )
          end
        end
      else
        summary_list.with_row do |row|
          row.with_key { "Outcome" }
          row.with_value { @vaccination_record.human_enum_name(:reason) }

          if (href = @change_links[:outcome])
            row.with_action(
              text: "Change",
              href:,
              visually_hidden_text: "outcome"
            )
          end
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Date" }
        row.with_value { "Today (#{Date.current.to_fs(:long)})" }
      end

      summary_list.with_row do |row|
        row.with_key { "Time" }
        row.with_value { Time.current.to_fs(:time) }
      end

      summary_list.with_row do |row|
        row.with_key { "Location" }
        row.with_value { @session.location.name }

        if (href = @change_links[:location])
          row.with_action(
            text: "Change",
            href:,
            visually_hidden_text: "location"
          )
        end
      end

      if vaccinator
        summary_list.with_row do |row|
          row.with_key { "Vaccinator" }
          row.with_value { vaccinator }
        end
      end
    end
  end

  private

  def vaccinator
    @vaccinator ||=
      if @vaccination_record.performed_by == @current_user
        "You (#{@current_user.full_name})"
      else
        @vaccination_record.performed_by&.full_name
      end
  end
end
