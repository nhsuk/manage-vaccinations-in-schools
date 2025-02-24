# frozen_string_literal: true

class SchoolMoveForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :current_user, :school_move

  attribute :action, :string

  validates :action, inclusion: { in: %w[confirm ignore] }

  def save
    return false unless valid?

    case action
    when "confirm"
      @school_move.confirm!(user: current_user)
    when "ignore"
      @school_move.ignore!
    end

    true
  end
end
