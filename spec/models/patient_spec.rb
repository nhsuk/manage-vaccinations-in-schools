# frozen_string_literal: true

# == Schema Information
#
# Table name: patients
#
#  id                         :bigint           not null, primary key
#  address_line_1             :string
#  address_line_2             :string
#  address_postcode           :string
#  address_town               :string
#  birth_academic_year        :integer          not null
#  date_of_birth              :date             not null
#  date_of_death              :date
#  date_of_death_recorded_at  :datetime
#  family_name                :string           not null
#  gender_code                :integer          default("not_known"), not null
#  given_name                 :string           not null
#  home_educated              :boolean
#  invalidated_at             :datetime
#  nhs_number                 :string
#  pending_changes            :jsonb            not null
#  preferred_family_name      :string
#  preferred_given_name       :string
#  registration               :string
#  registration_academic_year :integer
#  restricted_at              :datetime
#  updated_from_pds_at        :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  gp_practice_id             :bigint
#  school_id                  :bigint
#
# Indexes
#
#  index_patients_on_family_name_trigram        (family_name) USING gin
#  index_patients_on_given_name_trigram         (given_name) USING gin
#  index_patients_on_gp_practice_id             (gp_practice_id)
#  index_patients_on_names_family_first         (family_name,given_name)
#  index_patients_on_names_given_first          (given_name,family_name)
#  index_patients_on_nhs_number                 (nhs_number) UNIQUE
#  index_patients_on_pending_changes_not_empty  (id) WHERE (pending_changes <> '{}'::jsonb)
#  index_patients_on_school_id                  (school_id)
#
# Foreign Keys
#
#  fk_rails_...  (gp_practice_id => locations.id)
#  fk_rails_...  (school_id => locations.id)
#

