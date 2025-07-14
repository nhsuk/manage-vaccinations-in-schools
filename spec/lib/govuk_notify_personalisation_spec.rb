# frozen_string_literal: true

describe GovukNotifyPersonalisation do
  subject(:to_h) do
    described_class.new(
      patient:,
      session:,
      consent:,
      consent_form:,
      programmes:,
      vaccination_record:
    ).to_h
  end

  let(:programmes) { [create(:programme, :hpv)] }
  let(:organisation) do
    create(
      :organisation,
      name: "Organisation",
      email: "organisation@example.com",
      phone: "01234 567890",
      phone_instructions: "option 1",
      programmes:
    )
  end

  let(:patient) do
    create(
      :patient,
      given_name: "John",
      family_name: "Smith",
      date_of_birth: Date.new(2012, 2, 1),
      year_group: 8
    )
  end
  let(:location) { create(:school, name: "Hogwarts") }
  let(:session) do
    create(
      :session,
      location:,
      organisation:,
      programmes:,
      date: Date.new(2026, 1, 1)
    )
  end
  let(:consent) { nil }
  let(:consent_form) { nil }
  let(:vaccination_record) { nil }

  it do
    expect(to_h).to match(
      {
        talk_to_your_child_message:
          "## Talk to your child about what they want\n\n" \
            "We suggest you talk to your child about the vaccine before you " \
            "respond to us.\n\nYoung people have the right to refuse " \
            "vaccinations. Those who show " \
            "[‘Gillick competence’](https://www.nhs.uk/conditions/consent-to-treatment/children/) " \
            "have the right to consent to vaccinations themselves. Our team " \
            "may assess Gillick competence during vaccination sessions.",
        catch_up: "no",
        consent_deadline: "Wednesday 31 December",
        consent_link:
          "http://localhost:4000/consents/#{session.slug}/hpv/start",
        full_and_preferred_patient_name: "John Smith",
        has_multiple_dates: "no",
        location_name: "Hogwarts",
        next_or_today_session_date: "Thursday 1 January",
        next_or_today_session_dates: "Thursday 1 January",
        next_or_today_session_dates_or: "Thursday 1 January",
        next_session_date: "Thursday 1 January",
        next_session_dates: "Thursday 1 January",
        next_session_dates_or: "Thursday 1 January",
        not_catch_up: "yes",
        organisation_privacy_notice_url: "https://example.com/privacy-notice",
        organisation_privacy_policy_url: "https://example.com/privacy-policy",
        patient_date_of_birth: "1 February 2012",
        short_patient_name: "John",
        short_patient_name_apos: "John’s",
        subsequent_session_dates_offered_message: "",
        team_email: "organisation@example.com",
        team_name: "Organisation",
        team_phone: "01234 567890 (option 1)",
        vaccination: "HPV vaccination",
        vaccination_and_method: "HPV vaccination",
        vaccine: "HPV vaccine",
        vaccine_and_method: "HPV vaccine",
        vaccine_is_injection: "no",
        vaccine_is_nasal: "no",
        vaccine_side_effects: ""
      }
    )
  end

  context "with a patient in primary school" do
    let(:patient) { create(:patient, year_group: 6) }

    it { should include(talk_to_your_child_message: "") }
  end

  context "when the session is today" do
    let(:session) do
      create(
        :session,
        location:,
        organisation:,
        programmes:,
        dates: [Date.current, Date.tomorrow]
      )
    end

    it "doesn't show today's date in next date" do
      expect(to_h).to include(
        next_or_today_session_date: Date.current.to_fs(:short_day_of_week),
        next_session_date: Date.tomorrow.to_fs(:short_day_of_week)
      )
    end
  end

  context "when patient is in Year 9" do
    let(:patient) do
      create(
        :patient,
        given_name: "John",
        family_name: "Smith",
        date_of_birth: Date.current - 14.years
      )
    end

    it { should include(catch_up: "yes", not_catch_up: "no") }
  end

  context "with multiple programmes" do
    let(:programmes) do
      [create(:programme, :menacwy), create(:programme, :td_ipv)]
    end

    it { should include(vaccination: "MenACWY and Td/IPV vaccinations") }
  end

  context "with multiple dates" do
    before { session.session_dates.create!(value: Date.new(2026, 1, 2)) }

    it do
      expect(to_h).to match(
        hash_including(
          consent_deadline: "Wednesday 31 December",
          has_multiple_dates: "yes",
          next_or_today_session_date: "Thursday 1 January",
          next_or_today_session_dates:
            "Thursday 1 January and Friday 2 January",
          next_or_today_session_dates_or:
            "Thursday 1 January or Friday 2 January",
          next_session_date: "Thursday 1 January",
          next_session_dates: "Thursday 1 January and Friday 2 January",
          next_session_dates_or: "Thursday 1 January or Friday 2 January",
          subsequent_session_dates_offered_message:
            "If they’re not seen, they’ll be offered the vaccination on Friday 2 January."
        )
      )
    end

    context "when today is the first date" do
      around { |example| travel_to(Date.new(2026, 1, 1)) { example.run } }

      it do
        expect(to_h).to match(
          hash_including(
            consent_deadline: "Thursday 1 January",
            next_or_today_session_date: "Thursday 1 January",
            next_or_today_session_dates:
              "Thursday 1 January and Friday 2 January",
            next_or_today_session_dates_or:
              "Thursday 1 January or Friday 2 January",
            next_session_date: "Friday 2 January",
            subsequent_session_dates_offered_message: ""
          )
        )
      end
    end
  end

  context "with a consent" do
    let(:consent) do
      create(
        :consent,
        :refused,
        programme: programmes.first,
        created_at: Date.new(2024, 1, 1)
      )
    end

    it do
      expect(to_h).to match(
        hash_including(
          reason_for_refusal: "of personal choice",
          survey_deadline_date: "8 January 2024"
        )
      )
    end
  end

  context "with a consent form" do
    let(:consent_form) do
      create(
        :consent_form,
        :refused,
        session:,
        recorded_at: Date.new(2024, 1, 1),
        given_name: "Tom"
      )
    end

    it do
      expect(to_h).to include(
        consented_vaccine_methods_message: "",
        location_name: "Hogwarts",
        reason_for_refusal: "of personal choice",
        survey_deadline_date: "8 January 2024"
      )
    end

    context "where the school is different" do
      let(:session) { nil }
      let(:school) { create(:school, name: "Waterloo Road", organisation:) }

      let(:consent_form) do
        create(
          :consent_form,
          :given,
          :recorded,
          session: create(:session, location:, programmes:, organisation:),
          school_confirmed: false,
          school:
        )
      end

      before { create(:session, location: school, programmes:, organisation:) }

      it { should include(location_name: "Waterloo Road") }
    end

    context "for the flu programme" do
      let(:programmes) { [create(:programme, :flu)] }

      it do
        expect(to_h).to include(
          consented_vaccine_methods_message:
            "You’ve agreed that Tom can have the injected flu vaccine."
        )
      end

      context "when consented to both nasal and injection" do
        before do
          consent_form.consent_form_programmes.update!(
            vaccine_methods: %w[nasal injection]
          )
        end

        it do
          expect(to_h).to include(
            consented_vaccine_methods_message:
              "You’ve agreed that Tom can have the nasal spray flu vaccine, " \
                "or the injected flu vaccine if the nasal spray is not suitable."
          )
        end
      end

      context "when consented only to nasal" do
        before do
          consent_form.consent_form_programmes.update!(
            vaccine_methods: %w[nasal]
          )
        end

        it do
          expect(to_h).to include(
            consented_vaccine_methods_message:
              "You’ve agreed that Tom can have the nasal spray flu vaccine."
          )
        end
      end
    end
  end

  context "with an administered vaccination record" do
    let(:vaccine) do
      create(:vaccine, brand: "Vaccine", programme: programmes.first)
    end

    let(:vaccination_record) do
      create(
        :vaccination_record,
        :administered,
        programme: programmes.first,
        performed_at: Date.new(2024, 1, 1),
        vaccine:
      )
    end

    it do
      expect(to_h).to match(
        hash_including(
          day_month_year_of_vaccination: "01/01/2024",
          today_or_date_of_vaccination: "1 January 2024",
          outcome_administered: "yes",
          outcome_not_administered: "no",
          vaccine_brand: "Vaccine"
        )
      )
    end
  end

  context "with a not-administered vaccination record" do
    let(:vaccination_record) do
      create(
        :vaccination_record,
        :not_administered,
        programme: programmes.first,
        performed_at: Date.new(2024, 1, 1)
      )
    end

    it do
      expect(to_h).to match(
        hash_including(
          day_month_year_of_vaccination: "01/01/2024",
          reason_did_not_vaccinate: "the nurse decided John was not well",
          show_additional_instructions: "yes",
          today_or_date_of_vaccination: "1 January 2024",
          outcome_administered: "no",
          outcome_not_administered: "yes"
        )
      )
    end
  end

  context "with vaccine methods" do
    context "and an injection-only programme" do
      before do
        create(
          :patient_consent_status,
          :given,
          patient:,
          programme: programmes.first
        )
      end

      it { should include(vaccine_is_injection: "yes", vaccine_is_nasal: "no") }
    end

    context "and a nasal spray programme" do
      let(:programmes) { [create(:programme, :flu)] }

      before do
        create(
          :patient_consent_status,
          :given,
          patient:,
          programme: programmes.first,
          vaccine_methods: %w[nasal injection]
        )
      end

      it { should include(vaccine_is_injection: "no", vaccine_is_nasal: "yes") }
    end

    context "and multiple programmes" do
      let(:programmes) { [create(:programme, :hpv), create(:programme, :flu)] }

      before do
        create(
          :patient_consent_status,
          :given,
          patient:,
          programme: programmes.first,
          vaccine_methods: %w[nasal injection]
        )
        create(
          :patient_consent_status,
          :given,
          patient:,
          programme: programmes.second
        )
      end

      it do
        expect(to_h).to include(
          vaccine_is_injection: "yes",
          vaccine_is_nasal: "yes"
        )
      end
    end
  end

  context "with vaccine side effects" do
    before do
      programmes.first.vaccines.first.update!(side_effects: %w[swelling unwell])
    end

    it { should include(vaccine_side_effects: "") }

    context "with injection as an approved vaccine method" do
      before do
        create(
          :patient_triage_status,
          :safe_to_vaccinate,
          :injection,
          patient:,
          programme: programmes.first
        )
      end

      it do
        expect(to_h).to match(
          hash_including(
            vaccine_side_effects:
              "- generally feeling unwell\n- swelling or pain where the injection was given"
          )
        )
      end
    end
  end

  context "with the flu programme" do
    let(:programmes) { [create(:programme, :flu)] }

    it do
      expect(to_h).to include(
        vaccination: "Flu vaccination",
        vaccination_and_method: "flu vaccination",
        vaccine: "Flu vaccine",
        vaccine_and_method: "flu vaccine"
      )
    end

    context "with an administered injected vaccination record" do
      let(:vaccination_record) do
        create(:vaccination_record, patient:, programme: programmes.first)
      end

      it do
        expect(to_h).to include(
          vaccination: "Flu vaccination",
          vaccination_and_method: "injected flu vaccination",
          vaccine: "Flu vaccine",
          vaccine_and_method: "injected flu vaccine"
        )
      end
    end

    context "with an administered nasal spray vaccination record" do
      let(:vaccination_record) do
        create(
          :vaccination_record,
          patient:,
          programme: programmes.first,
          delivery_method: "nasal_spray"
        )
      end

      it do
        expect(to_h).to include(
          vaccination: "Flu vaccination",
          vaccination_and_method: "nasal spray flu vaccination",
          vaccine: "Flu vaccine",
          vaccine_and_method: "nasal spray flu vaccine"
        )
      end
    end
  end
end
