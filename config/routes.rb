FoiRegister::Application.routes.draw do

  root :to => 'redirection#front'
  scope "(:is_admin)", :constraints => {:is_admin => /(admin)?/, :id => /\d+/} do
    resources :requests do
      resources :responses do
        member do
          get 'letter', :constraints => {:format => "pdf"}
        end
      end
      collection do
        get 'overdue'
        get 'stats'
        get 'search'
        get 'search_typeahead'
        get 'category/:top_level_lgcs_term_id', :action => "in_category", :constraints => { :is_admin => "" }
      end
    end
    resources :requestors
  end

  # One-time only links for requestors to register
  # their response to the outcome of their request
  get "/c/:token" => 'requestor_confirmation#show'
  post "/c/:token" => 'requestor_confirmation#set_response'

  get "/admin" => 'redirection#admin'

  # Useful in development.
  # In production presumably /admin/assets is configured specially
  # in your web server config.
  match "/admin/assets/*path.:ext" => redirect("/assets/%{path}.%{ext}")

  # Admin-only routes
  scope "(:is_admin)", :constraints => {:is_admin => /(admin)/} do
    get "ajax/requestors"
    get "ajax/lgcs_terms"

    resources :requests do
      member do
        post "update_state", :constraints => {:format => "json"}
      end
      collection do
        get 'feed', :constraints => {:format => "atom"}
      end
    end

    resources :staff_members
    resources :sessions do
      collection do
        get "logout"
      end
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
