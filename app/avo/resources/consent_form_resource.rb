class ConsentFormResource < Avo::BaseResource
  self.title = :id
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :session_id, as: :number
  # add fields here
  field :session, as: :belongs_to
  field :first_name, as: :text
  field :last_name, as: :text
  field :use_common_name, as: :boolean
  field :common_name, as: :text
  field :date_of_birth, as: :date
  field :recorded_at, as: :datetime
end
