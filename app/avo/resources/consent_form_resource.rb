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
  field :parent_name, as: :text
  field :parent_relationship,
        as: :select,
        enum: ::ConsentForm.parent_relationships
  field :parent_relationship_other, as: :text
  field :parent_email, as: :text
  field :parent_phone, as: :text
  field :contact_method, as: :select, enum: ::ConsentForm.contact_methods
  field :contact_method_other, as: :text
  field :response, as: :select, enum: ::ConsentForm.responses
  field :reason, as: :select, enum: ::ConsentForm.reasons
  field :reason_notes, as: :text
  field :contact_injection, as: :boolean
  field :gp_name, as: :string
  field :gp_response, as: :select, enum: ::ConsentForm.gp_responses
  field :recorded_at, as: :datetime
end
