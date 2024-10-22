# frozen_string_literal: true

class AppVaccinationCheckAndConfirmComponent < ViewComponent::Base
  def initialize(vaccination_record, current_user:)
    super

    @vaccination_record = vaccination_record
    @batch = vaccination_record.batch
    @patient = vaccination_record.patient
    @session = vaccination_record.session
    @vaccine = vaccination_record.vaccine

    @current_user = current_user
  end

  def call
    govuk_summary_list(
      actions: false,
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
        end

        summary_list.with_row do |row|
          row.with_key { "Method" }
          row.with_value do
            @vaccination_record.human_enum_name(:delivery_method)
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Site" }
          row.with_value { @vaccination_record.human_enum_name(:delivery_site) }
        end

        summary_list.with_row do |row|
          row.with_key { "Outcome" }
          row.with_value { "Vaccinated" }
        end
      else
        summary_list.with_row do |row|
          row.with_key { "Outcome" }
          row.with_value { @vaccination_record.human_enum_name(:reason) }
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
