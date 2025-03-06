# frozen_string_literal: true

describe PatientSessionStatusConcern do
  subject(:fake_instance) { fake_class.new }

  let(:fake_class) do
    Class.new do
      attr_accessor :status

      include PatientSessionStatusConcern
    end
  end

  describe "#status" do
    subject { fake_instance.status(programme:) }

    let(:programme) { create(:programme) }

    shared_examples "it supports the status" do |status, conditions:|
      conditions_list = conditions.to_sentence

      conditions_hash =
        conditions.map { |condition| [:"#{condition}?", true] }.to_h

      messages = {
        consent_given?: false,
        consent_refused?: false,
        consent_conflicts?: false,
        no_consent?: false,
        triage_needed?: false,
        triage_not_needed?: false,
        triage_ready_to_vaccinate?: false,
        triage_do_not_vaccinate?: false,
        triage_delay_vaccination?: false,
        vaccination_administered?: false,
        vaccination_not_administered?: false,
        vaccination_can_be_delayed?: false
      }.merge(conditions_hash)

      context "with conditions #{conditions_list}" do
        # rubocop:disable RSpec/SubjectStub
        before { allow(fake_instance).to receive_messages(**messages) }
        # rubocop:enable RSpec/SubjectStub

        it { should eq(status.to_s) }
      end
    end

    include_examples "it supports the status", :added_to_session, conditions: []

    include_examples "it supports the status",
                     :consent_given_triage_needed,
                     conditions: %i[consent_given triage_needed]

    include_examples "it supports the status",
                     :consent_given_triage_not_needed,
                     conditions: %i[consent_given triage_not_needed]

    include_examples "it supports the status",
                     :consent_refused,
                     conditions: [:consent_refused]

    include_examples "it supports the status",
                     :consent_conflicts,
                     conditions: [:consent_conflicts]

    include_examples "it supports the status",
                     :triaged_ready_to_vaccinate,
                     conditions: %i[consent_given triage_ready_to_vaccinate]

    include_examples "it supports the status",
                     :triaged_do_not_vaccinate,
                     conditions: [:triage_do_not_vaccinate]

    include_examples "it supports the status",
                     :delay_vaccination,
                     conditions: [:triage_delay_vaccination]

    include_examples "it supports the status",
                     :vaccinated,
                     conditions: [:vaccination_administered]

    include_examples "it supports the status",
                     :unable_to_vaccinate,
                     conditions: [:vaccination_not_administered]

    include_examples "it supports the status",
                     :delay_vaccination,
                     conditions: [:vaccination_can_be_delayed]
  end
end
