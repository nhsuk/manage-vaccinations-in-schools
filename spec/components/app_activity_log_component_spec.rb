# frozen_string_literal: true

describe AppActivityLogComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient_session:) }

  let(:programme) { create(:programme, :hpv) }
  let(:organisation) { create(:organisation, programmes: [programme]) }
  let(:patient_session) do
    create(
      :patient_session,
      patient:,
      session:,
      created_at: Time.zone.parse("2024-05-29 12:00")
    )
  end
  let(:user) do
    create(
      :user,
      organisations: [organisation],
      family_name: "Joy",
      given_name: "Nurse"
    )
  end
  let(:location) { create(:location, :school, name: "Hogwarts") }
  let(:session) { create(:session, programme:, location:) }
  let(:patient) do
    create(:patient, school: location, given_name: "Sarah", family_name: "Doe")
  end

  let(:mum) { create(:parent, :recorded, full_name: "Jane Doe") }
  let(:dad) { create(:parent, :recorded, full_name: "John Doe") }

  before do
    create(:parent_relationship, :mother, parent: mum, patient:)
    create(:parent_relationship, :father, parent: dad, patient:)
  end

  shared_examples "card" do |title:, date:, notes: nil, by: nil|
    it "renders card '#{title}'" do
      expect(rendered).to have_css(".nhsuk-card h3", text: title)

      card = page.find(".nhsuk-card h3", text: title).ancestor(".nhsuk-card")

      expect(card).to have_css("p", text: date)
      expect(card).to have_css("blockquote", text: notes) if notes
      expect(card).to have_css("p", text: by) if by
    end
  end

  describe "consent given by parents" do
    before do
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

      # draft consent should not show
      create(:consent, :given, programme:, patient:, parent: nil)

      create(
        :triage,
        :needs_follow_up,
        programme:,
        patient:,
        created_at: Time.zone.parse("2024-05-30 14:00"),
        notes: "Some notes",
        performed_by: user
      )
      create(
        :triage,
        :ready_to_vaccinate,
        programme:,
        patient:,
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

      create(
        :vaccination_record,
        programme:,
        patient_session:,
        created_at: Time.zone.parse("2024-05-31 13:00"),
        performed_by: nil,
        notes: "Some notes",
        vaccine: create(:vaccine, :gardasil, programme:)
      )

      create(
        :notify_log_entry,
        :email,
        template_id: GOVUK_NOTIFY_EMAIL_TEMPLATES[:consent_school_request],
        patient:,
        consent_form: nil,
        recipient: "test@example.com",
        created_at: Date.new(2024, 5, 10),
        sent_by: user
      )

      create(
        :session_notification,
        :clinic_initial_invitation,
        session:,
        patient:,
        sent_at: Date.new(2024, 5, 30)
      )
    end

    it "renders headings in correct order" do
      expect(rendered).to have_css("h2:nth-of-type(1)", text: "31 May 2024")
      expect(rendered).to have_css("h2:nth-of-type(2)", text: "30 May 2024")
      expect(rendered).to have_css("h2:nth-of-type(3)", text: "29 May 2024")
    end

    it "has cards" do
      expect(rendered).to have_css(".nhsuk-card", count: 8)
    end

    include_examples "card",
                     title: "Vaccinated with Gardasil 9 (HPV)",
                     date: "31 May 2024 at 12:00pm",
                     notes: "Some notes",
                     by: "Nurse Joy"

    include_examples "card",
                     title: "Vaccinated with Gardasil (HPV)",
                     date: "31 May 2024 at 1:00pm",
                     notes: "Some notes"

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

    include_examples "card",
                     title: "Consent school request sent",
                     date: "10 May 2024 at 12:00am",
                     notes: "test@example.com",
                     by: "Nurse Joy"
  end

  describe "vaccination not administered" do
    before do
      create(
        :vaccination_record,
        :not_administered,
        programme:,
        patient_session:,
        created_at: Time.zone.local(2024, 5, 31, 13),
        performed_by: user,
        notes: "Some notes.",
        vaccine: create(:vaccine, :gardasil, programme:)
      )
    end

    include_examples "card",
                     title: "Unable to vaccinate: Unwell",
                     date: "31 May 2024 at 1:00pm",
                     notes: "Some notes.",
                     by: "Nurse Joy"
  end

  describe "self-consent" do
    before do
      create(
        :consent,
        :given,
        :self_consent,
        programme:,
        patient:,
        recorded_at: Time.zone.parse("2024-05-30 12:00")
      )
    end

    include_examples "card",
                     title:
                       "Consent given by Sarah Doe (Child (Gillick competent))",
                     date: "30 May 2024 at 12:00pm"
  end

  describe "withdrawn consent" do
    before do
      create(
        :consent,
        :given,
        :withdrawn,
        programme:,
        patient:,
        parent: mum,
        recorded_at: Time.zone.local(2024, 5, 30, 12),
        withdrawn_at: Time.zone.local(2024, 6, 30, 12)
      )
    end

    include_examples "card",
                     title: "Consent from Jane Doe withdrawn",
                     date: "30 June 2024 at 12:00pm"

    include_examples "card",
                     title: "Consent given by Jane Doe (Mum)",
                     date: "30 May 2024 at 12:00pm"
  end

  describe "invalidated consent" do
    before do
      create(
        :consent,
        :given,
        :invalidated,
        programme:,
        patient:,
        parent: mum,
        recorded_at: Time.zone.local(2024, 5, 30, 12),
        invalidated_at: Time.zone.local(2024, 6, 30, 12)
      )
    end

    include_examples "card",
                     title: "Consent from Jane Doe invalidated",
                     date: "30 June 2024 at 12:00pm"

    include_examples "card",
                     title: "Consent given by Jane Doe (Mum)",
                     date: "30 May 2024 at 12:00pm"
  end
end
