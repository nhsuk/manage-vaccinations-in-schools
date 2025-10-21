# frozen_string_literal: true

class Generate::Triages
  def initialize(
    team:,
    programme: nil,
    session: nil,
    safe_to_vaccinate: 1,
    do_not_vaccinate: 1
  )
    @team = team
    @programme = programme || team.programmes.sample
    @session = session
    @safe_to_vaccinate = safe_to_vaccinate
    @do_not_vaccinate = do_not_vaccinate
  end

  def call
    create_triage_with_status(:safe_to_vaccinate, @safe_to_vaccinate)
    create_triage_with_status(:do_not_vaccinate, @do_not_vaccinate)
  end

  def self.call(...) = new(...).call

  private

  attr_reader :team, :programme

  def academic_year = Date.current.academic_year

  def patients
    (@session.presence || team)
      .patients
      .includes(:triage_statuses)
      .appear_in_programmes([programme], academic_year:)
      .select { it.triage_status(programme:, academic_year:).required? }
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
    @user ||= team.users.includes(:teams).sample
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
        team:
      )
    end
  end
end
