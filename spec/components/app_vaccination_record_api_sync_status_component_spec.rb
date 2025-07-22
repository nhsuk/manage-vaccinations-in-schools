# frozen_string_literal: true

describe AppVaccinationRecordAPISyncStatusComponent do
  let(:vaccination_record) do
    build(:vaccination_record, outcome:, programme:, session:)
  end
  let(:outcome) { "administered" }
  let(:programme) { create(:programme, type: "flu") }
  let(:session) { create(:session, programmes: [programme]) }

  let(:component) { described_class.new(vaccination_record) }
  let(:rendered_component) { render_inline(component) }

  describe "#call" do
    subject(:formatted_status) { rendered_component.to_html }

    context "when sync_status is :not_synced" do
      context "when vaccination was not administered" do
        before do
          allow(vaccination_record).to receive_messages(
            sync_status: :not_synced,
            administered?: false
          )
        end

        it do
          expect(formatted_status).to include(
            "Records are not synced if the vaccination was not given"
          )
        end
      end

      context "when vaccination was not recorded in service" do
        before do
          allow(vaccination_record).to receive(:sync_status).and_return(
            :not_synced
          )
        end

        let(:session) { nil }

        it do
          expect(formatted_status).to include(
            "Records are not synced if the vaccination was not recorded in Mavis"
          )
        end
      end

      context "when vaccination programme is not currently sent to the API" do
        before do
          allow(vaccination_record).to receive(:sync_status).and_return(
            :not_synced
          )
        end

        let(:programme) { create(:programme, type: "menacwy") }

        it do
          expect(formatted_status).to include(
            "Records are currently not synced for this programme"
          )
        end
      end
    end

    context "when sync_status is :cannot_sync" do
      before do
        allow(vaccination_record).to receive(:sync_status).and_return(
          :cannot_sync
        )
      end

      it do
        expect(formatted_status).to include(
          "You must add an NHS number to the child's record before this record will sync"
        )
      end
    end

    context "when sync_status is :failed" do
      before do
        allow(vaccination_record).to receive(:sync_status).and_return(:failed)
      end

      it do
        expect(formatted_status).to include(
          "The Mavis team is aware of the issue and is working to resolve it"
        )
      end
    end

    context "when sync_status is :synced" do
      before do
        allow(vaccination_record).to receive(:sync_status).and_return(:synced)
      end

      it { should include("Last synced:") }
    end

    context "when sync_status is :pending" do
      before do
        allow(vaccination_record).to receive(:sync_status).and_return(:pending)
      end

      it { should include("Last synced:") }
    end
  end
end
