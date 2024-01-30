class Avo::Resources::Team < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   query.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  def fields
    field :id, as: :id
    # Fields generated from the model
    field :email, as: :text
    field :name, as: :text
    field :campaigns, as: :has_many
    field :users, as: :has_and_belongs_to_many
    # add fields here
  end
end
