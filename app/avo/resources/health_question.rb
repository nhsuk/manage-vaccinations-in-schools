class Avo::Resources::HealthQuestion < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   query.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # add fields here
  field :vaccine, as: :belongs_to
  field :question, as: :string
  field :hint, as: :string
end
