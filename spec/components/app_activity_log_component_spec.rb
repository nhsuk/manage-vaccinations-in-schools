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
    create(:user, organisation:, family_name: "Joy", given_name: "Nurse")
  end
  let(:location) { create(:school, name: "Hogwarts") }
  let(:session) { create(:session, programme:, location:) }
  let(:patient) do
    create(:patient, school: location, given_name: "Sarah", family_name: "Doe")
  end

  let(:mum) { create(:parent, full_name: "Jane Doe") }
  let(:dad) { create(:parent, full_name: "John Doe") }

  before do
    create(:parent_relationship, :mother, parent: mum, patient:)
    create(:parent_relationship, :father, parent: dad, patient:)
    patient.reload

    patient_session.strict_loading!(false)
    patient_session.patient.strict_loading!(false)
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
        created_at: Time.zone.parse("2024-05-30 12:00"),
        recorded_by: user
      )
      create(
        :consent,
        :refused,
        programme:,
        patient:,
        parent: dad,
        created_at: Time.zone.parse("2024-05-30 13:00")
      )

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
        patient:,
        session:,
        performed_at: Time.zone.parse("2024-05-31 12:00"),
        performed_by: user,
        notes: "Some notes"
      )

      create(
        :vaccination_record,
        programme:,
        patient:,
        session:,
        performed_at: Time.zone.parse("2024-05-31 13:00"),
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
                     by: "JOY, Nurse"

    include_examples "card",
                     title: "Vaccinated with Gardasil (HPV)",
                     date: "31 May 2024 at 1:00pm",
                     notes: "Some notes"

    include_examples "card",
                     title: "Triaged decision: Safe to vaccinate",
                     date: "30 May 2024 at 2:30pm",
                     by: "JOY, Nurse"

    include_examples "card",
                     title: "Triaged decision: Keep in triage",
                     date: "30 May 2024 at 2:00pm",
                     notes: "Some notes",
                     by: "JOY, Nurse"

    include_examples "card",
                     title: "Consent refused by John Doe (Dad)",
                     date: "30 May 2024 at 1:00pm"

    include_examples "card",
                     title: "Consent given by Jane Doe (Mum)",
                     date: "30 May 2024 at 12:00pm",
                     by: "JOY, Nurse"

    include_examples "card",
                     title: "Added to session at Hogwarts",
                     date: "29 May 2024 at 12:00pm"

    include_examples "card",
                     title: "Consent school request sent",
                     date: "10 May 2024 at 12:00am",
                     notes: "test@example.com",
                     by: "JOY, Nurse"
  end

  describe "vaccination not administered" do
    before do
      create(
        :vaccination_record,
        :not_administered,
        programme:,
        patient:,
        session:,
        performed_at: Time.zone.local(2024, 5, 31, 13),
        performed_by: user,
        notes: "Some notes.",
        vaccine: create(:vaccine, :gardasil, programme:)
      )
    end

    include_examples "card",
                     title: "HPV vaccination not given: Unwell",
                     date: "31 May 2024 at 1:00pm",
                     notes: "Some notes.",
                     by: "JOY, Nurse"
  end

  describe "discarded vaccination" do
    before do
      create(
        :vaccination_record,
        :discarded,
        programme:,
        patient:,
        session:,
        performed_at: Time.zone.local(2024, 5, 31, 13),
        discarded_at: Time.zone.local(2024, 5, 31, 14),
        performed_by: user
      )
    end

    include_examples "card",
                     title: "Vaccinated with Gardasil 9 (HPV)",
                     date: "31 May 2024 at 1:00pm",
                     by: "JOY, Nurse"

    include_examples "card",
                     title: "HPV vaccination record deleted",
                     date: "31 May 2024 at 2:00pm"
  end

  describe "self-consent" do
    before do
      create(
        :consent,
        :given,
        :self_consent,
        programme:,
        patient:,
        created_at: Time.zone.parse("2024-05-30 12:00")
      )
    end

    include_examples "card",
                     title:
                       "Consent given by DOE, Sarah (Child (Gillick competent))",
                     date: "30 May 2024 at 12:00pm"
  end

  describe "manually matched consent" do
    before do
      consent_form =
        create(
          :consent_form,
          programme:,
          session:,
          recorded_at: Time.zone.local(2024, 5, 30, 12),
          parent_full_name: "Jane Doe",
          parent_relationship_type: "mother"
        )

      create(
        :consent,
        :given,
        :invalidated,
        programme:,
        patient:,
        parent: mum,
        consent_form:,
        recorded_by: user,
        created_at: Time.zone.local(2024, 5, 30, 13)
      )
    end

    include_examples "card",
                     title: "Consent given",
                     date: "30 May 2024 at 12:00pm",
                     by: "Jane Doe (Mum)"

    include_examples "card",
                     title:
                       "Consent response manually matched with child record",
                     date: "30 May 2024 at 1:00pm",
                     by: "JOY, Nurse"
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
        created_at: Time.zone.local(2024, 5, 30, 12),
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
        created_at: Time.zone.local(2024, 5, 30, 12),
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

  describe "gillick assessments" do
    let(:programme) { create(:programme) }
    let(:patient_session) { create(:patient_session, patient:, programme:) }

    before do
      create(
        :gillick_assessment,
        :competent,
        performed_by: user,
        patient_session:,
        notes: "First notes",
        created_at: Time.zone.local(2024, 6, 1, 12)
      )
      create(
        :gillick_assessment,
        :not_competent,
        performed_by: user,
        patient_session:,
        notes: "Second notes",
        created_at: Time.zone.local(2024, 6, 1, 13)
      )
    end

    include_examples "card",
                     title: "Completed Gillick assessment as Gillick competent",
                     notes: "First notes",
                     date: "1 June 2024 at 12:00pm",
                     by: "JOY, Nurse"

    include_examples "card",
                     title:
                       "Updated Gillick assessment as not Gillick competent",
                     notes: "Second notes",
                     date: "1 June 2024 at 1:00pm",
                     by: "JOY, Nurse"
  end

  describe "pre-screenings" do
    let(:programme) { create(:programme) }
    let(:patient_session) { create(:patient_session, patient:, programme:) }

    before do
      create(
        :pre_screening,
        :allows_vaccination,
        performed_by: user,
        patient_session:,
        notes: "Some notes",
        created_at: Time.zone.local(2024, 6, 1, 12)
      )
    end

    include_examples "card",
                     title: "Completed pre-screening checks",
                     notes: "Some notes",
                     date: "1 June 2024 at 12:00pm",
                     by: "JOY, Nurse"
  end
end
