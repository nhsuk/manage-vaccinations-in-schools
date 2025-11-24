# frozen_string_literal: true

module Importable
  extend ActiveSupport::Concern

  def show_approved_reviewers?
    raise NotImplementedError,
          "#{self.class.name} must implement #show_approved_reviewers?"
  end

  def show_cancelled_reviewer?
    raise NotImplementedError,
          "#{self.class.name} must implement #show_cancelled_reviewer?"
  end

  def records_count
    raise NotImplementedError,
          "#{self.class.name} must implement #records_count"
  end

  def type_label
    raise NotImplementedError, "#{self.class.name} must implement #type_label"
  end
end
