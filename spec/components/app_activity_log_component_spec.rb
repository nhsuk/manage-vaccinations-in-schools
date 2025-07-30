# frozen_string_literal: true

describe AppActivityLogComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient_session:, team:) }

  let(:today) { Date.new(2026, 1, 1) }

  let(:programmes) { [create(:programme, :hpv), create(:programme, :flu)] }
  let(:team) { create(:team, programmes:) }
  let(:patient_session) do
    create(
      :patient_session,
      patient:,
      session:,
      created_at: Time.zone.parse("2025-05-29 12:00")
    )
  end
  let(:user) { create(:user, team:, family_name: "Joy", given_name: "Nurse") }
  let(:location) { create(:school, name: "Hogwarts") }
  let(:session) { create(:session, programmes:, location:) }
  let(:patient) do
    create(
      :patient,
      school: location,
      given_name: "Sarah",
      family_name: "Doe",
      year_group: 8
    )
  end

  let(:mum) { create(:parent, full_name: "Jane Doe") }
  let(:dad) { create(:parent, full_name: "John Doe") }

  before do
    travel_to Date.new(2026, 1, 1)

    create(:parent_relationship, :mother, parent: mum, patient:)
    create(:parent_relationship, :father, parent: dad, patient:)
    patient.reload

    patient_session.strict_loading!(false)
    patient_session.patient.strict_loading!(false)
  end

  shared_examples "card" do |title:, date:, notes: nil, by: nil, programme: nil|
    it "renders card '#{title}'" do
      expect(rendered).to have_css(".nhsuk-card__heading", text: title)

      card =
        if programme
          page
            .all(".nhsuk-card")
            .find do |card_element|
              card_element.has_css?("h4", text: title) &&
                card_element.has_css?("strong", text: programme)
            end
        else
          page.find(".nhsuk-card__heading", text: title).ancestor(".nhsuk-card")
        end

      expect(card).to have_css("p", text: date)
      expect(card).to have_css("blockquote", text: notes) if notes
      expect(card).to have_css("p", text: by) if by
    end
  end

  describe "archive reasons" do
    before do
      create(
        :archive_reason,
        :other,
        created_at: Time.zone.local(2024, 6, 1, 12),
        created_by: user,
        team:,
        other_details: "Extra details",
        patient:
      )
    end

    include_examples "card",
                     title: "Record archived: Other",
                     notes: "Extra details",
                     date: "1 June 2024 at 12:00pm",
                     by: "JOY, Nurse"
  end

  describe "consent given by parents" do
    before do
      create(
        :consent,
        :given,
        programme: programmes.first,
        patient:,
        parent: mum,
        submitted_at: Time.zone.parse("2025-05-30 12:00"),
        recorded_by: user
      )
      create(
        :consent,
        :refused,
        programme: programmes.first,
        patient:,
        parent: dad,
        submitted_at: Time.zone.parse("2025-05-30 13:00")
      )
      create(
        :consent,
        :given,
        programme: programmes.second,
        patient:,
        parent: dad,
        submitted_at: Time.zone.parse("2025-05-30 13:00"),
        vaccine_methods: ["nasal"]
      )

      create(
        :triage,
        :needs_follow_up,
        programme: programmes.first,
        patient:,
        created_at: Time.zone.parse("2025-05-30 14:00"),
        notes: "Some notes",
        performed_by: user
      )
      create(
        :triage,
        :ready_to_vaccinate,
        programme: programmes.first,
        patient:,
        created_at: Time.zone.parse("2025-05-30 14:30"),
        performed_by: user
      )
      create(
        :triage,
        :ready_to_vaccinate,
        programme: programmes.second,
        patient:,
        created_at: Time.zone.parse("2025-05-30 14:35"),
        notes: "Some notes",
        performed_by: user,
        vaccine_method: "nasal"
      )

      create(
        :vaccination_record,
        programme: programmes.first,
        patient:,
        session:,
        performed_at: Time.zone.parse("2025-05-31 12:00"),
        performed_by: user,
        notes: "Some notes"
      )

      create(
        :vaccination_record,
        programme: programmes.first,
        patient:,
        session:,
        performed_at: Time.zone.parse("2025-05-31 13:00"),
        performed_by: nil,
        notes: "Some notes",
        vaccine: create(:vaccine, :cervarix, programme: programmes.first)
      )

      create(
        :notify_log_entry,
        :email,
        template_id: GOVUK_NOTIFY_EMAIL_TEMPLATES[:consent_school_request_hpv],
        consent_form: nil,
        patient:,
        programme_ids: programmes.map(&:id),
        recipient: "test@example.com",
        created_at: Date.new(2025, 5, 10),
        sent_by: user
      )

      create(
        :session_notification,
        :clinic_initial_invitation,
        session:,
        patient:,
        sent_at: Date.new(2025, 5, 30)
      )
    end

    it "renders headings in correct order" do
      expect(rendered).to have_css("h3:nth-of-type(1)", text: "31 August 2025")
      expect(rendered).to have_css("h3:nth-of-type(2)", text: "31 May 2025")
      expect(rendered).to have_css("h3:nth-of-type(3)", text: "30 May 2025")
      expect(rendered).to have_css("h3:nth-of-type(4)", text: "29 May 2025")
    end

    it "has cards" do
      expect(rendered).to have_css(".nhsuk-card", count: 11)
    end

    include_examples "card",
                     title: "Vaccinated with Gardasil 9",
                     date: "31 May 2025 at 12:00pm",
                     notes: "Some notes",
                     by: "JOY, Nurse",
                     programme: "HPV"

    include_examples "card",
                     title: "Vaccinated with Cervarix",
                     date: "31 May 2025 at 1:00pm",
                     notes: "Some notes",
                     programme: "HPV"

    include_examples "card",
                     title: "Triaged decision: Safe to vaccinate",
                     date: "30 May 2025 at 2:30pm",
                     by: "JOY, Nurse",
                     programme: "HPV"

    include_examples "card",
                     title: "Triaged decision: Keep in triage",
                     date: "30 May 2025 at 2:00pm",
                     notes: "Some notes",
                     by: "JOY, Nurse",
                     programme: "HPV"

    include_examples "card",
                     title:
                       "Triaged decision: Safe to vaccinate with nasal spray",
                     date: "30 May 2025 at 2:35pm",
                     notes: "Some notes",
                     by: "JOY, Nurse",
                     programme: "Flu"

    include_examples "card",
                     title: "Consent refused by John Doe (Dad)",
                     date: "30 May 2025 at 1:00pm",
                     programme: "HPV"

    include_examples "card",
                     title: "Consent given by Jane Doe (Mum)",
                     date: "30 May 2025 at 12:00pm",
                     by: "JOY, Nurse",
                     programme: "HPV"

    include_examples "card",
                     title: "Added to the session at Hogwarts",
                     date: "29 May 2025 at 12:00pm"

    include_examples "card",
                     title: "Consent school request hpv sent",
                     date: "10 May 2025 at 12:00am",
                     notes: "test@example.com",
                     by: "JOY, Nurse",
                     programme: "HPV"
  end

  describe "vaccination not administered" do
    before do
      create(
        :vaccination_record,
        :not_administered,
        programme: programmes.first,
        patient:,
        session:,
        performed_at: Time.zone.local(2025, 5, 31, 13),
        performed_by: user,
        notes: "Some notes.",
        vaccine: create(:vaccine, :gardasil, programme: programmes.first)
      )
    end

    include_examples "card",
                     title: "Vaccination not given: Unwell",
                     date: "31 May 2025 at 1:00pm",
                     notes: "Some notes.",
                     by: "JOY, Nurse",
                     programme: "HPV"
  end

  describe "discarded vaccination" do
    before do
      create(
        :vaccination_record,
        :discarded,
        programme: programmes.first,
        patient:,
        session:,
        performed_at: Time.zone.local(2025, 5, 31, 13),
        discarded_at: Time.zone.local(2025, 5, 31, 14),
        performed_by: user
      )
    end

    include_examples "card",
                     title: "Vaccinated with Gardasil 9",
                     date: "31 May 2025 at 1:00pm",
                     by: "JOY, Nurse",
                     programme: "HPV"

    include_examples "card",
                     title: "Vaccination record deleted",
                     date: "31 May 2025 at 2:00pm",
                     programme: "HPV"
  end

  describe "self-consent" do
    before do
      create(
        :consent,
        :given,
        :self_consent,
        programme: programmes.first,
        patient:,
        submitted_at: Time.zone.parse("2025-05-30 12:00")
      )
    end

    include_examples "card",
                     title:
                       "Consent given by DOE, Sarah (Child (Gillick competent))",
                     date: "30 May 2025 at 12:00pm",
                     programme: "HPV"
  end

  describe "manually matched consent" do
    before do
      consent_form =
        create(
          :consent_form,
          session:,
          recorded_at: Time.zone.local(2025, 5, 30, 12),
          parent_full_name: "Jane Doe",
          parent_relationship_type: "mother"
        )

      create(
        :consent,
        :given,
        :invalidated,
        programme: programmes.first,
        patient:,
        parent: mum,
        consent_form:,
        recorded_by: user,
        created_at: Time.zone.local(2025, 5, 30, 13)
      )
    end

    include_examples "card",
                     title: "Consent given",
                     date: "30 May 2025 at 12:00pm",
                     by: "Jane Doe (Mum)",
                     programme: "HPV"

    include_examples "card",
                     title:
                       "Consent response manually matched with child record",
                     date: "30 May 2025 at 1:00pm",
                     by: "JOY, Nurse"
  end

  describe "withdrawn consent" do
    before do
      create(
        :consent,
        :given,
        :withdrawn,
        programme: programmes.first,
        patient:,
        parent: mum,
        submitted_at: Time.zone.local(2025, 5, 30, 12),
        withdrawn_at: Time.zone.local(2025, 6, 30, 12)
      )
    end

    include_examples "card",
                     title: "Consent from Jane Doe withdrawn",
                     date: "30 June 2025 at 12:00pm",
                     programme: "HPV"

    include_examples "card",
                     title: "Consent given by Jane Doe (Mum)",
                     date: "30 May 2025 at 12:00pm",
                     programme: "HPV"
  end

  describe "invalidated consent" do
    before do
      create(
        :consent,
        :given,
        :invalidated,
        programme: programmes.first,
        patient:,
        parent: mum,
        submitted_at: Time.zone.local(2025, 5, 30, 12),
        invalidated_at: Time.zone.local(2025, 6, 30, 12)
      )
    end

    include_examples "card",
                     title: "Consent from Jane Doe invalidated",
                     date: "30 June 2025 at 12:00pm",
                     programme: "HPV"

    include_examples "card",
                     title: "Consent given by Jane Doe (Mum)",
                     date: "30 May 2025 at 12:00pm",
                     programme: "HPV"
  end

  describe "gillick assessments" do
    let(:programmes) { [create(:programme, :td_ipv)] }
    let(:patient_session) { create(:patient_session, patient:, programmes:) }

    before do
      create(
        :gillick_assessment,
        :competent,
        performed_by: user,
        patient_session:,
        notes: "First notes",
        created_at: Time.zone.local(2025, 6, 1, 12)
      )
      create(
        :gillick_assessment,
        :not_competent,
        performed_by: user,
        patient_session:,
        notes: "Second notes",
        created_at: Time.zone.local(2025, 6, 1, 13)
      )
    end

    include_examples "card",
                     title: "Completed Gillick assessment as Gillick competent",
                     notes: "First notes",
                     date: "1 June 2025 at 12:00pm",
                     by: "JOY, Nurse",
                     programme: "Td/IPV"

    include_examples "card",
                     title:
                       "Updated Gillick assessment as not Gillick competent",
                     notes: "Second notes",
                     date: "1 June 2025 at 1:00pm",
                     by: "JOY, Nurse",
                     programme: "Td/IPV"
  end

  describe "notes" do
    let(:programmes) { [create(:programme, :hpv)] }
    let(:session) { create(:session, programmes:) }

    before do
      create(
        :note,
        created_by: user,
        patient:,
        session:,
        body: "A note.",
        created_at: Time.zone.local(2026, 6, 1, 12)
      )
    end

    include_examples "card",
                     title: "Note",
                     notes: "A note.",
                     date: "1 June 2026 at 12:00pm",
                     by: "JOY, Nurse",
                     programme: "HPV"
  end

  describe "pre-screenings" do
    let(:patient_session) { create(:patient_session, patient:, programmes:) }

    before do
      create(
        :pre_screening,
        performed_by: user,
        patient_session:,
        notes: "Some notes",
        created_at: Time.zone.local(2025, 6, 1, 12)
      )
    end

    include_examples "card",
                     title: "Completed pre-screening checks",
                     notes: "Some notes",
                     date: "1 June 2025 at 12:00pm",
                     by: "JOY, Nurse",
                     programme: "HPV"
  end

  describe "vaccination records" do
    context "without a vaccine" do
      before do
        create(
          :vaccination_record,
          patient:,
          programme: programmes.first,
          vaccine: nil,
          performed_at: Time.zone.parse("2025-05-31 13:00")
        )
      end

      include_examples "card",
                       title: "Vaccinated",
                       date: "31 May 2025 at 1:00pm",
                       programme: "HPV"
    end
  end

  describe "decision expiration events" do
    let(:hpv_programme) do
      Programme.find_by(type: "hpv") || create(:programme, :hpv)
    end
    let(:flu_programme) do
      Programme.find_by(type: "flu") || create(:programme, :flu)
    end
    let(:programmes) { [hpv_programme, flu_programme] }

    context "with expired consent, triage, and PSD" do
      before do
        create(
          :consent,
          :given,
          programme: hpv_programme,
          patient:,
          parent: mum,
          academic_year: 2024,
          submitted_at: Time.zone.parse("#2024-05-30 12:00")
        )

        create(
          :triage,
          :ready_to_vaccinate,
          programme: hpv_programme,
          patient:,
          academic_year: 2024,
          created_at: Time.zone.parse("#2024-05-30 14:30"),
          performed_by: user
        )

        create(
          :patient_specific_direction,
          programme: hpv_programme,
          patient:,
          created_by: user,
          academic_year: 2024,
          created_at: Time.zone.parse("#2024-05-30 15:00")
        )
      end

      include_examples "card",
                       title:
                         "Consent, health information, triage outcome and PSD status expired",
                       date: "31 August 2025 at 11:59pm",
                       notes: "DOE, Sarah was not vaccinated.",
                       programme: "HPV"
    end

    context "with only expired PSD" do
      before do
        create(
          :patient_specific_direction,
          programme: hpv_programme,
          patient:,
          created_by: user,
          academic_year: 2024,
          created_at: Time.zone.parse("#2024-05-30 15:00")
        )
      end

      include_examples "card",
                       title: "PSD status expired",
                       date: "31 August 2025 at 11:59pm",
                       notes: "DOE, Sarah was not vaccinated.",
                       programme: "HPV"
    end

    context "with vaccinated patient" do
      before do
        create(
          :patient_specific_direction,
          programme: hpv_programme,
          patient:,
          created_by: user,
          academic_year: 2024,
          created_at: Time.zone.parse("#2024-05-30 15:00")
        )

        create(
          :vaccination_record,
          programme: hpv_programme,
          patient:,
          session:,
          performed_at: Time.zone.parse("#2024-05-31 12:00"),
          performed_by: user
        )

        create(
          :patient_specific_direction,
          programme: flu_programme,
          patient:,
          created_by: user,
          academic_year: 2024,
          created_at: Time.zone.parse("#2024-05-30 15:00")
        )
      end

      include_examples "card",
                       title: "PSD status expired",
                       date: "31 August 2025 at 11:59pm",
                       notes: "DOE, Sarah was not vaccinated.",
                       programme: "Flu"
    end
  end
end
