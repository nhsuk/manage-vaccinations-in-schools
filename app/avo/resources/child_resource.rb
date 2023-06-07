class ChildResource < Avo::BaseResource
  self.title = :full_name
  self.includes = []
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :dob, as: :date
  field :nhs_number, as: :number
  field :sex, as: :select, enum: ::Child.sexes
  field :first_name, as: :text
  field :last_name, as: :text
  field :preferred_name, as: :text
  field :gp, as: :select, enum: ::Child.gps
  field :screening, as: :select, enum: ::Child.screenings
  field :consent, as: :select, enum: ::Child.consents
  field :seen, as: :select, enum: ::Child.seens
  field :sessions, as: :has_and_belongs_to_many
  field :location, as: :belongs_to
  # add fields here
end
