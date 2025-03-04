# frozen_string_literal: true

class SearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  include ActiveRecord::AttributeAssignment

  attribute :q, :string
  attribute :date_of_birth, :date
  attribute :missing_nhs_number, :boolean

  def apply(scope)
    scope = scope.search_by_name(q) if q.present?

    scope = scope.where(date_of_birth:) if date_of_birth.present?

    scope = scope.where(nhs_number: nil) if missing_nhs_number.present?

    scope.order_by_name
  end
end
