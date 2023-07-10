require "rails_helper"

RSpec.describe PatientSessionStateMachineConcern do
  let(:fake_state_machine_class) do
    Class.new do
      attr_accessor :state

      include PatientSessionStateMachineConcern

      def consent_response
      end

      def triage
      end

      def vaccination_record
      end
    end
  end

  subject(:fsm) { fake_state_machine_class.new }

  before do
    fsm.aasm_write_state_without_persistence(state) if state
    allow(fsm).to receive(:consent_response).and_return(consent_response)
    allow(fsm).to receive(:triage).and_return(triage)
    allow(fsm).to receive(:vaccination_record).and_return(vaccination_record)
  end

  let(:consent_response) { double("ConsentResponse") }
  let(:triage) { double("Triage") }
  let(:vaccination_record) { double("VaccinationRecord") }

  let(:state) { nil }

  it "starts in the awaiting_consent state" do
    expect(fsm).to be_awaiting_consent_response
  end

  context "in awaiting_consent_response state" do
    let(:state) { :awaiting_consent_response }

    describe "#received_consent_response" do
      it "transitions to awaiting_triage when consent is refused" do
        allow(consent_response).to receive(:consent_given?).and_return(false)
        allow(consent_response).to receive(:consent_refused?).and_return(true)
        allow(consent_response).to receive(:triage_needed?).and_return(false)

        fsm.received_consent_response
        expect(fsm).to be_awaiting_triage
      end

      it "transitions to ready_to_vaccinate when consent is given and needs no triage" do
        allow(consent_response).to receive(:consent_given?).and_return(true)
        allow(consent_response).to receive(:consent_refused?).and_return(false)
        allow(consent_response).to receive(:triage_needed?).and_return(false)

        fsm.received_consent_response
        expect(fsm).to be_ready_to_vaccinate
      end

      it "transitions to awaiting_triage when consent is given and needs triage" do
        allow(consent_response).to receive(:consent_given?).and_return(true)
        allow(consent_response).to receive(:consent_refused?).and_return(false)
        allow(consent_response).to receive(:triage_needed?).and_return(true)

        fsm.received_consent_response
        expect(fsm).to be_awaiting_triage
      end
    end
  end

  context "in awaiting_triage state" do
    let(:state) { :awaiting_triage }

    describe "#triaged" do
      it "transitions to ready_to_vaccinate when triage is ready to vaccinate" do
        allow(triage).to receive(:ready_to_vaccinate?).and_return(true)
        allow(triage).to receive(:do_not_vaccinate?).and_return(false)
        allow(triage).to receive(:needs_follow_up?).and_return(false)

        fsm.triaged
        expect(fsm).to be_ready_to_vaccinate
      end

      it "transitions to not_vaccinated when triage is do_not_vaccinate" do
        allow(triage).to receive(:ready_to_vaccinate?).and_return(false)
        allow(triage).to receive(:do_not_vaccinate?).and_return(true)
        allow(triage).to receive(:needs_follow_up?).and_return(false)

        fsm.triaged
        expect(fsm).to be_not_vaccinated
      end
    end
  end

  context "in ready_to_vaccinate state" do
    let(:state) { :ready_to_vaccinate }

    describe "#vaccine_administered" do
      it "transitions to vaccinated when vaccination_record is administered" do
        allow(vaccination_record).to receive(:administered?).and_return(true)
        allow(vaccination_record).to receive(:administered).and_return(true)

        fsm.vaccinate
        expect(fsm).to be_vaccinated
      end
    end

    describe "#did_not_vaccinate" do
      it "transitions to not_vaccinated when vaccination_record is not administered" do
        allow(vaccination_record).to receive(:administered?).and_return(false)
        allow(vaccination_record).to receive(:administered).and_return(false)

        fsm.did_not_vaccinate
        expect(fsm).to be_not_vaccinated
      end
    end
  end
end
