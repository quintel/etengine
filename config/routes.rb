require 'sidekiq/web'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  use_doorkeeper
  use_doorkeeper_openid_connect

  devise_for :users, path: 'identity', sign_out_via: %i[get post delete], controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  namespace :identity do
    get '/', to: redirect('/identity/profile')
    get 'profile', to: 'settings#index', as: :profile

    get 'change_name', to: 'settings#edit_name', as: :edit_name
    post 'change_name', to: 'settings#update_name'

    get 'change_email', to: 'settings#edit_email', as: :edit_email
    post 'change_email', to: 'settings#update_email'

    get 'change_password', to: 'settings#edit_password', as: :edit_password
    post 'change_password', to: 'settings#update_password'

    post 'change_scenario_privacy', to: 'settings#update_scenario_privacy'

    get 'newsletter', to: 'newsletter#edit', as: :edit_newsletter
    post 'newsletter', to: 'newsletter#update'

    resources :tokens, only: [:index, :new, :create, :destroy], as: :tokens
    resources :authorized_applications, only: [:index], as: :authorized_applications
  end

  devise_scope :user do
    get 'identity/delete_account', to: 'users/registrations#confirm_destroy', as: :delete_account
  end

  root :to => 'pages#index'

  # Frontend
  resources :users, :except => %i[show destroy]

  namespace :api do
    namespace :v3 do
      resources :areas, :only => [:index, :show]
      resources :scenarios, :only => [:index, :show, :create, :update, :destroy] do
        member do
          get :batch
          get :application_demands, to: 'export#application_demands'
          get :production_parameters, to: 'export#production_parameters'
          get :energy_flow, to: 'export#energy_flow'
          get :molecule_flow, to: 'export#molecule_flow'
          get :costs_parameters, to: 'export#costs_parameters'
          get :sankey, to: 'export#sankey'
          get :merit
          put :dashboard
          post :interpolate
        end
        collection do
          post :merge
        end
        get :templates, :on => :collection

        resources :nodes, :only => :show do
          get  :topology, :on => :collection
          post :stats,    :on => :collection
        end

        get 'converters', to: redirect('/api/v3/scenarios/%{scenario_id}/nodes')
        get 'converters/:id', to: redirect('/api/v3/scenarios/%{scenario_id}/nodes/%{id}')

        resources :inputs, :only => [:index, :show]

        # Flexibility orders have been removed. Endpoint returns a 404 with a useful message.
        get   '/flexibility_order', to: 'removed_features#flexibility_order'
        put   '/flexibility_order', to: 'removed_features#flexibility_order'
        patch '/flexibility_order', to: 'removed_features#flexibility_order'

        resource :heat_network_order, only: [:show, :update], controller: :heat_network_orders

        resources :custom_curves, only: %i[index show update destroy],
          constraints: { id: %r{[a-z\d_\-/]+} }

        resource :esdl_file, only: %i[show update]

        get 'curves/buildings_heat',
          to: 'curves#buildings_heat_curves',
          as: :curves_buildings_heat_download

        get 'curves/merit_order',
          to: 'curves#merit_order',
          as: :curves_merit_order_download

        get 'curves/electricity_price',
          to: 'curves#electricity_price',
          as: :curves_electricity_price_download

        get 'curves/heat_network',
          to: 'curves#heat_network',
          as: :curves_heat_network_download

        get 'curves/agriculture_heat',
          to: 'curves#agriculture_heat',
          as: :curves_agriculture_heat_download

        get 'curves/household_heat',
          to: 'curves#household_heat_curves',
          as: :curves_household_heat_download

        get 'curves/hydrogen',
          to: 'curves#hydrogen',
          as: :curves_hydrogen_download

        get 'curves/network_gas',
          to: 'curves#network_gas',
          as: :curves_network_gas_download

        get 'curves/residual_load',
          to: 'curves#residual_load',
          as: :curves_residual_load_download
      end

      resources :saved_scenarios
      resources :transition_paths

      resources :inputs, :only => [:index, :show] do
        get :list, :on => :collection
      end
    end
  end

  namespace :mechanical_turk do
    root :to => 'turks#index'
    resource :factory, :only => [:new, :create, :show]
    resources :turks, :only => [:index, :show]
  end

  namespace :inspect do
    get '/'             => 'pages#start_inspect'
    get  '/redirect'    => "base#redirect", :as => 'redirect'

    # Updating a staff application
    put '/staff_application/:id' => 'staff_applications#update', as: :staff_application

    get 'search.js' => 'search#index', as: :search_autocomplete

    scope '/:api_scenario_id' do
      root :to => "pages#index"
      post '/clear_cache' => 'pages#clear_cache', :as => 'clear_cache'

      # The Graphviz
      resources :layouts, :except => [:new, :index, :create, :destroy] do
        member { get 'yaml' }
      end

      get 'layout', to: redirect("api/v3/scenarios/%{api_scenario_id}/layout/energy")

      resources :gqueries, :only => [:index, :show] do
        get :result, :on => :member
        collection do
          get :test
          post :test
          get :result
        end
      end

      scope '/graphs/:graph_name' do
        resources :nodes, :only => [:index, :show]
      end

      resources :carriers, :only => [:index, :show]
      resource  :area, :as => :area, :only => :show

      resources :query_tables
      resources :query_table_cells, :except => [:show, :index]
      resources :inputs, :only => [:index, :show]

      resources :scenarios, :only => [:index, :show, :edit, :update, :new, :create] do
        put :fix, :on => :member
      end

      get '/checks/share_groups' => 'checks#share_groups'
      get '/checks/gquery_results' => 'checks#gquery_results'
      get '/checks/loops' => 'checks#loops'
      get '/checks/expected_demand' => 'checks#expected_demand'
      get '/checks/index' => 'checks#index'

      get '/debug/merit_order' => 'debug#merit_order'
      get '/debug/calculation' => 'debug#calculation'
      get '/debug/gquery' => 'debug#gquery', :as => :debug_gql

      get '/gql' => "gql#index"
      get '/gql/search' => "gql#search", :as => :gql_search
      get '/gql/log' => "gql#log", :as => :gql_log
      get '/gql/warnings' => "gql#warnings", :as => :gql_warnings

      get '/merit' => 'merit#index'

      get '/merit/download',
        to: redirect("api/v3/scenarios/%{api_scenario_id}/merit/loads.csv")

      get '/merit/download_prices',
        to: redirect("api/v3/scenarios/%{api_scenario_id}/merit/price.csv")

      get 'converters', to: redirect('/inspect/%{api_scenario_id}/nodes')
      get 'converters/:id', to: redirect('/inspect/%{api_scenario_id}/nodes/%{id}')

      get 'search' => 'search#index', :as => :search
    end
  end

  get '/data', to: redirect('/inspect', status: 302)

  get '/data/*rest',
    to: redirect(status: 302) { |params| "/inspect/#{params[:rest]}" }

  namespace :etsource do
    root :to => 'commits#index'

    resources :commits, :only => [:index] do
      get :import, :on => :member
    end
  end
end
