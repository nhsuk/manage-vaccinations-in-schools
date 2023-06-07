class LocationResource < Avo::BaseResource
  self.title = :name
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :name, as: :text
  field :address, as: :text
  field :locality, as: :text
  field :town, as: :text
  field :county, as: :text
  field :postcode, as: :text
  field :url, as: :text
  field :sessions, as: :has_many
  field :children, as: :has_many
  # add fields here
end
