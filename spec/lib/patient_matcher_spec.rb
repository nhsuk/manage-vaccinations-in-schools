# frozen_string_literal: true

describe PatientMatcher do
  shared_examples "patient matching behavior" do
    subject(:match_existing) do
      if candidates.nil?
        described_class.from_relation(
          Patient.all,
          nhs_number:,
          given_name:,
          family_name:,
          date_of_birth:,
          address_postcode:,
          include_3_out_of_4_matches:
        )
      else
        described_class.from_enumerable(
          candidates,
          nhs_number:,
          given_name:,
          family_name:,
          date_of_birth:,
          address_postcode:,
          include_3_out_of_4_matches:
        )
      end
    end

    let(:nhs_number) { "0123456789" }
    let(:given_name) { "John" }
    let(:family_name) { "Smith" }
    let(:date_of_birth) { Date.new(1999, 1, 1) }
    let(:address_postcode) { "SW1A 1AA" }
    let(:include_3_out_of_4_matches) { true }

    def build_or_create_patient(**attrs)
      if candidates.nil?
        create(:patient, **attrs)
      else
        patient =
          Patient.new(
            {
              nhs_number: nil,
              given_name: "Unrelated",
              family_name: "Person",
              date_of_birth: Date.new(2000, 1, 1),
              address_postcode: nil
            }.merge(attrs)
          )

        candidates << patient
        patient
      end
    end

    context "with no matches" do
      let(:patient) { build_or_create_patient }

      it { should_not include(patient) }
    end

    context "with a matching NHS number" do
      let!(:patient) { build_or_create_patient(nhs_number:) }

      it { should include(patient) }

      context "when other patients match too" do
        let(:other_patient) do
          build_or_create_patient(
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
        build_or_create_patient(given_name:, family_name:, date_of_birth:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and date of birth and postcode not provided" do
      let(:nhs_number) { nil }
      let(:address_postcode) { nil }
      let(:patient) do
        build_or_create_patient(given_name:, family_name:, date_of_birth:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        build_or_create_patient(given_name:, family_name:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and postcode not provided" do
      let(:nhs_number) { nil }
      let(:address_postcode) { nil }
      let(:patient) do
        build_or_create_patient(
          given_name:,
          family_name:,
          address_postcode: nil
        )
      end

      it { should_not include(patient) }
    end

    context "with matching first name, date of birth and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        build_or_create_patient(given_name:, date_of_birth:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching last name, date of birth and postcode" do
      let(:nhs_number) { nil }
      let(:patient) do
        build_or_create_patient(family_name:, date_of_birth:, address_postcode:)
      end

      it { should include(patient) }
    end

    context "with matching first name, last name and date of birth but names are uppercase" do
      let(:nhs_number) { nil }
      let(:patient) do
        build_or_create_patient(
          given_name: given_name.upcase,
          family_name: family_name.upcase,
          date_of_birth:
        )
      end

      it { should include(patient) }
    end

    context "when postcode is provided and there is exactly one exact 4-of-4 match" do
      let(:nhs_number) { nil }

      let!(:exact_patient) do
        build_or_create_patient(
          given_name:,
          family_name:,
          date_of_birth:,
          address_postcode:
        )
      end

      before do
        build_or_create_patient(
          given_name:,
          family_name:,
          date_of_birth:,
          address_postcode: "SW1A 2AA"
        )

        build_or_create_patient(
          given_name:,
          family_name:,
          date_of_birth: Date.new(1998, 1, 1),
          address_postcode:
        )

        build_or_create_patient(
          given_name:,
          family_name: "Jones",
          date_of_birth:,
          address_postcode:
        )

        build_or_create_patient(
          given_name: "Jack",
          family_name:,
          date_of_birth:,
          address_postcode:
        )
      end

      it { should contain_exactly(exact_patient) }
    end

    context "when postcode is provided and there is more than one exact 4-of-4 match" do
      let(:nhs_number) { nil }

      let!(:first_exact_patient) do
        build_or_create_patient(
          given_name:,
          family_name:,
          date_of_birth:,
          address_postcode:
        )
      end
      let!(:second_exact_patient) do
        build_or_create_patient(
          given_name:,
          family_name:,
          date_of_birth:,
          address_postcode:
        )
      end

      let!(:same_name_and_dob_different_postcode) do
        build_or_create_patient(
          given_name:,
          family_name:,
          date_of_birth:,
          address_postcode: "SW1A 2AA"
        )
      end

      it do
        expect(match_existing).to contain_exactly(
          first_exact_patient,
          second_exact_patient,
          same_name_and_dob_different_postcode
        )
      end
    end

    context "when include_3_out_of_4_matches is false" do
      let(:nhs_number) { nil }
      let(:include_3_out_of_4_matches) { false }

      context "when all four datapoints match" do
        let!(:patient) do
          build_or_create_patient(
            given_name:,
            family_name:,
            date_of_birth:,
            address_postcode:
          )
        end

        before do
          build_or_create_patient(
            given_name:,
            family_name:,
            date_of_birth:,
            address_postcode: "SW1A 2AA"
          )
        end

        it { should contain_exactly(patient) }
      end

      context "when only three datapoints match" do
        before do
          build_or_create_patient(
            given_name:,
            family_name:,
            date_of_birth:,
            address_postcode: "SW1A 2AA"
          )
        end

        it { should be_empty }
      end

      context "when postcode is not provided" do
        let(:address_postcode) { nil }

        let!(:patient) do
          build_or_create_patient(given_name:, family_name:, date_of_birth:)
        end

        it { should contain_exactly(patient) }
      end
    end

    context "when postcode is provided in a non-normalised format" do
      let(:nhs_number) { nil }
      let(:address_postcode) { " sw1a1aa " }

      let!(:patient) do
        build_or_create_patient(
          given_name:,
          family_name:,
          date_of_birth: Date.new(2000, 1, 1),
          address_postcode: "SW1A 1AA"
        )
      end

      it { should contain_exactly(patient) }
    end

    context "when NHS number is provided in a non-normalised format" do
      let(:nhs_number) { " 012 345 6789 " }

      let!(:patient) do
        build_or_create_patient(
          nhs_number: "0123456789",
          given_name: "Same",
          family_name: "Person",
          date_of_birth: Date.new(2000, 1, 1)
        )
      end

      it { should contain_exactly(patient) }
    end

    context "when postcode is invalid" do
      let(:nhs_number) { nil }
      let(:address_postcode) { "NOT A POSTCODE" }

      let!(:patient) do
        build_or_create_patient(
          given_name:,
          family_name:,
          date_of_birth:,
          address_postcode: "SW1A 1AA"
        )
      end

      it { should contain_exactly(patient) }
    end

    context "when name inputs include SQL LIKE wildcard characters" do
      let(:nhs_number) { nil }
      let(:given_name) { "Jo%n" }
      let(:family_name) { "Sm_th" }
      let(:address_postcode) { nil }

      let!(:literal_patient) do
        build_or_create_patient(given_name:, family_name:, date_of_birth:)
      end
      let!(:wildcard_patient) do
        build_or_create_patient(
          given_name: "John",
          family_name: "Smith",
          date_of_birth:
        )
      end

      it do
        expect(match_existing).to contain_exactly(literal_patient)
        expect(match_existing).not_to include(wildcard_patient)
      end
    end

    context "when matching everything except the NHS number" do
      let(:other_patient) do
        build_or_create_patient(
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

  describe ".from_relation" do
    let(:candidates) { nil }

    include_examples "patient matching behavior"
  end

  describe ".from_enumerable" do
    let(:candidates) { [] }

    include_examples "patient matching behavior"
  end
end
