class VaccineResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :type, as: :text
  # add fields here
  field :campaigns, as: :has_and_belongs_to_many
  field :health_questions, as: :has_many
  field :brand, as: :text
  field :method, as: :select, enum: Vaccine.methods
  field :batches, as: :has_many
end
