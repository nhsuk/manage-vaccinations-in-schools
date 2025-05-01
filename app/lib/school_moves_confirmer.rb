# frozen_string_literal: true

class SchoolMovesConfirmer
  def initialize(school_moves, user: nil)
    @school_moves = school_moves
    @user = user
  end

  def call
    ActiveRecord::Base.transaction do
      school_moves.each do |school_move|
        school_move.update_patient!
        school_move.update_sessions!
        school_move.create_log_entry!(user:)
        if school_move.persisted?
          SchoolMove.where(patient: school_move.patient).destroy_all
        end
      end
    end
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :school_moves, :user
end
