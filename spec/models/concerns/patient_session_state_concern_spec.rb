# frozen_string_literal: true

require "rails_helper"

describe PatientSessionStateConcern do
  subject(:fsm) { fake_state_machine_class.new }

  let(:fake_state_machine_class) do
    Class.new do
      attr_accessor :state

      include PatientSessionStateConcern
    end
  end

  describe "#state" do
    subject { fsm.state }

    RSpec.shared_examples "it supports the state" do |state:, conditions:|
      conditions_list = conditions.to_sentence

      conditions_hash =
        conditions.map { |condition| [:"#{condition}?", true] }.to_h

      messages = {
        consent_given?: false,
        consent_refused?: false,
        consent_conflicts?: false,
        no_consent?: false,
        not_gillick_competent?: false,
        triage_needed?: false,
        triage_not_needed?: false,
        triage_ready_to_vaccinate?: false,
        triage_do_not_vaccinate?: false,
        triage_keep_in_triage?: false,
        triage_delay_vaccination?: false,
        vaccination_administered?: false,
        vaccination_not_administered?: false,
        vaccination_can_be_delayed?: false
      }.merge(conditions_hash)

      context "with conditions #{conditions_list}" do
        before { allow(fsm).to receive_messages(**messages) }

        it { should eq state.to_s }
      end
    end

    it_behaves_like "it supports the state",
                    state: :added_to_session,
                    conditions: []

    it_behaves_like "it supports the state",
                    state: :consent_given_triage_needed,
                    conditions: %i[consent_given triage_needed]

    it_behaves_like "it supports the state",
                    state: :consent_given_triage_not_needed,
                    conditions: %i[consent_given triage_not_needed]

    it_behaves_like "it supports the state",
                    state: :consent_refused,
                    conditions: [:consent_refused]

    it_behaves_like "it supports the state",
                    state: :consent_conflicts,
                    conditions: [:consent_conflicts]

    it_behaves_like "it supports the state",
                    state: :unable_to_vaccinate_not_gillick_competent,
                    conditions: [:not_gillick_competent]

    it_behaves_like "it supports the state",
                    state: :triaged_ready_to_vaccinate,
                    conditions: [:triage_ready_to_vaccinate]

    it_behaves_like "it supports the state",
                    state: :triaged_do_not_vaccinate,
                    conditions: [:triage_do_not_vaccinate]

    it_behaves_like "it supports the state",
                    state: :triaged_kept_in_triage,
                    conditions: [:triage_keep_in_triage]

    it_behaves_like "it supports the state",
                    state: :delay_vaccination,
                    conditions: [:triage_delay_vaccination]

    it_behaves_like "it supports the state",
                    state: :vaccinated,
                    conditions: [:vaccination_administered]

    it_behaves_like "it supports the state",
                    state: :unable_to_vaccinate,
                    conditions: [:vaccination_not_administered]

    it_behaves_like "it supports the state",
                    state: :delay_vaccination,
                    conditions: [:vaccination_can_be_delayed]
  end
end
