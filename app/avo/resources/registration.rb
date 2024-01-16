class Avo::Resources::Registration < Avo::BaseResource
  self.includes = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :location_id, as: :number
    field :parent_name, as: :text
    field :parent_relationship,
          as: :select,
          enum: ::Registration.parent_relationships
    field :parent_relationship_other, as: :text
    field :parent_email, as: :text
    field :parent_phone, as: :text
    field :first_name, as: :text
    field :last_name, as: :text
    field :use_common_name, as: :boolean
    field :common_name, as: :text
    field :date_of_birth, as: :date
    field :address_line_1, as: :text
    field :address_line_2, as: :text
    field :address_town, as: :text
    field :address_postcode, as: :text
    field :nhs_number, as: :text
    field :terms_and_conditions_agreed, as: :boolean
    field :data_processing_agreed, as: :boolean
    field :consent_response_confirmed, as: :boolean
    field :location, as: :belongs_to
  end
end
