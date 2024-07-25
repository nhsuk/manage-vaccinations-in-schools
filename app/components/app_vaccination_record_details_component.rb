# frozen_string_literal: true

class AppVaccinationRecordDetailsComponent < ViewComponent::Base
  def initialize(vaccination_record)
    super

    @vaccination_record = vaccination_record
    @vaccine = vaccination_record.vaccine
    @batch = vaccination_record.batch
  end

  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border nhsuk-u-margin-bottom-0"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Outcome" }
        row.with_value do
          @vaccination_record.administered ? "Vaccinated" : "Not vaccinated"
        end
      end

      if @vaccine.present?
        summary_list.with_row do |row|
          row.with_key { "Vaccine" }
          row.with_value { helpers.vaccine_heading(@vaccine) }
        end
      end

      if @vaccination_record.delivery_method.present?
        summary_list.with_row do |row|
          row.with_key { "Method" }
          row.with_value do
            @vaccination_record.human_enum_name(:delivery_method)
          end
        end
      end

      if @vaccination_record.delivery_site.present?
        summary_list.with_row do |row|
          row.with_key { "Site" }
          row.with_value { @vaccination_record.human_enum_name(:delivery_site) }
        end
      end

      if @vaccine.present?
        summary_list.with_row do |row|
          row.with_key { "Dose" }
          row.with_value { "#{@vaccination_record.dose} ml" }
        end
      end

      if @batch.present?
        summary_list.with_row do |row|
          row.with_key { "Batch ID" }
          row.with_value(classes: ["app-u-monospace"]) { @batch.name }
        end

        summary_list.with_row do |row|
          row.with_key { "Batch expiry date" }
          row.with_value { @batch.expiry.to_fs(:long) }
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Date and time" }
        row.with_value { @vaccination_record.recorded_at.to_fs(:long) }
      end

      summary_list.with_row do |row|
        row.with_key { "Nurse" }
        row.with_value { @vaccination_record.user.full_name }
      end

      summary_list.with_row do |row|
        row.with_key { "Location" }
        row.with_value { @vaccination_record.session.location.name }
      end
    end
  end
end
