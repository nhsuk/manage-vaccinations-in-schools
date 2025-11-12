# frozen_string_literal: true

module BelongsToSessionDate
  extend ActiveSupport::Concern

  included do
    belongs_to :session_date
    belongs_to :location

    has_one :session, through: :session_date

    scope :today, -> { joins(:session_date).merge(SessionDate.today) }

    scope :where_session,
          ->(session) { joins(:session_date).where(session_date: { session: }) }

    delegate :academic_year, to: :session
    delegate :today?, to: :session_date
  end
end
