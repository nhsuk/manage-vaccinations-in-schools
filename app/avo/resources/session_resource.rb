class SessionResource < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.record_selector = false
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :name, as: :text
  field :date, as: :date_time
  field :campaign, as: :belongs_to
  field :location, as: :belongs_to
  field :children, as: :has_and_belongs_to_many
  # add fields here
end
