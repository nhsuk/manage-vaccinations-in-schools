# frozen_string_literal: true

class SchoolMoveForm
  include ActiveModel::Model

  attr_accessor :school_move, :action

  validates :action, inclusion: { in: %w[confirm ignore] }

  def save
    return false unless valid?

    case action
    when "confirm"
      @school_move.confirm!
    when "ignore"
      @school_move.ignore!
    end

    true
  end
end
