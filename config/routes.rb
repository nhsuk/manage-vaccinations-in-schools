Rails.application.routes.draw do
  root to: redirect("/dashboard")
  get "/dashboard", to: "dashboard#index"

  resources :campaigns, only: %i[index] do
    resources :children,
              only: %i[index show],
              as: :vaccinations,
              controller: :vaccinations do
      put "record", on: :member
      get "confirmation", on: :member
      get "history", on: :member
      get "show-template", on: :collection
    end
  end

  scope via: :all do
    get "/404", to: "errors#not_found"
    get "/422", to: "errors#unprocessable_entity"
    get "/429", to: "errors#too_many_requests"
    get "/500", to: "errors#internal_server_error"
  end
end
