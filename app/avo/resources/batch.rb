class Avo::Resources::Batch < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   query.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :name, as: :text
  field :expiry, as: :date
  field :vaccine_id, as: :number
  field :vaccine, as: :belongs_to
  field :vaccination_records, as: :has_many
  # add fields here
end
