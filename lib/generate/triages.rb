# frozen_string_literal: true

module Generate
  class Triages
    attr_reader :config, :organisation, :programme

    def initialize(
      organisation:,
      programme: nil,
      session: nil,
      ready_to_vaccinate: 1,
      do_not_vaccinate: 1
    )
      @organisation = organisation
      @programme = programme || organisation.programmes.sample
      @session = session
      @ready_to_vaccinate = ready_to_vaccinate
      @do_not_vaccinate = do_not_vaccinate
    end

    def call
      create_triage_with_status(:ready_to_vaccinate, @ready_to_vaccinate)
      create_triage_with_status(:do_not_vaccinate, @do_not_vaccinate)
    end

    def self.call(...) = new(...).call

    private

    def patients
      (@session.presence || organisation)
        .patients
        .includes(:triage_statuses)
        .in_programmes([programme], academic_year: AcademicYear.current)
        .select { it.triage_status(programme:).required? }
    end

    def random_patients(count)
      patients
        .shuffle
        .take(count)
        .tap do
          raise "Not enough patients to generate triages" if it.size < count
        end
    end

    def user
      @user ||= organisation.users.includes(:organisations).sample
    end

    def create_triage_with_status(status, count)
      available_patients = random_patients(count)

      available_patients.each do |patient|
        FactoryBot.create(
          :triage,
          status,
          patient:,
          programme:,
          performed_by: user,
          organisation:
        )
      end
    end
  end
end
