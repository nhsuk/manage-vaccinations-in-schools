# frozen_string_literal: true

class SchoolPolicy < LocationPolicy
  def import? = true

  def patients? = true

  def sessions? = true
end
