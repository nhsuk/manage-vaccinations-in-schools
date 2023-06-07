class LocationResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :name, as: :textarea
  field :address, as: :textarea
  field :locality, as: :textarea
  field :town, as: :textarea
  field :county, as: :textarea
  field :postcode, as: :textarea
  field :url, as: :textarea
  field :sessions, as: :has_many
  field :children, as: :has_many
  # add fields here
end
