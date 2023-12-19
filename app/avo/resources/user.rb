class Avo::Resources::User < Avo::BaseResource
  self.title = :full_name
  self.includes = []
  # self.search_query = -> do
  #   query.ransack(id_eq: params[:q], m: "or").result(distinct: false)
  # end

  field :id, as: :id
  # Fields generated from the model
  field :email, as: :text
  field :full_name, as: :text
  field :sign_in_count, as: :number
  field :current_sign_in_at, as: :date_time
  field :last_sign_in_at, as: :date_time
  field :current_sign_in_ip, as: :text
  field :last_sign_in_ip, as: :text
  # add fields here
end
