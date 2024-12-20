
Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  mount Identity::Engine => '/auth'

  root :to => 'pages#index'

  # Frontend
  resources :users, :except => %i[show destroy] do
    member do
      post 'resend_confirmation_email'
    end
  end

  namespace :api do
    namespace :v3 do
      put '/user' => 'user#update'
      delete '/user' => 'user#destroy'
      resources :areas, :only => [:index, :show]
      resources :gqueries, :only => :index
      resources :scenarios, :only => [:index, :show, :create, :update, :destroy] do
        member do
          get :batch
          get :application_demands, to: 'export#application_demands'
          get :production_parameters, to: 'export#production_parameters'
          get :energy_flow, to: 'export#energy_flow'
          get :molecule_flow, to: 'export#molecule_flow'
          get :costs_parameters, to: 'export#costs_parameters'
          get :sankey, to: 'export#sankey'
          get :storage_parameters, to: 'export#storage_parameters'
          get :merit
          put :dashboard
          post :interpolate
          post :uncouple
          post :couple
        end
        collection do
          post :merge

          get 'versions', to: 'scenario_version_tags#index'
        end
        get :templates, :on => :collection

        resources :nodes, :only => :show do
          get  :topology, :on => :collection
          post :stats,    :on => :collection
        end

        get 'converters', to: redirect('/api/v3/scenarios/%{scenario_id}/nodes')
        get 'converters/:id', to: redirect('/api/v3/scenarios/%{scenario_id}/nodes/%{id}')

        resources :inputs, :only => [:index, :show]

        resource :version, :only => [:create, :show, :update], controller: 'scenario_version_tags'

        # Flexibility orders have been removed. Endpoint returns a 404 with a useful message.
        get   '/flexibility_order', to: 'removed_features#flexibility_order'
        put   '/flexibility_order', to: 'removed_features#flexibility_order'
        patch '/flexibility_order', to: 'removed_features#flexibility_order'

        resource :heat_network_order, only: [:show, :update],
          controller: :user_sortables, sortable_type: :heat_network

        resource :forecast_storage_order, only: [:show, :update],
          controller: :user_sortables, sortable_type: :forecast_storage

        resource :hydrogen_supply_order, only: [:show, :update],
          controller: :user_sortables, sortable_type: :hydrogen_supply

        resource :hydrogen_demand_order, only: [:show, :update],
          controller: :user_sortables, sortable_type: :hydrogen_demand

        resource :households_space_heating_producer_order, only: [:show, :update],
          controller: :user_sortables, sortable_type: :space_heating

        resources :custom_curves, only: %i[index show update destroy],
          constraints: { id: %r{[a-z\d_\-/]+} }

        resource :esdl_file, only: %i[show update]

        resources :users, only: %i[index create update destroy], controller: 'scenario_users' do
          collection do
            post :create
            put :update
            delete :destroy
          end
        end

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

        get 'curves/hydrogen_integral_cost',
          to: 'curves#hydrogen_integral_cost',
          as: :hydrogen_integral_cost_download

      end

      resources :saved_scenarios
      resources :collections

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
  get '/redirect_to_external', to: 'redirect#set_cookie_and_redirect', as: :redirect_to_external

  get '/data/*rest',
    to: redirect(status: 302) { |params| "/inspect/#{params[:rest]}" }

  namespace :etsource do
    root :to => 'commits#index'

    resources :commits, :only => [:index] do
      get :import, :on => :member
    end
  end
end
