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
    field :first_name, as: :text
    field :last_name, as: :text
    field :common_name, as: :text
    field :date_of_birth, as: :date
    field :nhs_number, as: :number
    field :sex, as: :select, enum: ::Patient.sexes
    field :screening, as: :select, enum: ::Patient.screenings
    field :consent, as: :select, enum: ::Patient.consents
    field :seen, as: :select, enum: ::Patient.seens
    field :sessions, as: :has_and_belongs_to_many
    field :location, as: :belongs_to
    # add fields here
    field :parent_name, as: :text
    field :parent_relationship,
          as: :select,
          enum: ::Patient.parent_relationships
    field :parent_relationship_other, as: :text
    field :parent_email, as: :text
    field :parent_phone, as: :text
    field :parent_info_source, as: :text
  end
end
