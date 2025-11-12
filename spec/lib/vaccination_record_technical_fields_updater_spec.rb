# frozen_string_literal: true

describe VaccinationRecordTechnicalFieldsUpdater do
  let(:updated_at) { Time.zone.local(2025, 1, 1) }
  let(:vaccination_record) { create(:vaccination_record, updated_at:) }

  describe "#call" do
    describe "updating allowed attributes" do
      subject(:reloaded_vaccination_record) do
        described_class.call(vaccination_record: vaccination_record, updates:)
        vaccination_record.reload
      end

      shared_examples "doesn't change the updated_at time" do
        its(:updated_at) { should eq updated_at }
      end

      context "updates allowed string attributes (uuid)" do
        let(:new_uuid) { SecureRandom.uuid }

        let(:updates) { { uuid: new_uuid } }

        its(:uuid) { should eq new_uuid }

        include_examples "doesn't change the updated_at time"
      end

      context "coerces integer attributes from string (source)" do
        let(:updates) { { source: "1" } }

        its(:source_before_type_cast) { should eq 1 }

        include_examples "doesn't change the updated_at time"
      end

      context "coerces datetime attributes from string (confirmation_sent_at)" do
        let(:time_str) { "2024-05-17T10:30:00Z" }

        let(:updates) { { confirmation_sent_at: time_str } }

        its(:confirmation_sent_at) do
          should be_within(1.second).of(Time.zone.parse(time_str))
        end

        include_examples "doesn't change the updated_at time"
      end

      context "sets attributes to nil when given 'nil' string" do
        before do
          vaccination_record.update_columns(
            nhs_immunisations_api_etag: "etag-123"
          )
        end

        let(:updates) { { nhs_immunisations_api_etag: "nil" } }

        its(:nhs_immunisations_api_etag) { should be_nil }

        include_examples "doesn't change the updated_at time"
      end

      context "coerces true attributes from string" do
        let(:updates) do
          {
            nhs_immunisations_api_primary_source: "true",
            nhs_immunisations_api_id: SecureRandom.uuid
          }
        end

        its(:nhs_immunisations_api_primary_source) { should be true }

        include_examples "doesn't change the updated_at time"
      end

      context "coerces false attributes from string" do
        let(:updates) { { nhs_immunisations_api_primary_source: "false" } }

        its(:nhs_immunisations_api_primary_source) { should be false }

        include_examples "doesn't change the updated_at time"
      end

      context "actively updates updated_at timestamp" do
        let(:updates) { { updated_at: Time.zone.local(2025, 2, 1) } }

        its(:updated_at) { should eq Time.zone.local(2025, 2, 1) }
      end
    end

    describe "rejects invalid records" do
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

      context "tries to save an invalid record" do
        let(:updates) { { nhs_immunisations_api_id: SecureRandom.uuid } }

        it "raises ActiveRecord::RecordInvalid" do
          expect { call }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
end
