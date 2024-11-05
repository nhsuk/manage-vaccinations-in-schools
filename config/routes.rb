# frozen_string_literal: true

Rails.application.routes.draw do
  # Redirect www subdomain to root in production envs
  unless Rails.env.development? || Rails.env.test?
    match "(*any)",
          to: redirect(subdomain: ""),
          via: :all,
          constraints: {
            subdomain: "www"
          }
  end

  if Settings.cis2.enabled
    devise_for :users,
               module: :users,
               controllers: {
                 omniauth_callbacks: "users/omniauth_callbacks"
               }
    devise_scope :user do
      post "/users/auth/cis2/backchannel-logout",
           to: "users/omniauth_callbacks#cis2_logout"
      delete "/logout", to: "users/omniauth_callbacks#logout"
    end
  else
    devise_for :users,
               module: :users,
               path_names: {
                 sign_in: "sign-in",
                 sign_out: "sign-out"
               }
    devise_scope :user do
      delete "/logout", to: "users/sessions#destroy"
    end
  end

  root to: redirect("/start")

  mount GoodJob::Engine => "/good-job"

  get "/start", to: "pages#start"
  get "/dashboard", to: "dashboard#index"
  get "/accessibility-statement", to: "content#accessibility_statement"

  get "/ping" => proc { [200, {}, ["PONG"]] }

  flipper_app =
    Flipper::UI.app do |builder|
      builder.use Rack::Auth::Basic do |username, password|
        ActiveSupport::SecurityUtils.secure_compare(
          Rails.application.credentials.support_username,
          username
        ) &&
          ActiveSupport::SecurityUtils.secure_compare(
            Rails.application.credentials.support_password,
            password
          )
      end
    end
  mount flipper_app, at: "/flipper"

  if Rails.env.development? || Rails.env.test?
    get "/reset", to: "dev#reset"
    get "/random_consent_form", to: "dev#random_consent_form"
  end

  constraints -> { Flipper.enabled?(:dev_tools) } do
    get "/reset/:organisation_ods_code",
        to: "dev#reset_organisation",
        as: :reset_organisation
  end

  get "/csrf", to: "csrf#new"

  namespace :parent_interface, path: "/" do
    resources :consent_forms, path: "/consents", only: %i[create] do
      collection do
        get ":session_slug/:programme_type/start", action: "start", as: :start
        get ":session_slug/:programme_type/deadline-passed",
            action: "deadline_passed",
            as: :deadline_passed
      end

      member do
        get "cannot-consent-responsibility"
        get "confirm"
        put "record"
      end

      resources :edit, only: %i[show update], controller: "consent_forms/edit"
    end
  end

  resources :consent_forms, path: "consent-forms", only: %i[index show] do
    member do
      get "match/:patient_id", action: :edit_match, as: :match
      post "match/:patient_id", action: :update_match
    end
  end

  resources :notices, only: :index

  resources :patients, only: %i[index show edit update] do
    post "", action: :index, on: :collection

    member do
      get "log"

      get "edit/nhs-number",
          controller: "patients/edit",
          action: "edit_nhs_number"
      put "edit/nhs-number",
          controller: "patients/edit",
          action: "update_nhs_number"
      put "edit/nhs-number-merge",
          controller: "patients/edit",
          action: "update_nhs_number_merge"
    end
  end

  resources :programmes, only: %i[index show], param: :type do
    get "sessions", on: :member

    resources :cohort_imports, path: "cohort-imports", except: %i[index destroy]

    resources :cohorts, only: %i[index show]

    resources :patients, only: %i[index], module: "programme"

    resources :immunisation_imports,
              path: "immunisation-imports",
              except: %i[index destroy]

    resources :import_issues, path: "import-issues", only: %i[index] do
      get ":type", action: :show, on: :member, as: ""
      patch ":type", action: :update, on: :member
    end

    resources :imports, only: %i[index new create]

    resources :vaccination_records,
              path: "vaccination-records",
              only: %i[index show edit] do
      post "export-dps", on: :collection
      constraints -> { Flipper.enabled?(:dev_tools) } do
        post "reset-dps-export", on: :collection
      end

      get "edit/date-and-time",
          controller: "vaccination_records/edit",
          action: "edit_date_and_time"
      put "edit/date-and-time",
          controller: "vaccination_records/edit",
          action: "update_date_and_time"
    end
  end

  resources :sessions, only: %i[edit index show], param: :slug do
    collection do
      get "closed"
      get "completed"
      get "scheduled"
      get "unscheduled"
    end

    member do
      get "close", action: "edit_close"
      post "close", action: "update_close"

      get "consent-form", action: "consent_form"

      get "edit/send-consent-requests-at",
          controller: "sessions/edit",
          action: "edit_send_consent_requests_at"
      put "edit/send-consent-requests-at",
          controller: "sessions/edit",
          action: "update_send_consent_requests_at"

      get "edit/send-invitations-at",
          controller: "sessions/edit",
          action: "edit_send_invitations_at"
      put "edit/send-invitations-at",
          controller: "sessions/edit",
          action: "update_send_invitations_at"

      get "edit/weeks-before-consent-reminders",
          controller: "sessions/edit",
          action: "edit_weeks_before_consent_reminders"
      put "edit/weeks-before-consent-reminders",
          controller: "sessions/edit",
          action: "update_weeks_before_consent_reminders"

      constraints -> { Flipper.enabled?(:dev_tools) } do
        put "make-in-progress", to: "sessions#make_in_progress"
      end

      constraints -> { Flipper.enabled?(:offline_working) } do
        get "setup-offline", to: "offline_passwords#new"
        post "setup-offline", to: "offline_passwords#create"
      end
    end

    resources :class_imports, path: "class-imports", except: %i[index destroy]

    resource :dates, controller: "session_dates", only: %i[show update]

    resources :moves, controller: "session_moves", only: %i[index update]
  end

  scope "/sessions/:session_slug/:section", as: "session" do
    constraints section: "consents" do
      defaults section: "consents" do
        get "/",
            as: "consents",
            to:
              redirect(
                "/sessions/%{session_slug}/consents/#{TAB_PATHS[:consents].keys.first}"
              )

        get ":tab",
            controller: "consents",
            action: :index,
            as: :consents_tab,
            tab: TAB_PATHS[:consents].keys.join("|")
      end
    end

    constraints section: "triage" do
      defaults section: "triage" do
        get "/",
            as: "triage",
            to:
              redirect(
                "/sessions/%{session_slug}/triage/#{TAB_PATHS[:triage].keys.first}"
              )

        get ":tab",
            controller: "triages",
            action: :index,
            as: :triage_tab,
            tab: TAB_PATHS[:triage].keys.join("|")
      end
    end

    constraints section: "vaccinations" do
      defaults section: "vaccinations" do
        get "/",
            as: "vaccinations",
            to:
              redirect(
                "/sessions/%{session_slug}/vaccinations/#{TAB_PATHS[:vaccinations].keys.first}"
              )

        get "batch", to: "vaccinations#batch"
        patch "batch", to: "vaccinations#update_batch"

        get ":tab",
            controller: "vaccinations",
            action: :index,
            as: :vaccinations_tab,
            tab: TAB_PATHS[:vaccinations].keys.join("|")
      end
    end

    scope ":tab" do
      resources :patient_sessions,
                path: "patients",
                as: :patient,
                only: %i[show] do
        get "log"
        post "request-consent", action: :request_consent

        post "consents", to: "manage_consents#create", as: :manage_consents
        resources :manage_consents,
                  only: %i[show update],
                  path: "consents/:consent_id/" do
          get "details", on: :collection, to: "consents#show"
        end

        resource :gillick_assessment, only: %i[new create]

        resource :gillick_assessment,
                 path: "gillick-assessment/:id",
                 only: %i[show update]

        resource :triages, only: %i[new create]

        resource :vaccinations, only: %i[create] do
          resource "edit",
                   only: %i[show update],
                   controller: "vaccinations/edit",
                   path: "edit/:id"
        end
      end
    end

    # These are just used to create helpers with better names that allow passing
    # in section and/or tab as a parameter. e.g. session_section_path(@session,
    # section: @section) which looks cleaner than session_triage_path(@session,
    # section: @section)
    get "/", to: "errors#not_found", as: "section"
    get "/:tab", to: "errors#not_found", as: "section_tab"
  end

  resource :organisation, only: %i[show]

  resources :vaccines, only: %i[index show] do
    resources :batches, only: %i[create edit new update] do
      member do
        get "archive", action: "edit_archive"
        post "archive", action: "update_archive"

        post "make-default", as: :make_default
      end
    end
  end

  namespace :users do
    get "organisation-not-found", controller: :errors
    get "workgroup-not-found", controller: :errors
    get "role-not-found", controller: :errors
  end

  scope via: :all do
    get "/404", to: "errors#not_found"
    get "/422", to: "errors#unprocessable_entity"
    get "/429", to: "errors#too_many_requests"
    get "/500", to: "errors#internal_server_error"
  end

  get "/oidc/jwks", to: "pages#jwks"
end
