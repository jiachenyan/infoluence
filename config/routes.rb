Rails.application.routes.draw do
	root to: 'static#index'

	scope format: true, constraints: { format: :json } do

		resources :user, only: [:create]
		resources :session, only: [:create, :destroy]
		resources :post, only: [:create]

	end

	# load application container by default
	get '*path', to: 'static#index'
end
