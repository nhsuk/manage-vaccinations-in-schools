# frozen_string_literal: true

class AppTriageNotesComponent < ViewComponent::Base
  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end

  def render?
    entries.present?
  end

  private

  def entries
    @entries ||=
      @patient_session.triage.where.not(notes: nil).order(created_at: :desc)
  end
<<<<<<< HEAD
||||||| parent of 41a4b57a (Show decision on triage notes)

  def triage_notes(triage)
    [
      tag.p(class: "nhsuk-u-margin-bottom-1") { triage.notes },
      tag.p(class: "nhsuk-u-secondary-text-color nhsuk-u-font-size-16") do
        "#{triage.user.full_name}, #{triage.created_at.to_fs(:app_date_time)}"
      end
    ].join("\n").html_safe
  end
=======

  def triage_notes(triage)
    [
      tag.h3(
        "Triaged decision: #{triage.human_enum_name(:status)}",
        class: "nhsuk-heading-s nhsuk-u-margin-bottom-2"
      ),
      if (notes = triage.notes).present?
        tag.p(notes, class: "nhsuk-u-margin-bottom-1")
      end,
      tag.p(
        "#{triage.user.full_name}, #{triage.created_at.to_fs(:app_date_time)}",
        class: "nhsuk-u-secondary-text-color nhsuk-u-font-size-16"
      )
    ].compact.join("\n").html_safe
  end
>>>>>>> 41a4b57a (Show decision on triage notes)
end
