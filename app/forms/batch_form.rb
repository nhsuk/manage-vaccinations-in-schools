# frozen_string_literal: true

class BatchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :batch

  attribute :name, :string
  attribute :expiry, :date

  validates :name,
            presence: true,
            format: {
              with: /\A[A-Za-z0-9]+\z/
            },
            length: {
              minimum: 2,
              maximum: 100
            }

  validates :expiry,
            comparison: {
              greater_than: -> { Date.current },
              less_than: -> { Date.current + 15.years }
            }

  def save
    valid? && batch.update(name: name, expiry: expiry)
  end
end
