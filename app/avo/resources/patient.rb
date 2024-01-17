class Avo::Resources::Patient < Avo::BaseResource
  self.title = :full_name
  self.includes = []
  self.record_selector = false
  # self.search_query = -> do
  #   query.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  def fields
    field :id, as: :id
    # Fields generated from the model
    field :first_name, as: :string
    field :last_name, as: :string
    field :common_name, as: :string
    field :date_of_birth, as: :date
    field :nhs_number, as: :number
    field :sessions, as: :has_and_belongs_to_many
    field :location, as: :belongs_to
    # add fields here
    field :parent_name, as: :string
    field :parent_relationship,
          as: :select,
          enum: ::Patient.parent_relationships
    field :parent_relationship_other, as: :string
    field :parent_email, as: :string
    field :parent_phone, as: :string
    field :location, as: :belongs_to
  end
end
