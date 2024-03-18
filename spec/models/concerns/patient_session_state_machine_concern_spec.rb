require "rails_helper"

RSpec.describe PatientSessionStateMachineConcern do
  let(:fake_state_machine_class) do
    Class.new do
      attr_accessor :state

      include PatientSessionStateMachineConcern

      def latest_consents
      end

      def consents
      end

      def triage
      end

      def vaccination_record
      end

      def gillick_competent?
      end
    end
  end

  subject(:fsm) { fake_state_machine_class.new }

  before do
    fsm.aasm_write_state_without_persistence(state) if state
    allow(fsm).to receive(:latest_consents).and_return(consents)
    allow(fsm).to receive_message_chain(:consents, :recorded).and_return(
      consents
    )
    allow(fsm).to receive(:triage).and_return([triage])
    allow(fsm).to receive(:vaccination_record).and_return(vaccination_record)
  end

  let(:consent) { double("Consent") }
  let(:other_consent) { double("Consent") }
  let(:consents) { [consent] }
  let(:triage) { double("Triage") }
  let(:vaccination_record) { double("VaccinationRecord") }

  let(:state) { nil }

  it "starts in the added_to_session state" do
    expect(fsm).to be_added_to_session
  end

  context "in added_to_session state" do
    let(:state) { :added_to_session }

    before do
      allow(consent).to receive(:response_given?).and_return(false)
      allow(consent).to receive(:response_refused?).and_return(false)
      allow(consent).to receive(:response_not_provided?).and_return(false)
      allow(consent).to receive(:triage_needed?).and_return(false)

      allow(other_consent).to receive(:response_given?).and_return(false)
      allow(other_consent).to receive(:response_refused?).and_return(false)
      allow(other_consent).to receive(:response_not_provided?).and_return(false)
      allow(other_consent).to receive(:triage_needed?).and_return(false)
    end

    describe "#do_consent" do
      let(:consents) { [consent, other_consent] }

      it "transitions to consent_given_triage_not_needed when consent is given and needs no triage" do
        allow(consent).to receive(:response_given?).and_return(true)
        allow(other_consent).to receive(:response_given?).and_return(true)

        fsm.do_consent
        expect(fsm).to be_consent_given_triage_not_needed
      end

      it "transitions to consent_given_triage_needed consent is given and needs triage" do
        allow(consent).to receive(:response_given?).and_return(true)
        allow(consent).to receive(:triage_needed?).and_return(true)
        allow(other_consent).to receive(:response_given?).and_return(true)
        allow(other_consent).to receive(:response_given?).and_return(true)

        fsm.do_consent
        expect(fsm).to be_consent_given_triage_needed
      end

      it "transitions to consent_refused when consent is refused" do
        allow(consent).to receive(:response_refused?).and_return(true)
        allow(other_consent).to receive(:response_refused?).and_return(true)

        fsm.do_consent
        expect(fsm).to be_consent_refused
      end

      it "transitions to consent_conflicts when consent is given and refused" do
        allow(consent).to receive(:response_given?).and_return(true)
        allow(other_consent).to receive(:response_refused?).and_return(true)

        fsm.do_consent
        expect(fsm).to be_consent_conflicts
      end
    end

    describe "#do_gillick_assessment" do
      it "transitions to unable_to_vaccinate_not_gillick_competent when patient is not gillick competent" do
        allow(fsm).to receive(:gillick_competent?).and_return(false)

        fsm.do_gillick_assessment
        expect(fsm).to be_unable_to_vaccinate_not_gillick_competent
      end
    end

    describe "#do_vaccination" do
      it "transitions to unable_to_vaccinate_not_assessed when consent is nil" do
        allow(fsm).to receive_message_chain(:consents, :recorded).and_return([])

        fsm.do_vaccination
        expect(fsm).to be_unable_to_vaccinate_not_assessed
      end
    end
  end

  context "in consent_given_triage_not_needed state" do
    let(:state) { :consent_given_triage_not_needed }

    before do
      allow(triage).to receive(:ready_to_vaccinate?).and_return(false)
      allow(triage).to receive(:do_not_vaccinate?).and_return(false)
      allow(triage).to receive(:needs_follow_up?).and_return(false)
      allow(triage).to receive(:delay_vaccination?).and_return(false)
    end

    describe "#do_triage" do
      it "transitions to triaged_ready_to_vaccinate when triage is ready to vaccinate" do
        allow(triage).to receive(:ready_to_vaccinate?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_ready_to_vaccinate
      end

      it "transitions to triaged_do_not_vaccinate when triage is do_not_vaccinate" do
        allow(triage).to receive(:do_not_vaccinate?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_do_not_vaccinate
      end

      it "transitions to triaged_kept_in_triage when triage is needs_follow_up" do
        allow(triage).to receive(:needs_follow_up?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_kept_in_triage
      end

      it "transitions to delay_vaccination when triage is delay_vaccination" do
        allow(triage).to receive(:delay_vaccination?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_delay_vaccination
      end
    end

    describe "#do_vaccination" do
      it "transitions to vaccinated when vaccination_record is administered" do
        allow(vaccination_record).to receive(:administered?).and_return(true)
        allow(vaccination_record).to receive(:administered).and_return(true)

        fsm.do_vaccination
        expect(fsm).to be_vaccinated
      end

      it "transitions to unable_to_vaccinate when vaccination_record is not administered" do
        allow(vaccination_record).to receive(:administered?).and_return(false)
        allow(vaccination_record).to receive(:administered).and_return(false)

        fsm.do_vaccination
        expect(fsm).to be_unable_to_vaccinate
      end
    end

    describe "#next_step" do
      subject { fsm.next_step }

      it { should eq(:vaccinate) }
    end
  end

  context "in consent_given_triage_needed state" do
    let(:state) { :consent_given_triage_needed }

    before do
      allow(triage).to receive(:ready_to_vaccinate?).and_return(false)
      allow(triage).to receive(:do_not_vaccinate?).and_return(false)
      allow(triage).to receive(:needs_follow_up?).and_return(false)
      allow(triage).to receive(:delay_vaccination?).and_return(false)
    end

    describe "#do_triage" do
      it "transitions to triaged_ready_to_vaccinate when triage is ready to vaccinate" do
        allow(triage).to receive(:ready_to_vaccinate?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_ready_to_vaccinate
      end

      it "transitions to triaged_do_not_vaccinate when triage is do_not_vaccinate" do
        allow(triage).to receive(:do_not_vaccinate?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_do_not_vaccinate
      end

      it "transitions to triaged_kept_in_triage when triage is needs_follow_up" do
        allow(triage).to receive(:needs_follow_up?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_kept_in_triage
      end

      it "transitions to delay_vaccination when triage is delay_vaccination" do
        allow(triage).to receive(:delay_vaccination?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_delay_vaccination
      end
    end

    describe "#next_step" do
      subject { fsm.next_step }

      it { should eq(:triage) }
    end
  end

  context "in triaged_do_not_vaccinate state" do
    let(:state) { :triaged_do_not_vaccinate }

    before do
      allow(triage).to receive(:ready_to_vaccinate?).and_return(false)
      allow(triage).to receive(:do_not_vaccinate?).and_return(false)
      allow(triage).to receive(:needs_follow_up?).and_return(false)
      allow(triage).to receive(:delay_vaccination?).and_return(false)
    end

    describe "#do_triage" do
      it "transitions to triaged_ready_to_vaccinate when triage is ready to vaccinate" do
        allow(triage).to receive(:ready_to_vaccinate?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_ready_to_vaccinate
      end

      it "stays in triaged_do_not_vaccinate when triage is do_not_vaccinate" do
        allow(triage).to receive(:do_not_vaccinate?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_do_not_vaccinate
      end

      it "transitions to triaged_kept_in_triage when triage is needs_follow_up" do
        allow(triage).to receive(:needs_follow_up?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_kept_in_triage
      end

      it "transitions to delay_vaccination when triage is delay_vaccination" do
        allow(triage).to receive(:delay_vaccination?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_delay_vaccination
      end
    end
  end

  context "in triaged_kept_in_triage state" do
    let(:state) { :triaged_kept_in_triage }

    before do
      allow(triage).to receive(:ready_to_vaccinate?).and_return(false)
      allow(triage).to receive(:do_not_vaccinate?).and_return(false)
      allow(triage).to receive(:needs_follow_up?).and_return(false)
      allow(triage).to receive(:delay_vaccination?).and_return(false)
    end

    describe "#do_triage" do
      it "transitions to triaged_ready_to_vaccinate when triage is ready to vaccinate" do
        allow(triage).to receive(:ready_to_vaccinate?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_ready_to_vaccinate
      end

      it "transitions to triaged_do_not_vaccinate when triage is do_not_vaccinate" do
        allow(triage).to receive(:do_not_vaccinate?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_do_not_vaccinate
      end

      it "stays in triaged_kept_in_triage when triage is needs_follow_up" do
        allow(triage).to receive(:needs_follow_up?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_kept_in_triage
      end

      it "transitions to delay_vaccination when triage is delay_vaccination" do
        allow(triage).to receive(:delay_vaccination?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_delay_vaccination
      end
    end

    describe "#next_step" do
      subject { fsm.next_step }

      it { should eq(:triage) }
    end
  end

  context "in triaged_ready_to_vaccinate state" do
    let(:state) { :triaged_ready_to_vaccinate }

    before do
      allow(triage).to receive(:ready_to_vaccinate?).and_return(false)
      allow(triage).to receive(:do_not_vaccinate?).and_return(false)
      allow(triage).to receive(:needs_follow_up?).and_return(false)
      allow(triage).to receive(:delay_vaccination?).and_return(false)
    end

    describe "#do_triage" do
      it "transitions to triaged_ready_to_vaccinate when triage is ready to vaccinate" do
        allow(triage).to receive(:ready_to_vaccinate?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_ready_to_vaccinate
      end

      it "transitions to triaged_do_not_vaccinate when triage is do_not_vaccinate" do
        allow(triage).to receive(:do_not_vaccinate?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_do_not_vaccinate
      end

      it "transitions to triaged_kept_in_triage when triage is needs_follow_up" do
        allow(triage).to receive(:needs_follow_up?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_triaged_kept_in_triage
      end

      it "transitions to delay_vaccination when triage is delay_vaccination" do
        allow(triage).to receive(:delay_vaccination?).and_return(true)

        fsm.do_triage
        expect(fsm).to be_delay_vaccination
      end
    end

    describe "#do_vaccination" do
      it "transitions to vaccinated when vaccination_record is administered" do
        allow(vaccination_record).to receive(:administered?).and_return(true)
        allow(vaccination_record).to receive(:administered).and_return(true)

        fsm.do_vaccination
        expect(fsm).to be_vaccinated
      end

      it "transitions to unable_to_vaccinate when vaccination_record is not administered" do
        allow(vaccination_record).to receive(:administered?).and_return(false)
        allow(vaccination_record).to receive(:administered).and_return(false)

        fsm.do_vaccination
        expect(fsm).to be_unable_to_vaccinate
      end
    end

    describe "#next_step" do
      subject { fsm.next_step }

      it { should eq(:vaccinate) }
    end
  end

  describe "when consent is given, no triage needed and the vaccination is administered" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      patient_session = patient.patient_sessions.find_by(session:)

      # no consent yet
      expect(patient_session).to be_added_to_session

      # consent given
      create(
        :consent_given,
        patient:,
        parent_relationship: :mother,
        campaign: session.campaign
      )
      patient_session.do_consent
      expect(patient_session).to be_consent_given_triage_not_needed

      # vaccination administered
      create(
        :vaccination_record,
        patient_session:,
        administered: true,
        delivery_site: :right_arm
      )
      patient_session.do_vaccination
      expect(patient_session).to be_vaccinated
    end
  end

  describe "when consent is refused" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      patient_session = patient.patient_sessions.find_by(session:)

      # consent refused
      create(
        :consent_refused,
        patient:,
        parent_relationship: :mother,
        campaign: session.campaign
      )
      patient_session.do_consent
      expect(patient_session).to be_consent_refused
    end
  end

  describe "when consent given by other, no triage needed, the vaccination is administered" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      patient_session = patient.patient_sessions.find_by(session:)

      # consent given
      create(
        :consent_given,
        patient:,
        parent_relationship: :other,
        campaign: session.campaign
      )
      patient_session.do_consent
      expect(patient_session).to be_consent_given_triage_not_needed

      # vaccination administered
      create(
        :vaccination_record,
        patient_session:,
        administered: true,
        delivery_site: :left_arm
      )
      patient_session.do_vaccination
      expect(patient_session).to be_vaccinated
    end
  end

  describe "when consent given but patient triaged out" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      patient_session = patient.patient_sessions.find_by(session:)

      # consent given
      create(
        :consent_given,
        patient:,
        parent_relationship: :other,
        campaign: session.campaign
      )
      patient_session.do_consent
      expect(patient_session).to be_consent_given_triage_not_needed

      # triage decides not to vaccinate
      create(:triage, patient_session:, status: :do_not_vaccinate)
      patient_session.do_triage
      expect(patient_session).to be_triaged_do_not_vaccinate
    end
  end

  describe "when consent given, but vaccination is not administered" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      patient_session = patient.patient_sessions.find_by(session:)

      # consent given
      create(
        :consent_given,
        patient:,
        parent_relationship: :mother,
        campaign: session.campaign
      )
      patient_session.do_consent
      expect(patient_session).to be_consent_given_triage_not_needed

      # vaccination not administered
      create(:vaccination_record, patient_session:, administered: false)
      patient_session.do_vaccination
      expect(patient_session).to be_unable_to_vaccinate
    end
  end

  describe "when consent given and triage not needed, but triage done anyway and decided not to vaccinate" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      patient_session = patient.patient_sessions.find_by(session:)

      # consent given
      create(
        :consent_given,
        patient:,
        parent_relationship: :mother,
        campaign: session.campaign
      )
      patient_session.do_consent
      expect(patient_session).to be_consent_given_triage_not_needed

      # triage decides not to vaccinate
      create(:triage, patient_session:, status: :do_not_vaccinate)
      patient_session.do_triage
      expect(patient_session).to be_triaged_do_not_vaccinate
    end
  end

  describe "changing triage status" do
    it "steps through the right actions and outcomes" do
      session = create(:session, patients_in_session: 1)
      patient = session.patients.first
      patient_session = patient.patient_sessions.find_by(session:)

      # consent given
      create(
        :consent_given,
        patient:,
        parent_relationship: :mother,
        campaign: session.campaign
      )
      patient_session.do_consent
      expect(patient_session).to be_consent_given_triage_not_needed

      # triage decides to vaccinate
      create(:triage, patient_session:, status: :ready_to_vaccinate)
      patient_session.do_triage
      expect(patient_session).to be_triaged_ready_to_vaccinate

      # triage decides not to vaccinate
      create(:triage, patient_session:, status: :do_not_vaccinate)
      patient_session.do_triage
      expect(patient_session).to be_triaged_do_not_vaccinate
    end
  end
end