describe Patient do
  describe "associations" do
    it { should have_many(:archive_reasons) }

    describe "#vaccination_records" do
      subject(:vaccination_records) { patient.vaccination_records }

      let(:patient) { create(:patient) }
      let(:programme) { create(:programme) }
      let(:kept_vaccination_record) do
        create(:vaccination_record, patient:, programme:)
      end
      let(:discarded_vaccination_record) do
        create(:vaccination_record, :discarded, patient:, programme:)
      end

      it { should include(kept_vaccination_record) }
      it { should_not include(discarded_vaccination_record) }
    end
  end

  describe "scopes" do
    describe "#archived" do
      subject(:scope) { described_class.archived(team:) }

      let(:patient) { create(:patient) }
      let(:team) { create(:team) }

      context "without an archive reason" do
        it { should_not include(patient) }
      end

      context "with an archive reason for the team" do
        before { create(:archive_reason, :moved_out_of_area, team:, patient:) }

        it { should include(patient) }
      end

      context "with an archive reason for a different team" do
        before { create(:archive_reason, :imported_in_error, patient:) }

        it { should_not include(patient) }
      end
    end

    describe "#not_archived" do
      subject(:scope) { described_class.not_archived(team:) }

      let(:patient) { create(:patient) }
      let(:team) { create(:team) }

      context "without an archive reason" do
        it { should include(patient) }
      end

      context "with an archive reason for the team" do
        before { create(:archive_reason, :moved_out_of_area, team:, patient:) }

        it { should_not include(patient) }
      end

      context "with an archive reason for a different team" do
        before { create(:archive_reason, :imported_in_error, patient:) }

        it { should include(patient) }
      end
    end

    describe "#with_pending_changes" do
      subject(:scope) { described_class.with_pending_changes_for_team(team:) }

      let(:team) { create(:team) }
      let(:patient) { create(:patient) }

      context "without pending changes" do
        it { should_not include(patient) }
      end

      context "with pending changes" do
        before do
          patient.update!(pending_changes: { "some_field" => "new_value" })
        end

        it { should include(patient) }
      end

      context "with pending changes but archived from the team" do
        before do
          patient.update!(pending_changes: { "some_field" => "new_value" })
          create(:archive_reason, :moved_out_of_area, team:, patient:)
        end

        it { should_not include(patient) }
      end
    end

    describe "#appear_in_programmes" do
      subject(:scope) do
        described_class.appear_in_programmes(programmes, academic_year:)
      end

      let(:programmes) { create_list(:programme, 1, :td_ipv) }
      let(:academic_year) { AcademicYear.current }

      it { should be_empty }

      context "with a patient in no sessions" do
        before { create(:patient) }

        it { should be_empty }
      end

      context "in a session with the right year group" do
        let(:session) { create(:session, programmes:) }

        let(:patient) { create(:patient, session:, year_group: 9) }

        it { should include(patient) }
      end

      context "in a session but the wrong year group" do
        let(:session) { create(:session, programmes:) }

        let(:patient) { create(:patient, session:, year_group: 8) }

        it { should_not include(patient) }
      end

      context "in a session with the right year group for the programme but not the location" do
        let(:location) { create(:school, :secondary) }
        let(:patient) { create(:patient, session:, year_group: 9) }
        let(:session) { create(:session, location:, programmes:) }

        before do
          programmes.each do |programme|
            create(
              :location_programme_year_group,
              programme:,
              location:,
              year_group: 10
            )
          end
        end

        it { should_not include(patient) }
      end

      context "in multiple sessions with the right year group for one programme" do
        let(:flu_programme) { create(:programme, :flu) }
        let(:hpv_programme) { create(:programme, :hpv) }

        let(:location) do
          create(:school, programmes: [flu_programme, hpv_programme])
        end
        let(:academic_year) { AcademicYear.current }

        # Year 4 is eligible for flu only.
        let(:patient) { create(:patient, year_group: 4) }

        # Year 9 is eligible for flu and HPV only.
        let(:another_patient) { create(:patient, year_group: 9) }

        before do
          create(:session, location:, programmes: [flu_programme])
          create(:session, location:, programmes: [hpv_programme])

          create(:patient_location, patient:, location:, academic_year:)
          create(
            :patient_location,
            patient: another_patient,
            location:,
            academic_year:
          )
        end

        context "for the right programme" do
          let(:programmes) { [flu_programme] }

          it { should include(patient) }
        end

        context "for the wrong programme" do
          let(:programmes) { [hpv_programme] }

          it { should_not include(patient) }
        end
      end
    end

    describe "#not_appear_in_programmes" do
      subject(:scope) do
        described_class.not_appear_in_programmes(programmes, academic_year:)
      end

      let(:programmes) { create_list(:programme, 1, :td_ipv) }
      let(:academic_year) { AcademicYear.current }

      it { should be_empty }

      context "with a patient in no sessions" do
        let(:patient) { create(:patient) }

        it { should include(patient) }
      end

      context "in a session with the right year group" do
        let(:session) { create(:session, programmes:) }

        before { create(:patient, session:, year_group: 9) }

        it { should be_empty }
      end

      context "in a session but the wrong year group" do
        let(:session) { create(:session, programmes:) }

        let(:patient) { create(:patient, session:, year_group: 8) }

        it { should include(patient) }
      end

      context "in a session with the right year group for the programme but not the location" do
        let(:location) { create(:school, :secondary) }
        let(:session) { create(:session, location:, programmes:) }
        let(:patient) { create(:patient, session:, year_group: 9) }

        before do
          programmes.each do |programme|
            create(
              :location_programme_year_group,
              programme:,
              location:,
              year_group: 10
            )
          end
        end

        it { should include(patient) }
      end

      context "in multiple sessions with the right year group for one programme" do
        let(:flu_programme) { create(:programme, :flu) }
        let(:hpv_programme) { create(:programme, :hpv) }

        let(:location) do
          create(:school, programmes: [flu_programme, hpv_programme])
        end
        let(:academic_year) { AcademicYear.current }

        # Year 4 is eligible for flu only.
        let!(:patient) { create(:patient, year_group: 4) }

        # Year 9 is eligible for flu and HPV only.
        let(:another_patient) { create(:patient, year_group: 9) }

        before do
          create(:session, location:, programmes: [flu_programme])
          create(:session, location:, programmes: [hpv_programme])

          create(:patient_location, patient:, location:, academic_year:)
          create(
            :patient_location,
            patient: another_patient,
            location:,
            academic_year:
          )
        end

        context "for the right programme" do
          let(:programmes) { [flu_programme] }

          it { should be_empty }
        end

        context "for the wrong programme" do
          let(:programmes) { [hpv_programme] }

          it { should include(patient) }
        end
      end
    end

    describe "#search_by_name" do
      subject(:scope) { described_class.search_by_name(query) }

      describe "case insensitivity" do
        let!(:patient_mixed_case) do
          create(:patient, given_name: "JoHn", family_name: "SmItH")
        end

        context "with lowercase query" do
          let(:query) { "john smith" }

          it "finds the patient regardless of case" do
            expect(scope).to include(patient_mixed_case)
          end
        end

        context "with uppercase query" do
          let(:query) { "JOHN SMITH" }

          it "finds the patient regardless of case" do
            expect(scope).to include(patient_mixed_case)
          end
        end

        context "with mixed case query" do
          let(:query) { "JoHn SmITh" }

          it "finds the patient regardless of case" do
            expect(scope).to include(patient_mixed_case)
          end
        end
      end

      describe "comma handling" do
        let!(:patient_comma_test) do
          create(:patient, given_name: "Sarah", family_name: "Connor")
        end

        context "with comma-separated query 'Connor, Sarah'" do
          let(:query) { "Connor, Sarah" }

          it "finds the patient by treating comma as name separator" do
            expect(scope).to include(patient_comma_test)
          end
        end

        context "with comma-separated query with extra spaces 'Connor, Sarah'" do
          let(:query) { "Connor,  Sarah" }

          it "finds the patient by treating comma as name separator" do
            expect(scope).to include(patient_comma_test)
          end
        end

        context "with comma-separated query 'CONNOR, sarah'" do
          let(:query) { "CONNOR, sarah" }

          it "finds the patient with case insensitive comma handling" do
            expect(scope).to include(patient_comma_test)
          end
        end
      end

      describe "comprehensive search ordering with all match types" do
        let(:expected_order) do
          [
            perfect_full_given_family,
            perfect_family_only,
            perfect_given_only,
            prefix_family,
            prefix_given,
            mid_family,
            mid_given,
            similar_given_in_family,
            similar_given,
            similar_family,
            similar_family_in_given
          ]
        end

        let!(:perfect_full_given_family) do
          create(:patient, given_name: "Emma", family_name: "Watson")
        end
        let!(:perfect_family_only) do
          create(:patient, given_name: "David", family_name: "Watson")
        end
        let!(:perfect_given_only) do
          create(:patient, given_name: "Emma", family_name: "Thompson")
        end
        let!(:prefix_family) do
          create(:patient, given_name: "Michael", family_name: "Watsonville")
        end
        let!(:prefix_given) do
          create(:patient, given_name: "Emmanuel", family_name: "Davis")
        end
        let!(:mid_family) do
          create(:patient, given_name: "Sarah", family_name: "Swatson")
        end
        let!(:mid_given) do
          create(:patient, given_name: "Lemma", family_name: "Johnson")
        end
        let!(:similar_family) do
          create(:patient, given_name: "James", family_name: "Watsan")
        end
        let!(:similar_family_in_given) do
          create(:patient, given_name: "Watsan", family_name: "Champagne")
        end
        let!(:similar_given) do
          create(:patient, given_name: "Ema", family_name: "Parsons")
        end
        let!(:similar_given_in_family) do
          create(:patient, given_name: "Kyle", family_name: "Ema")
        end

        before do
          create(:patient, given_name: "Daniel", family_name: "Radcliffe")
        end

        context "with full name search" do
          [
            "Emma Watson",
            "Watson Emma",
            "WATSON, Emma",
            "Watson,   Emma"
          ].each do |query_string|
            context "with query '#{query_string}'" do
              let(:query) { query_string }

              it "returns all matching patients in correct priority order" do
                expect(scope).to eq(expected_order)
              end
            end
          end
        end

        context "with single prefect name" do
          context "with query of perfect given name only" do
            let(:query) { "Emma" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                perfect_given_only,
                perfect_full_given_family,
                prefix_given,
                mid_given,
                similar_given_in_family,
                similar_given
              ]
              expect(scope).to eq(expected_order)
            end
          end

          context "with query of perfect family name only" do
            let(:query) { "Watson" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                perfect_family_only,
                perfect_full_given_family,
                prefix_family,
                mid_family,
                similar_family,
                similar_family_in_given
              ]
              expect(scope).to eq(expected_order)
            end
          end
        end

        context "with prefixes" do
          context "with query of prefix given name only (short)" do
            let(:query) { "Em" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                similar_given_in_family,
                similar_given,
                perfect_given_only,
                perfect_full_given_family,
                prefix_given
              ]
              expect(scope).to eq(expected_order)
            end
          end

          context "with query of prefix given name only (long)" do
            let(:query) { "Emm" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                perfect_given_only,
                perfect_full_given_family,
                prefix_given,
                mid_given,
                similar_given_in_family,
                similar_given
              ]
              expect(scope).to eq(expected_order)
            end
          end

          context "with query of prefix family name only (short)" do
            let(:query) { "Wa" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                similar_family,
                perfect_family_only,
                perfect_full_given_family,
                similar_family_in_given,
                prefix_family
              ]
              expect(scope).to eq(expected_order)
            end
          end

          context "with query of prefix family name only (long)" do
            let(:query) { "Wats" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                similar_family,
                perfect_family_only,
                perfect_full_given_family,
                similar_family_in_given,
                prefix_family,
                mid_family
              ]
              expect(scope).to eq(expected_order)
            end
          end
        end

        context "with multiple prefix terms" do
          context "with query of prefix_family (short) prefix_given (short)" do
            let(:query) { "em wa" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                perfect_full_given_family,
                similar_given_in_family,
                similar_given,
                perfect_given_only,
                similar_family,
                perfect_family_only,
                similar_family_in_given,
                prefix_given,
                prefix_family
              ]
              expect(scope).to eq(expected_order)
            end
          end

          context "with query of prefix_family (long) prefix_given (long)" do
            let(:query) { "emm wats" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                perfect_full_given_family,
                similar_family,
                perfect_family_only,
                similar_family_in_given,
                perfect_given_only,
                prefix_family,
                prefix_given,
                mid_family,
                mid_given,
                similar_given_in_family,
                similar_given
              ]
              expect(scope).to eq(expected_order)
            end
          end

          context "with query of prefix_given (short) prefix_family (short)" do
            let(:query) { "wa em" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                perfect_full_given_family,
                similar_given_in_family,
                similar_given,
                perfect_given_only,
                similar_family,
                perfect_family_only,
                similar_family_in_given,
                prefix_given,
                prefix_family
              ]
              expect(scope).to eq(expected_order)
            end
          end

          context "with query of prefix_given (long) prefix_family (long)" do
            let(:query) { "wats emm" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                perfect_full_given_family,
                similar_family,
                perfect_family_only,
                similar_family_in_given,
                perfect_given_only,
                prefix_family,
                prefix_given,
                mid_family,
                mid_given,
                similar_given_in_family,
                similar_given
              ]
              expect(scope).to eq(expected_order)
            end
          end

          context "with query of prefix_given (long) prefix_family (v short)" do
            let(:query) { "emm w" }

            it "returns all matching patients in correct priority order, then by similarity" do
              expected_order = [
                perfect_full_given_family,
                perfect_given_only,
                prefix_given,
                similar_family,
                perfect_family_only,
                similar_family_in_given,
                prefix_family,
                mid_given,
                similar_given_in_family,
                similar_given
              ]
              expect(scope).to eq(expected_order)
            end
          end
        end
      end
    end

    describe "#order_by_name" do
      subject(:scope) { described_class.order_by_name }

      let(:patient_a) { create(:patient, family_name: "Adams") }
      let(:patient_b) do
        create(:patient, given_name: "christine", family_name: "Jones")
      end
      let(:patient_c) do
        create(:patient, given_name: "claire", family_name: "Jones")
      end

      it { should eq([patient_a, patient_b, patient_c]) }
    end

    describe "#consent_given_and_safe_to_vaccinate" do
      subject(:scope) do
        described_class.consent_given_and_safe_to_vaccinate(
          programmes:,
          academic_year:,
          vaccine_method:,
          without_gelatine:
        )
      end

      let(:programmes) { [create(:programme, :flu), create(:programme, :hpv)] }
      let(:session) { create(:session, programmes:) }
      let(:academic_year) { AcademicYear.current }
      let(:vaccine_method) { nil }
      let(:without_gelatine) { nil }

      it { should be_empty }

      context "with a patient eligible for vaccination" do
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should include(patient) }
      end

      context "when filtering on nasal spray" do
        let(:vaccine_method) { "nasal" }

        context "with a patient eligible for vaccination" do
          let(:patient) do
            create(:patient, :consent_given_triage_not_needed, session:)
          end

          before do
            patient.consent_status(
              programme: programmes.first,
              academic_year:
            ).update!(vaccine_methods: %w[nasal injection])
          end

          it { should include(patient) }

          context "when the patient has been vaccinated for flu" do
            before do
              create(
                :vaccination_record,
                programme: programmes.first,
                session:,
                patient:
              )
              StatusUpdater.call(session:, patient:)
            end

            it { should_not include(patient) }
          end
        end
      end
    end
  end

  describe "validations" do
    context "when home educated" do
      subject(:patient) { build(:patient, :home_educated) }

      it { should validate_absence_of(:school) }
    end

    context "with an invalid GP practice" do
      subject(:patient) { build(:patient, gp_practice: create(:school)) }

      it "is invalid" do
        expect(patient.valid?).to be(false)
        expect(patient.errors[:gp_practice]).to include(
          "must be a GP practice location type"
        )
      end
    end

    context "with an invalid school" do
      subject(:patient) { build(:patient, school: create(:community_clinic)) }

      it "is invalid" do
        expect(patient.valid?).to be(false)
        expect(patient.errors[:school]).to include(
          "must be a school location type"
        )
      end
    end
  end

  describe "normalizations" do
    let(:patient) { described_class.new }

    it do
      expect(patient).to normalize(:nhs_number).from(
        "012\u200D345\u200D6789"
      ).to("0123456789")
    end

    it { should normalize(:nhs_number).from(" 0123456789 ").to("0123456789") }

    it { should normalize(:address_postcode).from(" SW111AA ").to("SW11 1AA") }
  end

  describe "#teams" do
    subject(:teams) { patient.teams }

    let(:patient) { create(:patient) }

    it { should be_empty }

    context "when a team exists" do
      let!(:team) { create(:team) }

      it { should be_empty }

      context "and the patient belongs to the team" do
        let(:session) { create(:session, team:) }
        let(:patient) { create(:patient, session:) }

        it { should include(team) }
      end

      context "and the patient belongs to multiple sessions under the same team" do
        let(:menacwy_session) do
          create(:session, team:, programmes: [create(:programme, :menacwy)])
        end
        let(:td_ipv_session) do
          create(:session, team:, programmes: [create(:programme, :td_ipv)])
        end
        let(:patient) { create(:patient, session: menacwy_session) }

        before { create(:patient_location, patient:, session: td_ipv_session) }

        it { should contain_exactly(team) }
      end
    end
  end

  describe "#match_existing" do
    subject(:match_existing) do
      described_class.match_existing(
        nhs_number:,
        given_name:,
        family_name:,
        date_of_birth:,
        address_postcode:
      )
    end

    let(:nhs_number) { "0123456789" }
    let(:given_name) { "John" }
    let(:family_name) { "Smith" }
    let(:date_of_birth) { Date.new(1999, 1, 1) }
    let(:address_postcode) { "SW1A 1AA" }

    context "with no matches" do
      let(:patient) { create(:patient) }

      it { should_not include(patient) }
    end

    context "with a matching NHS number" do
      let!(:patient) { create(:patient, nhs_number:) }

      it { should include(patient) }

      context "when other patients match too" do
        let(:other_patient) do
          create(
            :patient,
            nhs_number: nil,
            given_name:,
            family_name:,
            date_of_birth:
          )
        end

        it { should_not include(other_patient) }
      end
    end

    context "with matching first name, last name and date of birth" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, given_name:, family_name:, date_of_birth:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and date of birth and postcode not provided" do
      let(:nhs_number) { nil }
      let(:address_postcode) { nil }
      let(:patient) do
        create(:patient, given_name:, family_name:, date_of_birth:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, given_name:, family_name:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and postcode not provided" do
      let(:nhs_number) { nil }
      let(:address_postcode) { nil }
      let(:patient) do
        create(:patient, given_name:, family_name:, address_postcode: nil)
      end

      it { should_not include(patient) }
    end

    context "with matching first name, date of birth and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, given_name:, date_of_birth:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching last name, date of birth and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(:patient, family_name:, date_of_birth:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and date of birth but names are uppercase" do
      let(:nhs_number) { nil }
      let(:patient) do
        create(
          :patient,
          given_name: given_name.upcase,
          family_name: family_name.upcase,
          date_of_birth:
        )
      end

      it { should include(patient) }
    end

    context "when matching everything except the NHS number" do
      let(:other_patient) do
        create(
          :patient,
          nhs_number: "9876543210",
          given_name:,
          family_name:,
          date_of_birth:,
          address_postcode:
        )
      end

      it { should_not include(other_patient) }
    end
  end

  describe "#archived?" do
    subject(:archived?) { patient.archived?(team:) }

    let(:patient) { create(:patient) }
    let(:team) { create(:team) }

    context "without an archive reason" do
      it { should be(false) }
    end

    context "with an archive reason for the team" do
      before { create(:archive_reason, :moved_out_of_area, team:, patient:) }

      it { should be(true) }
    end

    context "with an archive reason for a different team" do
      before { create(:archive_reason, :imported_in_error, patient:) }

      it { should be(false) }
    end
  end

  describe "#not_archived?" do
    subject(:not_archived?) { patient.not_archived?(team:) }

    let(:patient) { create(:patient) }
    let(:team) { create(:team) }

    context "without an archive reason" do
      it { should be(true) }
    end

    context "with an archive reason for the team" do
      before { create(:archive_reason, :moved_out_of_area, team:, patient:) }

      it { should be(false) }
    end

    context "with an archive reason for a different team" do
      before { create(:archive_reason, :imported_in_error, patient:) }

      it { should be(true) }
    end
  end

  describe "#show_year_group?" do
    subject { patient.show_year_group?(team:) }

    let(:programmes) { [create(:programme, :flu), create(:programme, :hpv)] }
    let(:team) { create(:team, programmes:) }
    let(:school) { create(:school, team:) }

    context "outside the preparation period" do
      around { |example| travel_to(Date.new(2025, 7, 31)) { example.run } }

      context "for a year 1" do
        let(:patient) { create(:patient, school:, year_group: 1) }

        it { should be(true) }
      end

      context "for a year 7" do
        let(:patient) { create(:patient, school:, year_group: 7) }

        it { should be(true) }
      end

      context "for a year 11" do
        let(:patient) { create(:patient, school:, year_group: 11) }

        it { should be(true) }
      end

      context "for a year 12" do
        let(:patient) { create(:patient, school:, year_group: 12) }

        it { should be(false) }
      end
    end

    context "inside the preparation period" do
      around { |example| travel_to(Date.new(2025, 8, 1)) { example.run } }

      context "for a year 1" do
        let(:patient) { create(:patient, school:, year_group: 1) }

        it { should be(true) }
      end

      context "for a year 7" do
        let(:patient) { create(:patient, school:, year_group: 7) }

        it { should be(true) }
      end

      context "for a year 11" do
        let(:patient) { create(:patient, school:, year_group: 11) }

        it { should be(false) }
      end

      context "for a year 12" do
        let(:patient) { create(:patient, school:, year_group: 12) }

        it { should be(false) }
      end
    end
  end

  describe "#initials" do
    subject { patient.initials }

    let(:patient) { create(:patient, given_name: "John", family_name: "Doe") }

    it { should eq("JD") }
  end

  describe "#has_patient_specific_direction?" do
    subject { patient.has_patient_specific_direction?(team:) }

    let(:team) { create(:team) }
    let(:patient) { create(:patient) }

    it { should be(false) }

    context "with a PSD from the same team" do
      before { create(:patient_specific_direction, patient:, team:) }

      it { should be(true) }
    end

    context "with a PSD from a different team" do
      before { create(:patient_specific_direction, patient:) }

      it { should be(false) }
    end
  end

  describe "#next_activity" do
    subject { patient.next_activity(programme:, academic_year:) }

    let(:patient) { create(:patient) }
    let(:programme) { create(:programme) }
    let(:academic_year) { AcademicYear.current }

    context "with no consent" do
      it { should be(:consent) }
    end

    context "with consent refused" do
      before { create(:patient_consent_status, :refused, patient:, programme:) }

      it { should be(:do_not_record) }
    end

    context "with triaged as do not vaccinate" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_triage_status, :do_not_vaccinate, patient:, programme:)
      end

      it { should be(:do_not_record) }
    end

    context "with consent needing triage" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_triage_status, :required, patient:, programme:)
      end

      it { should be(:triage) }
    end

    context "with triaged as safe to vaccinate" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_triage_status, :safe_to_vaccinate, patient:, programme:)
      end

      it { should be(:record) }
    end

    context "with consent no triage needed" do
      before { create(:patient_consent_status, :given, patient:, programme:) }

      it { should be(:record) }
    end

    context "with an administered vaccination record" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_vaccination_status, :vaccinated, patient:, programme:)
      end

      it { should be_nil }
    end

    context "with an un-administered vaccination record" do
      before do
        create(:patient_consent_status, :given, patient:, programme:)
        create(:patient_vaccination_status, patient:, programme:)
      end

      it { should be(:record) }
    end
  end

  describe "#vaccine_criteria" do
    subject(:vaccine_criteria) do
      patient.vaccine_criteria(programme:, academic_year:)
    end

    let(:patient) { create(:patient) }
    let(:programme) { create(:programme) }
    let(:academic_year) { AcademicYear.current }

    describe "#vaccine_methods" do
      subject { vaccine_criteria.vaccine_methods }

      it { should be_empty }

      context "when consent given and triage not required" do
        before do
          create(
            :patient_consent_status,
            :given,
            patient:,
            programme:,
            vaccine_methods: %w[nasal injection]
          )
        end

        it { should eq(%w[nasal injection]) }
      end

      context "when consent given and triage required" do
        before do
          create(
            :patient_consent_status,
            :given,
            patient:,
            programme:,
            vaccine_methods: %w[nasal injection]
          )
          create(:patient_triage_status, :required, patient:, programme:)
        end

        it { should be_empty }

        context "and when triaged" do
          before do
            patient.triage_status(programme:, academic_year:).update!(
              status: "safe_to_vaccinate",
              vaccine_method: "nasal"
            )
          end

          it { should eq(%w[nasal]) }
        end
      end
    end
  end

  describe "#update_from_pds!" do
    subject(:update_from_pds!) { patient.update_from_pds!(pds_patient) }

    let(:patient) { create(:patient, nhs_number: "0123456789") }
    let(:pds_patient) { PDS::Patient.new(nhs_number: "0123456789") }

    it "doesn't set a date of death" do
      expect { update_from_pds! }.not_to change(patient, :date_of_death)
    end

    it "doesn't flag as restricted" do
      expect { update_from_pds! }.not_to change(patient, :restricted_at)
    end

    it "doesn't change the GP practice" do
      expect { update_from_pds! }.not_to change(patient, :gp_practice)
    end

    it "sets the updated from PDS date and time" do
      freeze_time do
        expect { update_from_pds! }.to change(
          patient,
          :updated_from_pds_at
        ).from(nil).to(Time.current)
      end
    end

    context "when the NHS number doesn't match" do
      let(:pds_patient) { PDS::Patient.new(nhs_number: "abc") }

      it "raises an error" do
        expect { update_from_pds! }.to raise_error(Patient::NHSNumberMismatch)
      end
    end

    context "with notification of death" do
      let(:pds_patient) do
        PDS::Patient.new(
          nhs_number: "0123456789",
          date_of_death: Date.new(2024, 1, 1)
        )
      end

      it "sets the date of death" do
        expect { update_from_pds! }.to change(patient, :date_of_death).to(
          Date.new(2024, 1, 1)
        )
      end

      it "sets the date of death recorded at" do
        freeze_time do
          expect { update_from_pds! }.to change(
            patient,
            :date_of_death_recorded_at
          ).from(nil).to(Time.current)
        end
      end

      context "when in an upcoming session" do
        let(:session) do
          create(
            :session,
            academic_year: AcademicYear.pending,
            date: AcademicYear.pending.to_academic_year_date_range.begin
          )
        end

        let!(:patient_location) do
          create(:patient_location, patient:, session:)
        end

        it "removes the patient from the session" do
          expect(patient.patient_locations).to include(patient_location)
          update_from_pds!
          expect(patient.patient_locations).not_to include(patient_location)
        end

        it "archives the patient" do
          expect { update_from_pds! }.to change(
            patient.archive_reasons,
            :count
          ).from(0).to(1)

          archive_reason = patient.archive_reasons.first
          expect(archive_reason).to be_deceased
          expect(archive_reason.team_id).to eq(session.team_id)
        end

        context "when already archived" do
          let!(:archive_reason) do
            create(
              :archive_reason,
              :moved_out_of_area,
              patient:,
              team: session.team
            )
          end

          it "updates the existing archive reason" do
            expect(archive_reason).to be_moved_out_of_area
            expect { update_from_pds! }.not_to change(ArchiveReason, :count)
            expect(archive_reason.reload).to be_deceased
          end
        end
      end
    end

    context "with a restricted flag" do
      let(:pds_patient) do
        PDS::Patient.new(nhs_number: "0123456789", restricted: true)
      end

      it "sets restricted at" do
        freeze_time do
          expect { update_from_pds! }.to change(patient, :restricted_at).from(
            nil
          ).to(Time.current)
        end
      end
    end

    context "with a GP practice ODS code" do
      let(:gp_practice) { create(:gp_practice) }

      let(:pds_patient) do
        PDS::Patient.new(
          nhs_number: "0123456789",
          gp_ods_code: gp_practice.ods_code
        )
      end

      it "sets the GP practice" do
        expect { update_from_pds! }.to change(patient, :gp_practice).from(
          nil
        ).to(gp_practice)
      end
    end

    context "with a GP practice that doesn't exist" do
      let(:pds_patient) do
        PDS::Patient.new(nhs_number: "0123456789", gp_ods_code: "GP")
      end

      it "records an error in Sentry" do
        expect(Sentry).to receive(:capture_exception).with(
          an_instance_of(Patient::UnknownGPPractice)
        )
        update_from_pds!
      end
    end

    context "when the patient is currently invalidated" do
      let(:patient) do
        create(:patient, :invalidated, school:, nhs_number: "0123456789")
      end

      let(:programme) { create(:programme) }
      let(:team) { create(:team, programmes: [programme]) }
      let(:school) { create(:school, team:) }
      let(:session) { create(:session, location: school, team:, programme:) }

      it "marks the patient as not invalidated" do
        expect { update_from_pds! }.to change(patient, :invalidated?).from(
          true
        ).to(false)
      end
    end
  end

  describe "#invalidate!" do
    subject(:invalidate!) { patient.invalidate! }

    let(:patient) { create(:patient) }

    it "marks the patient as invalidated" do
      expect { invalidate! }.to change(patient, :invalidated?).from(false).to(
        true
      )
    end

    it "sets the date/time of when the patient was invalidated" do
      freeze_time do
        expect { invalidate! }.to change(patient, :invalidated_at).from(nil).to(
          Time.current
        )
      end
    end
  end

  describe "#should_sync_vaccinations_to_nhs_immunisations_api" do
    subject(:should_sync_vaccinations_to_nhs_immunisations_api?) do
      patient.send(:should_sync_vaccinations_to_nhs_immunisations_api?)
    end

    let(:patient) { create(:patient, nhs_number: "9449310475") }
    let(:programme) { create(:programme, type: "hpv") }
    let(:session) { create(:session, programmes: [programme]) }
    let(:vaccination_record) do
      create(:vaccination_record, patient:, programme:, session:)
    end

    context "when nhs_number changes" do
      it "syncs vaccination records to NHS Immunisations API" do
        patient.update!(nhs_number: "9449304130")

        expect(should_sync_vaccinations_to_nhs_immunisations_api?).to be_truthy
      end
    end

    context "when invalidated_at changes" do
      it "syncs vaccination records to NHS Immunisations API" do
        patient.update!(invalidated_at: Time.current)

        expect(should_sync_vaccinations_to_nhs_immunisations_api?).to be_truthy
      end
    end

    context "when other attributes change" do
      it "does not sync vaccination records to NHS Immunisations API" do
        patient.update!(given_name: "NewName")

        expect(should_sync_vaccinations_to_nhs_immunisations_api?).to be_falsy
      end
    end
  end

  describe "#should_search_vaccinations_from_nhs_immunisations_api?" do
    subject(:should_search_vaccinations_from_nhs_immunisations_api?) do
      patient.send(:should_search_vaccinations_from_nhs_immunisations_api?)
    end

    let(:patient) { create(:patient, nhs_number: "9449310475") }

    context "when nhs_number changes" do
      it "syncs vaccination records to NHS Immunisations API" do
        patient.update!(nhs_number: "9449304130")

        expect(
          should_search_vaccinations_from_nhs_immunisations_api?
        ).to be_truthy
      end
    end

    context "when other attributes change" do
      it "does not sync vaccination records to NHS Immunisations API" do
        patient.update!(given_name: "NewName")

        expect(
          should_search_vaccinations_from_nhs_immunisations_api?
        ).to be_falsy
      end
    end
  end

  describe "#stage_changes" do
    let(:patient) { create(:patient, given_name: "John", family_name: "Doe") }

    it "stages new changes in pending_changes" do
      patient.stage_changes(given_name: "Jane", address_line_1: "123 New St")

      expect(patient.pending_changes).to eq(
        { "given_name" => "Jane", "address_line_1" => "123 New St" }
      )
    end

    it "does not stage unchanged attributes" do
      patient.stage_changes(given_name: "John", family_name: "Smith")

      expect(patient.pending_changes).to eq({ "family_name" => "Smith" })
    end

    it "does not update other attributes directly" do
      patient.stage_changes(given_name: "Jane", family_name: "Smith")

      expect(patient.given_name).to eq("John")
      expect(patient.family_name).to eq("Doe")
    end

    it "does not save any changes if no valid changes are provided" do
      expect { patient.stage_changes(given_name: "John") }.not_to(
        change { patient.reload.pending_changes }
      )
    end
  end

  describe "#with_pending_changes" do
    let(:patient) { create(:patient) }

    it "returns the patient with pending changes applied" do
      patient.stage_changes(given_name: "Jane")
      expect(patient.given_name_changed?).to be(false)

      changed_patient = patient.with_pending_changes
      expect(changed_patient.given_name_changed?).to be(true)
      expect(changed_patient.family_name_changed?).to be(false)
      expect(changed_patient.given_name).to eq("Jane")
    end
  end

  describe "#dup_for_pending_changes" do
    subject(:new_patient) { old_patient.dup_for_pending_changes }

    let(:old_patient) { create(:patient) }

    it { should be_valid }

    it "doesn't change the old patient" do
      new_patient
      expect(old_patient).not_to be_changed
    end

    it "clears the NHS number" do
      expect(new_patient.nhs_number).to be_nil
    end

    context "when the old patient has upcoming sessions" do
      let(:location) { create(:school) }

      before do
        create(
          :patient_location,
          patient: old_patient,
          location:,
          academic_year: AcademicYear.pending
        )
      end

      it "adds the new patient to any upcoming sessions" do
        expect(new_patient.patient_locations.size).to eq(1)
        expect(new_patient.patient_locations.first.location).to eq(location)
      end
    end

    context "when the old patient has a school move to a school" do
      let(:school) { create(:school) }

      before { create(:school_move, :to_school, patient: old_patient, school:) }

      it "adds any school moves from the old patient" do
        expect(new_patient.school_moves.size).to eq(1)
        expect(new_patient.school_moves.first.school).to eq(school)
      end
    end

    context "when the old patient has a school move to an unknown school" do
      before { create(:school_move, :to_unknown_school, patient: old_patient) }

      it "adds any school moves from the old patient" do
        expect(new_patient.school_moves.size).to eq(1)
        expect(new_patient.school_moves.first.home_educated).to be(false)
      end
    end

    context "when the old patient has a school move to home-schooled" do
      before { create(:school_move, :to_home_educated, patient: old_patient) }

      it "adds any school moves from the old patient" do
        expect(new_patient.school_moves.size).to eq(1)
        expect(new_patient.school_moves.first.home_educated).to be(true)
      end
    end
  end

  describe "#destroy_childless_parents" do
    context "when parent has only one child" do
      let(:parent) { create(:parent) }
      let!(:patient) { create(:patient, parents: [parent]) }

      it "destroys the parent when the patient is destroyed" do
        expect { patient.destroy }.to change(Parent, :count).by(-1)
      end
    end

    context "when parent has multiple children" do
      let(:parent) { create(:parent) }
      let!(:patient) { create(:patient, parents: [parent]) }

      before { create(:patient, parents: [parent]) }

      it "does not destroy the parent when one patient is destroyed" do
        expect { patient.destroy }.not_to change(Parent, :count)
      end
    end

    context "when patient has multiple parents" do
      let!(:patient) { create(:patient, parents: create_list(:parent, 2)) }

      it "destroys only the childless parents" do
        expect { patient.destroy }.to change(Parent, :count).by(-2)
      end
    end
  end

  describe "#latest_pds_search_result" do
    subject(:latest_pds_search_result) { patient.latest_pds_search_result }

    let(:patient) { create(:patient) }

    context "with no PDS search results" do
      it { should be_nil }
    end

    context "with unique NHS number in PDS search results" do
      let(:import) { create(:class_import) }

      before do
        create(
          :patient_changeset,
          patient:,
          import:,
          pds_nhs_number: "9449304130"
        )
        create(:pds_search_result, patient:, import:, nhs_number: "9449304130")
        create(
          :pds_search_result,
          patient:,
          import:,
          nhs_number: nil,
          step: :no_fuzzy_with_wildcard_family_name
        )
      end

      it { should eq("9449304130") }
    end

    context "with conflicting NHS numbers in PDS search results" do
      before do
        create(:pds_search_result, patient:, nhs_number: "9449304130")
        create(
          :pds_search_result,
          patient:,
          nhs_number: "9449310475",
          step: :no_fuzzy_with_wildcard_family_name
        )
      end

      it { should be_nil }
    end
  end

  describe "#pds_lookup_match?" do
    subject(:pds_lookup_match?) { patient.pds_lookup_match? }

    let(:patient) { create(:patient, nhs_number: "9449304130") }

    context "when patient has no NHS number" do
      let(:patient) { create(:patient, nhs_number: nil) }

      it { should be(false) }
    end

    context "with no PDS search results" do
      it { should be(false) }
    end

    context "with matching PDS search result" do
      let(:import) { create(:class_import) }

      before do
        create(
          :patient_changeset,
          patient:,
          import:,
          pds_nhs_number: "9449304130"
        )
        create(:pds_search_result, patient:, import:, nhs_number: "9449304130")
      end

      it { should be(true) }
    end

    context "with non-matching PDS search result" do
      let(:import) { create(:class_import) }

      before do
        create(
          :patient_changeset,
          patient:,
          import:,
          pds_nhs_number: "9449310475"
        )
        create(:pds_search_result, patient:, import:)
      end

      it { should be(false) }
    end
  end
end
