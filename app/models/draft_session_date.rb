# frozen_string_literal: true

class DraftSessionDate
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attribute :index, :integer
  attribute :value, :date

  validates :value, presence: true

  def attributes
    { "index" => index, "value" => value&.iso8601 }
  end

  def persisted? = index != nil

  def new_record? = index.nil?

  class ArraySerializer
    def self.load(arr)
      return if arr.nil?
      arr.map do |item|
        DraftSessionDate.new(
          index: item.fetch("index"),
          value: item.fetch("value")
        )
      end
    end

    def self.dump(values)
      values.map { |value| value.is_a?(Hash) ? value : value.attributes }
    end
  end
end
