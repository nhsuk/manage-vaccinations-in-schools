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

    @batch = vaccination_record.batch
    @identity_check = vaccination_record.identity_check
    @patient = vaccination_record.patient
    @programme = vaccination_record.programme
    @vaccine = vaccination_record.vaccine
  end

  def call
    govuk_summary_list(actions: @change_links.present?) do |summary_list|
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

      summary_list.with_row do |row|
        row.with_key { "Programme" }
        row.with_value { programme_value }
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
                visually_hidden_text: "site"
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
        if @vaccination_record.vaccine.present?
          summary_list.with_row do |row|
            row.with_key { "Dose volume" }
            row.with_value { dose_volume_value }

            if (href = @change_links[:dose_volume])
              row.with_action(
                text: "Change",
                href:,
                visually_hidden_text: "dose volume"
              )
            end
          end
        end

        if dose_number.present?
          summary_list.with_row do |row|
            row.with_key { "Dose number" }
            row.with_value { dose_number_value }
          end
        end
      end

      if @identity_check
        summary_list.with_row do |row|
          row.with_key { "Child identified by" }
          row.with_value { helpers.identity_check_label(@identity_check) }
          if (href = @change_links[:identity])
            row.with_action(
              text: "Change",
              href:,
              visually_hidden_text: "child identified by"
            )
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

      summary_list.with_row do |row|
        row.with_key { "Date" }
        row.with_value { date_value }
        if (href = @change_links[:performed_at])
          row.with_action(text: "Change", visually_hidden_text: "date", href:)
        end
      end

      summary_list.with_row do |row|
        row.with_key { "Time" }
        row.with_value { time_value }
        if (href = @change_links[:performed_at])
          row.with_action(text: "Change", visually_hidden_text: "time", href:)
        end
      end

      if @vaccination_record.performed_by.present?
        summary_list.with_row do |row|
          row.with_key { "Vaccinator" }
          row.with_value { vaccinator_value }
        end
      end

      if @vaccination_record.protocol.present?
        summary_list.with_row do |row|
          row.with_key { "Protocol" }
          row.with_value { protocol_value }
        end
      end

      if @show_notes
        summary_list.with_row do |row|
          row.with_key { "Notes" }

          if @vaccination_record.notes.present?
            row.with_value { notes_value }

            if (href = @change_links[:notes])
              row.with_action(
                text: "Change",
                href:,
                visually_hidden_text: "site"
              )
            end
          elsif (href = @change_links[:notes])
            row.with_value { link_to "Add notes", href }
          else
            row.with_value { "Not provided" }
          end
        end
      end
    end
  end

  private

  def outcome_value
    highlight_if(
      VaccinationRecord.human_enum_name(:outcome, @vaccination_record.outcome),
      @vaccination_record.outcome_changed?
    )
  end

  def programme_value
    highlight_if(@programme.name, @vaccination_record.programme_id_changed?)
  end

  def vaccine_value
    highlight_if(@vaccine.brand, @vaccination_record.vaccine_id_changed?)
  end

  def delivery_method_value
    highlight_if(
      VaccinationRecord.human_enum_name(
        :delivery_method,
        @vaccination_record.delivery_method
      ),
      @vaccination_record.delivery_method_changed?
    )
  end

  def delivery_site_value
    highlight_if(
      VaccinationRecord.human_enum_name(
        :delivery_site,
        @vaccination_record.delivery_site
      ),
      @vaccination_record.delivery_site_changed?
    )
  end

  def dose_volume_value
    "#{@vaccination_record.dose_volume_ml} ml"
  end

  def batch_id_value
    highlight_if(@batch.name, @vaccination_record.batch_id_changed?)
  end

  def batch_expiry_value
    highlight_if(
      @batch.expiry&.to_fs(:long) || "Unknown",
      @vaccination_record.batch_id_changed?
    )
  end

  def location_value
    helpers.vaccination_record_location(@vaccination_record)
  end

  def date_value
    date = @vaccination_record.performed_at.to_date

    highlight_if(
      date.today? ? "Today (#{date.to_fs(:long)})" : date.to_fs(:long),
      @vaccination_record.performed_at_changed?
    )
  end

  def time_value
    highlight_if(
      @vaccination_record.performed_at.to_fs(:time),
      @vaccination_record.performed_at_changed?
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

  def protocol_value
    highlight_if(
      VaccinationRecord.human_enum_name(
        :protocol,
        @vaccination_record.protocol
      ),
      @vaccination_record.protocol_changed?
    )
  end

  def notes_value
    highlight_if(@vaccination_record.notes, @vaccination_record.notes_changed?)
  end

  def dose_number_value
    highlight_if(dose_number, @vaccination_record.dose_sequence_changed?)
  end

  def dose_number
    dose_sequence = @vaccination_record.dose_sequence

    if dose_sequence.nil?
      "Unknown"
    elsif dose_sequence <= 10
      I18n.t(dose_sequence, scope: :ordinal_number).upcase_first
    else
      dose_sequence.ordinalize
    end
  end

  def highlight_if(value, condition)
    condition ? tag.span(value, class: "app-highlight") : value
  end
end
