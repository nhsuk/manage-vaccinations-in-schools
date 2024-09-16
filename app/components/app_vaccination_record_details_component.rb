# frozen_string_literal: true

class AppVaccinationRecordDetailsComponent < ViewComponent::Base
  def initialize(vaccination_record, change_links: false)
    super

    @vaccination_record = vaccination_record
    @vaccine = vaccination_record.vaccine
    @batch = vaccination_record.batch
    @change_links = change_links
  end

  def call
    govuk_summary_list(
      classes: "app-summary-list--no-bottom-border nhsuk-u-margin-bottom-0"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Outcome" }
        row.with_value { outcome_value }
      end

      if @vaccine.present?
        summary_list.with_row do |row|
          row.with_key { "Vaccine" }
          row.with_value { vaccine_value }
        end
      end

      if @vaccination_record.delivery_method.present?
        summary_list.with_row do |row|
          row.with_key { "Method" }
          row.with_value { delivery_method_value }
        end
      end

      if @vaccination_record.delivery_site.present?
        summary_list.with_row do |row|
          row.with_key { "Site" }
          row.with_value { delivery_site_value }
        end
      end

      if @vaccine.present?
        summary_list.with_row do |row|
          row.with_key { "Dose volume" }
          row.with_value { dose_volume_value }
        end
      end

      if dose_number.present?
        summary_list.with_row do |row|
          row.with_key { "Dose number" }
          row.with_value { dose_number_value }
        end
      end

      if @batch.present?
        summary_list.with_row do |row|
          row.with_key { "Batch ID" }
          row.with_value(classes: ["app-u-monospace"]) { batch_id_value }
        end

        summary_list.with_row do |row|
          row.with_key { "Batch expiry date" }
          row.with_value { batch_expiry_value }
        end
      end

      if @vaccination_record.session.location.present?
        summary_list.with_row do |row|
          row.with_key { "Location" }
          row.with_value { location_value }
        end
      end

      if @vaccination_record.administered_at.present?
        summary_list.with_row do |row|
          row.with_key { "Vaccination date" }
          row.with_value { vaccination_date_value }
          if @change_links
            row.with_action(
              text: "Change",
              visually_hidden_text: "vaccination date",
              href:
                programme_vaccination_record_edit_date_and_time_path(
                  @vaccination_record.programme,
                  @vaccination_record
                )
            )
          end
        end
      end

      if @vaccination_record.performed_by.present?
        summary_list.with_row do |row|
          row.with_key { "Nurse" }
          row.with_value { nurse_value }
        end
      end

      if @vaccination_record.notes.present?
        summary_list.with_row do |row|
          row.with_key { "Notes" }
          row.with_value { notes_value }
        end
      end
    end
  end

  private

  def outcome_value
    highlight_if(
      @vaccination_record.administered? ? "Vaccinated" : "Not vaccinated",
      @vaccination_record.administered_at_changed?
    )
  end

  def vaccine_value
    highlight_if(
      helpers.vaccine_heading(@vaccine),
      @vaccination_record.vaccine_id_changed?
    )
  end

  def delivery_method_value
    highlight_if(
      @vaccination_record.human_enum_name(:delivery_method),
      @vaccination_record.delivery_method_changed?
    )
  end

  def delivery_site_value
    highlight_if(
      @vaccination_record.human_enum_name(:delivery_site),
      @vaccination_record.delivery_site_changed?
    )
  end

  def dose_volume_value
    "#{@vaccination_record.dose} ml"
  end

  def batch_id_value
    highlight_if(@batch.name, @vaccination_record.batch_id_changed?)
  end

  def batch_expiry_value
    highlight_if(
      @batch.expiry.to_fs(:long),
      @vaccination_record.batch_id_changed?
    )
  end

  def location_value
    @vaccination_record.session.location.name
  end

  def vaccination_date_value
    highlight_if(
      @vaccination_record.administered_at.to_fs(:long),
      @vaccination_record.administered_at_changed?
    )
  end

  def nurse_value
    highlight_if(
      @vaccination_record.performed_by.full_name,
      @vaccination_record.performed_by_user_id_changed?
    )
  end

  def notes_value
    highlight_if(@vaccination_record.notes, @vaccination_record.notes_changed?)
  end

  def dose_number_value
    highlight_if(dose_number, @vaccination_record.dose_sequence_changed?)
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

  def highlight_if(value, condition)
    condition ? tag.span(value, class: "app-highlight") : value
  end
end
