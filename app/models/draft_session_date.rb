# frozen_string_literal: true

class DraftSessionDate
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attribute :id, :integer
  attribute :value, :date

  validates :value, presence: true

  def attributes
    { "id" => id, "value" => value&.iso8601 }
  end

  def session_date = SessionDate.find_by(id:)

  def has_been_attended?
    session_date&.has_been_attended? || false
  end

  def persisted? = id != nil

  def new_record? = id.nil?

  class ArraySerializer
    def self.load(arr)
      return if arr.nil?
      arr.map do |item|
        DraftSessionDate.new(id: item.fetch("id"), value: item.fetch("value"))
      end
    end

    def self.dump(values)
      values.map { |value| value.is_a?(Hash) ? value : value.attributes }
    end
  end
end
