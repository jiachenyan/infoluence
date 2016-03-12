Rails.application.routes.draw do
	root to: 'static#index'

	# load application container by default
	get '*path', to: 'static#index'
end
