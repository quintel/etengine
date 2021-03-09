Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  devise_for :users

  root :to => 'pages#index'

  # Frontend
  resources :users, :except => :show

  namespace :api do
    namespace :v3 do
      resources :areas, :only => [:index, :show]
      resources :scenarios, :only => [:show, :create, :update] do
        member do
          get :batch
          get :application_demands, to: 'export#application_demands'
          get :production_parameters, to: 'export#production_parameters'
          get :energy_flow, to: 'export#energy_flow'
          get :molecule_flow, to: 'export#molecule_flow'
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

        resource :flexibility_order, only: [:show, :update],
          controller: :user_sortables, sortable_type: :flexibility

        resource :heat_network_order, only: [:show, :update],
          controller: :user_sortables, sortable_type: :heat_network

        resources :custom_curves, only: %i[index show update destroy],
          constraints: { id: %r{[a-z\d_\-/]+} }

        resource :esdl_file, only: %i[show update]

        get 'curves/merit_order',
          to: 'curves#merit_order',
          as: :curves_merit_order_download

        get 'curves/electricity_price',
          to: 'curves#electricity_price',
          as: :curves_electricity_price_download

        get 'curves/heat_network',
          to: 'curves#heat_network',
          as: :curves_heat_network_download

        get 'curves/household_heat',
          to: 'curves#household_heat_curves',
          as: :curves_household_heat_download

        get 'curves/hydrogen',
          to: 'curves#hydrogen',
          as: :curves_hydrogen_download

        get 'curves/network_gas',
          to: 'curves#network_gas',
          as: :curves_network_gas_download
      end

      resources :nodes, :only => :show do
        get :topology, :on => :collection
      end

      get 'converters', to: redirect('/api/v3/nodes')
      get 'converters/*rest', to: redirect('/api/v3/nodes/%{rest}')

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

    resources :commits, :only => [:index, :show] do
      get :import, :on => :member
    end
  end
end
