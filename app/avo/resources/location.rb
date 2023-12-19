class Avo::Resources::Location < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.record_selector = false
  # self.search_query = -> do
  #   query.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  def fields
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
    field :patients, as: :has_many
    # add fields here
  end
end
