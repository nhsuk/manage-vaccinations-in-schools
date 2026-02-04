# frozen_string_literal: true

class BatchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :batch

  attribute :name, :string
  attribute :expiry, :date

  validates :name, batch_name: true

  validates :expiry,
            comparison: {
              greater_than: -> { Date.current },
              less_than: -> { Date.current + 15.years }
            }

  def save
    valid? && batch.update(name: name, number: name, expiry: expiry)
  end
end
