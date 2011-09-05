Etm::Application.routes.draw do  
  root :to => 'pages#index'
  
  match 'login'  => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  resources :user_sessions

  scope '/api/v1', :module => 'api',  do
    resources :api_scenarios
  end

  scope '/api/v2', :module => 'api',  do
    resources :scenarios, :only => [:index, :show, :create, :update] do
      get :load, :on => :member
      collection do
        get :homepage
      end
    end    
    resources :api_scenarios do
      member do 
        get :user_values
      end
    end
    resources :areas, :only => [:index, :show]
    resources :inputs, :only => [:index, :show]
    resources :gqueries, :only => [:index]
  end

  namespace :data do
    root :to => "pages#index", :blueprint_id => 'latest', :region_code => 'nl'
    
    match '/redirect' => "base#redirect", :as => 'redirect'
    match '/kick' => 'base#kick', :as => 'kick'

    scope '/:blueprint_id/:region_code' do
      root :to => "pages#index"
      resources :blueprint_layouts do
        resources :converter_positions
      end

      resources :gqueries do
        get :result, :on => :member
        collection do
          get :dump
          post :dump
          get :test
          post :test
          get :result
          get :group_descriptions
        end
      end

      resources :fce_values

      resources :converters do
        resource :converter_data
      end
      resources :converter_data

      resources :carriers, :only => [:index, :edit] do 
        resource :carrier_data
      end
      resources :carrier_data

      resources :areas do
        resources :carrier_data
      end

      resources :graphs do
        collection do
          post :import
        end
      end

      resources :gql_test_cases
      resources :historic_series
      resources :query_tables
      resources :query_table_cells, :except => [:show, :index]
      resources :blueprints
      resources :inputs
      resources :blueprint_models


      match '/gql' => "gql#index"
      match '/gql/search' => "gql#search", :as => :gql_search
    end
  end

  match '/:controller(/:action(/:id))'
end
