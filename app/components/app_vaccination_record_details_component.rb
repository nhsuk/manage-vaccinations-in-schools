# frozen_string_literal: true

class AppVaccinationRecordDetailsComponent < ViewComponent::Base
  def initialize(vaccination_record)
    super

    @vaccination_record = vaccination_record
    @vaccine = vaccination_record.vaccine
    @batch = vaccination_record.batch
  end

  def dose_number
    return nil if @vaccine.nil? || @vaccine.seasonal?

    numbers_to_words = {
      1 => "First",
      2 => "Second",
      3 => "Third",
      4 => "Fourth",
      5 => "Fifth",
      6 => "Sixth",
      7 => "Seventh",
      8 => "Eighth",
      9 => "Ninth"
    }.freeze

    if @vaccination_record.dose_sequence <= 9
      numbers_to_words[@vaccination_record.dose_sequence]
    else
      @vaccination_record.dose_sequence.ordinalize
    end
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
          row.with_key { "Dose volume" }
          row.with_value { "#{@vaccination_record.dose} ml" }
        end
      end

      if dose_number.present?
        summary_list.with_row do |row|
          row.with_key { "Dose number" }
          row.with_value { dose_number }
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

      if (administered_at = @vaccination_record.administered_at).present?
        summary_list.with_row do |row|
          row.with_key { "Date" }
          row.with_value { administered_at.to_date.to_fs(:long) }
        end
      end

      if @vaccination_record.user.present?
        summary_list.with_row do |row|
          row.with_key { "Nurse" }
          row.with_value { @vaccination_record.user.full_name }
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Location" }
        row.with_value { @vaccination_record.session.location.name }
      end
    end
  end
end
