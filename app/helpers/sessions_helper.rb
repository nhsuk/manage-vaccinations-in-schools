# frozen_string_literal: true

module SessionsHelper
  def session_location(session, part_of_sentence: false)
    if (location = session.location).present?
      location.name
    else
      part_of_sentence ? "unknown location" : "Unknown location"
    end
  end
end
