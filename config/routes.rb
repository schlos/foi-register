FoiRegister::Application.routes.draw do
  
  resources :attachments

  root :to => 'redirection#front'
  scope "(:is_admin)", :constraints => {:is_admin => /(admin)?/} do
    resources :requests do
      resources :responses
      collection do
        get 'overdue'
        get 'stats'
        get 'search'
        get 'search_typeahead'
      end
      member do
        get 'new_response'
      end
      resources :responses
    end
    resources :requestors
  end
  
  get "/admin" => 'redirection#admin'

  # Useful in development.
  # In production presumably /admin/assets is configured specially
  # in your web server config.
  match "/admin/assets/*path.:ext" => redirect("/assets/%{path}.%{ext}")

  scope "(:is_admin)", :constraints => {:is_admin => /(admin)/} do
    get "ajax/requestors"
    get "ajax/lgcs_terms"
    
    post "requests/:id/update_state.json", :controller => :requests, :action => :update_state
    
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
