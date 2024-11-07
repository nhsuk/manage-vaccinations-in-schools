# frozen_string_literal: true

class AppVaccinationRecordSummaryComponent < ViewComponent::Base
  def initialize(
    vaccination_record,
    current_user:,
    change_links: {},
    show_notes: true
  )
    super

    @vaccination_record = vaccination_record
    @current_user = current_user
    @change_links = change_links
    @show_notes = show_notes

    @patient = vaccination_record.patient
    @vaccine = vaccination_record.vaccine
    @batch = vaccination_record.batch
  end

  def call
    govuk_summary_list(
      actions: @change_links.present?,
      classes: "app-summary-list--no-bottom-border nhsuk-u-margin-bottom-0"
    ) do |summary_list|
      summary_list.with_row do |row|
        row.with_key { "Child" }
        row.with_value { @patient.full_name }
      end

      summary_list.with_row do |row|
        row.with_key { "Outcome" }
        row.with_value { outcome_value }

        if (href = @change_links[:outcome])
          row.with_action(
            text: "Change",
            href:,
            visually_hidden_text: "outcome"
          )
        end
      end

      if @vaccination_record.administered?
        summary_list.with_row do |row|
          row.with_key { "Vaccine" }

          if @vaccine
            row.with_value { vaccine_value }

            if (href = @change_links[:vaccine])
              row.with_action(
                text: "Change",
                visually_hidden_text: "vaccine",
                href:
              )
            end
          elsif (href = @change_links[:vaccine])
            row.with_value { link_to "Add vaccine", href }
          else
            row.with_value { "Not provided" }
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Batch ID" }

          if @batch
            row.with_value(classes: ["app-u-monospace"]) { batch_id_value }

            if (href = @change_links[:batch])
              row.with_action(
                text: "Change",
                href:,
                visually_hidden_text: "batch"
              )
            end
          elsif (href = @change_links[:batch])
            row.with_value { link_to "Add batch", href }
          else
            row.with_value { "Not provided" }
          end
        end

        if @batch
          summary_list.with_row do |row|
            row.with_key { "Batch expiry date" }
            row.with_value { batch_expiry_value }
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Method" }

          if @vaccination_record.delivery_method.present?
            row.with_value { delivery_method_value }

            if (href = @change_links[:delivery_method])
              row.with_action(
                text: "Change",
                href:,
                visually_hidden_text: "method"
              )
            end
          elsif (href = @change_links[:delivery_method])
            row.with_value { link_to "Add method", href }
          else
            row.with_value { "Not provided" }
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Site" }

          if @vaccination_record.delivery_site.present?
            row.with_value { delivery_site_value }

            if (href = @change_links[:delivery_site])
              row.with_action(
                text: "Change",
                href:,
                visually_hidden_text: "method"
              )
            end
          elsif (href = @change_links[:delivery_site])
            row.with_value { link_to "Add site", href }
          else
            row.with_value { "Not provided" }
          end
        end
      end

      if @vaccination_record.administered?
        summary_list.with_row do |row|
          row.with_key { "Dose volume" }
          row.with_value { dose_volume_value }
        end

        if dose_number.present?
          summary_list.with_row do |row|
            row.with_key { "Dose number" }
            row.with_value { dose_number_value }
          end
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Location" }
        row.with_value { location_value }
        if (href = @change_links[:location])
          row.with_action(
            text: "Change",
            href:,
            visually_hidden_text: "location"
          )
        end
      end

      if @vaccination_record.administered?
        summary_list.with_row do |row|
          row.with_key { "Date" }
          row.with_value { date_value }
          if (href = @change_links[:administered_at])
            row.with_action(text: "Change", visually_hidden_text: "date", href:)
          end
        end

        summary_list.with_row do |row|
          row.with_key { "Time" }
          row.with_value { time_value }
          if (href = @change_links[:administered_at])
            row.with_action(text: "Change", visually_hidden_text: "time", href:)
          end
        end
      end

      if @vaccination_record.performed_by.present?
        summary_list.with_row do |row|
          row.with_key { "Vaccinator" }
          row.with_value { vaccinator_value }
        end
      end

      if @show_notes && @vaccination_record.notes.present?
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
      (
        if @vaccination_record.administered?
          "Vaccinated"
        else
          @vaccination_record.human_enum_name(:reason)
        end
      ),
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
    if @vaccination_record.location.generic_clinic?
      @vaccination_record.location_name
    else
      @vaccination_record.location.name
    end
  end

  def date_value
    date = @vaccination_record.administered_at.to_date

    highlight_if(
      date.today? ? "Today (#{date.to_fs(:long)})" : date.to_fs(:long),
      @vaccination_record.administered_at_changed?
    )
  end

  def time_value
    highlight_if(
      @vaccination_record.administered_at.to_fs(:time),
      @vaccination_record.administered_at_changed?
    )
  end

  def vaccinator_value
    value =
      if @vaccination_record.performed_by == @current_user
        "You (#{@current_user.full_name})"
      else
        @vaccination_record.performed_by&.full_name
      end

    highlight_if(
      value,
      @vaccination_record.performed_by_family_name_changed? ||
        @vaccination_record.performed_by_given_name_changed? ||
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
