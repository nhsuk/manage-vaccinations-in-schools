class ChildResource < Avo::BaseResource
  self.title = :full_name
  self.includes = []
  self.record_selector = false
  # self.search_query = -> do
  #   scope.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :dob, as: :date, required: true
  field :nhs_number, as: :number, required: true
  field :sex, as: :select, enum: ::Child.sexes
  field :first_name, as: :text, required: true
  field :last_name, as: :text, required: true
  field :preferred_name, as: :text
  field :gp, as: :select, enum: ::Child.gps, required: true
  field :screening, as: :select, enum: ::Child.screenings, required: true
  field :consent, as: :select, enum: ::Child.consents, required: true
  field :seen, as: :select, enum: ::Child.seens, required: true
  field :sessions, as: :has_and_belongs_to_many
  field :location, as: :belongs_to
  # add fields here
end
