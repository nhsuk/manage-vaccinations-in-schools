# frozen_string_literal: true

module Programmable
  extend ActiveSupport::Concern

  def programme
    if programme_type
      options = {}
      options[:disease_types] = disease_types if respond_to?(:disease_types)
      options[:patient] = patient if respond_to?(:patient)
      Programme.find(programme_type, **options)
    end
  end

  def programme=(value)
    self.programme_type = value&.type
    self.disease_types = value&.disease_types if respond_to?(:disease_types=)
  end
end
