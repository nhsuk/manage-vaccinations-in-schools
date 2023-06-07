class SessionResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :date, as: :date_time
  field :location_id, as: :number
  field :name, as: :textarea
  field :campaign_id, as: :number
  field :campaign, as: :belongs_to
  field :location, as: :belongs_to
  field :children, as: :has_and_belongs_to_many
  # add fields here
end
