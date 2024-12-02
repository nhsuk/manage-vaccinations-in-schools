# frozen_string_literal: true

class SchoolMoveForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :school_move

  attribute :action, :string
  attribute :move_to_school, :boolean

  validates :action, inclusion: { in: %w[confirm ignore] }
  validates :move_to_school,
            inclusion: {
              in: [true, false]
            },
            if: :show_move_to_school?

  def save
    return false unless valid?

    case action
    when "confirm"
      @school_move.confirm!(move_to_school:)
    when "ignore"
      @school_move.ignore!
    end

    true
  end

  def show_move_to_school?
    school_move.from_clinic? && school_move.school_session.present?
  end
end
