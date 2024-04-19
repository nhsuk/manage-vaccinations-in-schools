module PatientTabsConcern
  extend ActiveSupport::Concern

  def group_patient_sessions_by_conditions(all_patient_sessions, tab_conditions)
    all_patient_sessions
      .group_by do |patient_session| # rubocop:disable Style/BlockDelimiters
        tab_conditions
          .find { |_, conditions| conditions.any? { patient_session.send(_1) } }
          &.first
      end
      .tap { |groups| tab_conditions.each_key { groups[_1] ||= [] } }
  end

  def group_patient_sessions_by_state(all_patient_sessions, tab_states)
    all_patient_sessions
      .group_by do |patient_session| # rubocop:disable Style/BlockDelimiters
        tab_states.find { |_, states| patient_session.state.in? states }&.first
      end
      .tap { |groups| tab_states.each_key { groups[_1] ||= [] } }
  end

  def count_patient_sessions(tab_patient_sessions)
    tab_patient_sessions.transform_values(&:count)
  end
end
