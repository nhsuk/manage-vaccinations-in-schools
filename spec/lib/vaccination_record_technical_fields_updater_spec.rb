# frozen_string_literal: true

describe VaccinationRecordTechnicalFieldsUpdater do
  let(:vaccination_record) { create(:vaccination_record) }

  describe "#call" do
    describe "updating allowed attributes" do
      subject(:reloaded_vaccination_record) do
        described_class.call(vaccination_record: vaccination_record, updates:)
        vaccination_record.reload
      end

      context "updates allowed string attributes (uuid)" do
        let(:new_uuid) { SecureRandom.uuid }

        let(:updates) { { uuid: new_uuid } }

        its(:uuid) { should eq new_uuid }
      end

      context "coerces integer attributes from string (source)" do
        let(:updates) { { source: "2" } }

        its(:source_before_type_cast) { should eq 2 }
      end

      context "coerces datetime attributes from string (confirmation_sent_at)" do
        let(:time_str) { "2024-05-17T10:30:00Z" }

        let(:updates) { { confirmation_sent_at: time_str } }

        its(:confirmation_sent_at) do
          should be_within(1.second).of(Time.zone.parse(time_str))
        end
      end

      context "sets attributes to nil when given 'nil' string" do
        before do
          vaccination_record.update!(nhs_immunisations_api_etag: "etag-123")
        end

        let(:updates) { { nhs_immunisations_api_etag: "nil" } }

        its(:nhs_immunisations_api_etag) { should be_nil }
      end

      context "coerces true attributes from string" do
        let(:updates) { { nhs_immunisations_api_primary_source: "true" } }

        its(:nhs_immunisations_api_primary_source) { should be true }
      end

      context "coerces false attributes from string" do
        let(:updates) { { nhs_immunisations_api_primary_source: "false" } }

        its(:nhs_immunisations_api_primary_source) { should be false }
      end
    end

    describe "rejects invalid attributes" do
      subject(:call) do
        described_class.call(vaccination_record: vaccination_record, updates:)
      end

      context "for invalid attribute key (not in allowed list)" do
        let(:updates) { { patient_id: 123 } }

        it "raises RuntimeError" do
          expect { call }.to raise_error(
            RuntimeError,
            /Attribute 'patient_id' is not editable/
          )
        end
      end

      context "for invalid integer coercion" do
        let(:updates) { { session_id: "abc" } }

        it "raises ArgumentError" do
          expect { call }.to raise_error(ArgumentError)
        end
      end

      context "for invalid boolean coercion" do
        let(:updates) { { nhs_immunisations_api_primary_source: "maybe" } }

        it "raises ArgumentError" do
          expect { call }.to raise_error(ArgumentError, /invalid boolean/)
        end
      end

      context "raises ArgumentError for invalid datetime coercion" do
        let(:updates) { { confirmation_sent_at: [] } }

        it "raises ArgumentError" do
          expect { call }.to raise_error(ArgumentError, /invalid datetime/)
        end
      end

      context "raises when updates is not a Hash" do
        let(:updates) { ["uuid=123"] }

        it "raises RuntimeError" do
          expect { call }.to raise_error(RuntimeError, /updates must be a Hash/)
        end
      end
    end
  end
end
