# frozen_string_literal: true

class BatchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :batch

  attribute :number, :string
  attribute :expiry, :date

  validates :number, batch_number: true

  validates :expiry,
            comparison: {
              greater_than: -> { Date.current },
              less_than: -> { Date.current + 15.years }
            }

  def save
    valid? && batch.update(number: number, expiry: expiry)
  end
end
