# frozen_string_literal: true

shared_examples "card" do |params|
  title, date, notes, by = params.values_at(:title, :date, :notes, :by)
  it "renders card '#{title}'" do
    expect(subject).to have_css(".nhsuk-card h3", text: title)

    card = subject.find(".nhsuk-card h3", text: title).ancestor(".nhsuk-card")
    expect(card).to have_css("p", text: date)
    expect(card).to have_css("blockquote", text: notes) if notes
    expect(card).to have_css("p", text: by) if by
  end
end

describe AppActivityLogComponent do
  subject { page }

  let(:programme) { create(:programme, :hpv) }
  let(:team) { create(:team, programmes: [programme]) }
  let(:patient_session) do
    create(
      :patient_session,
      patient:,
      session:,
      created_at: Time.zone.parse("2024-05-29 12:00")
    )
  end
  let(:component) { described_class.new(patient_session) }
  let(:user) do
    create(:user, teams: [team], family_name: "Joy", given_name: "Nurse")
  end
  let(:location) { create(:location, :school, name: "Hogwarts") }
  let(:session) { create(:session, programme:, location:) }
  let(:patient) { create(:patient, school: location) }

  let(:mum) { create(:parent, :recorded, full_name: "Jane Doe") }
  let(:dad) { create(:parent, :recorded, full_name: "John Doe") }

  before do
    create(:parent_relationship, :mother, parent: mum, patient:)
    create(:parent_relationship, :father, parent: dad, patient:)

    create(
      :consent,
      :given,
      programme:,
      patient:,
      parent: mum,
      recorded_at: Time.zone.parse("2024-05-30 12:00")
    )
    create(
      :consent,
      :refused,
      programme:,
      patient:,
      parent: dad,
      recorded_at: Time.zone.parse("2024-05-30 13:00")
    )
    create(
      :triage,
      :needs_follow_up,
      programme:,
      patient_session:,
      created_at: Time.zone.parse("2024-05-30 14:00"),
      notes: "Some notes",
      performed_by: user
    )
    create(
      :triage,
      :ready_to_vaccinate,
      programme:,
      patient_session:,
      created_at: Time.zone.parse("2024-05-30 14:30"),
      performed_by: user
    )

    create(
      :vaccination_record,
      programme:,
      patient_session:,
      created_at: Time.zone.parse("2024-05-31 12:00"),
      performed_by: user,
      notes: "Some notes"
    )
    render_inline(component)
  end

  it "renders headings in correct order" do
    expect(subject).to have_css("h2:nth-of-type(1)", text: "31 May 2024")
    expect(subject).to have_css("h2:nth-of-type(2)", text: "30 May 2024")
    expect(subject).to have_css("h2:nth-of-type(3)", text: "29 May 2024")
  end

  include_examples "card",
                   title: "Vaccinated with Gardasil 9 (HPV)",
                   date: "31 May 2024 at 12:00pm",
                   notes: "Some notes",
                   by: "Nurse Joy"

  include_examples "card",
                   title: "Triaged decision: Safe to vaccinate",
                   date: "30 May 2024 at 2:30pm",
                   by: "Nurse Joy"

  include_examples "card",
                   title: "Triaged decision: Keep in triage",
                   date: "30 May 2024 at 2:00pm",
                   notes: "Some notes",
                   by: "Nurse Joy"

  include_examples "card",
                   title: "Consent refused by John Doe (Dad)",
                   date: "30 May 2024 at 1:00pm"

  include_examples "card",
                   title: "Consent given by Jane Doe (Mum)",
                   date: "30 May 2024 at 12:00pm"

  include_examples "card",
                   title: "Added to session at Hogwarts",
                   date: "29 May 2024 at 12:00pm"
end
