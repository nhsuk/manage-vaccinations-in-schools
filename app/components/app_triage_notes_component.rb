# frozen_string_literal: true

class AppTriageNotesComponent < ViewComponent::Base
  def call
    if triage_entries.size == 1
      triage_notes(triage_entries.first)
    else
      tag.ul(class: "nhsuk-list") do
        triage_entries
          .map { |t| tag.li(t.notes) { triage_notes(t) } }
          .join("\n")
          .html_safe
      end
    end
  end

  def initialize(patient_session:)
    super

    @patient_session = patient_session
  end

  def render?
    triage_entries.present?
  end

  private

  def triage_entries
    @triage_entries ||=
      @patient_session.triage.where.not(notes: nil).order(created_at: :desc)
  end

  def triage_notes(triage)
    [
      tag.p(class: "nhsuk-u-margin-bottom-1") { triage.notes },
      tag.p(class: "nhsuk-u-secondary-text-color nhsuk-u-font-size-16") do
        author_info(triage:)
      end
    ].join("\n").html_safe
  end

  def author_info(triage:)
    date_text = triage.created_at.to_fs(:long)
    "#{triage.user.full_name}, #{date_text}"
  end
end
