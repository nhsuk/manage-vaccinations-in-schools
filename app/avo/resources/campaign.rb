class Avo::Resources::Campaign < Avo::BaseResource
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
    field :sessions, as: :has_many
    # add fields here
    field :vaccines, as: :has_and_belongs_to_many
    field :team, as: :belongs_to
  end
end
