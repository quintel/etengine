Etm::Application.routes.draw do
  devise_for :users

  root :to => 'pages#index'

  # Frontend
  resources :users, :except => :show
  get '/graph' => 'data/blueprint_layouts#show', :defaults => {:api_scenario_id => 'latest', :id => 1}

  namespace :api do
    namespace :v3 do
      resources :areas, :only => [:index, :show]
      resources :scenarios, :only => [:show, :create, :update] do
        member do
          get :batch
          get :sandbox
          get :merit
          put :dashboard
        end
        collection do
          post :merge
        end
        get :templates, :on => :collection
        resources :converters, :only => :show do
          get  :topology, :on => :collection
          post :stats,    :on => :collection
        end
        resources :inputs, :only => [:index, :show]
        resource :flexibility_order, only: [] do
          collection do
            post :set
            get :get
          end
        end

        get 'merit/loads' => 'merit#load_curves', as: :merit_download
        get 'merit/price' => 'merit#price_curve', as: :merit_price_download
      end
      resources :converters, :only => :show do
        get :topology, :on => :collection
      end
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

  namespace :data do
    get  '/redirect'    => "base#redirect", :as => 'redirect'
    post '/restart'     => 'pages#restart', :as => 'restart'
    post '/clear_cache' => 'pages#clear_cache', :as => 'clear_cache'

    scope '/:api_scenario_id' do
      root :to => "pages#index", :api_scenario_id => 'latest'

      get '', to: 'pages#index'

      # The Graphviz
      resource :layout, :except => [:new, :index, :create, :destroy] do
        member { get 'yaml' }
      end

      resources :gqueries, :only => [:index, :show] do
        get :result, :on => :member
        collection do
          get :test
          post :test
          get :result
        end
      end

      resources :converters, :only => [:index, :show]
      resources :carriers, :only => [:index, :show]
      resource  :area, :as => :area, :only => :show

      resources :query_tables
      resources :query_table_cells, :except => [:show, :index]
      resources :inputs, :only => [:index, :show]

      resources :scenarios, :only => [:index, :show, :edit, :update, :new, :create] do
        put :fix, :on => :member
      end

      get '/share_groups' => 'share_groups#index'

      get '/checks/:action' => 'checks'

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

      get 'search' => 'search#index', :as => :search
    end
  end

  get '/data', to: redirect("data/latest")

  namespace :etsource do
    root :to => 'commits#index'

    resources :commits, :only => [:index, :show] do
      get :import, :on => :member
    end
  end
end
