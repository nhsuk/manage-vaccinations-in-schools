# frozen_string_literal: true

module SessionsHelper
  def pluralize_child(count)
    count.zero? ? "No children" : pluralize(count, "child")
  end

  def session_location(session, part_of_sentence: false)
    if (location = session.location).present?
      location.name
    else
      part_of_sentence ? "unknown location" : "Unknown location"
    end
  end

  def session_name(session)
    "#{session.programme.name} session at #{session_location(session, part_of_sentence: true)}"
  end
end
