ruby '2.1.5'


# Bower releases with Rails Assets
source 'https://rails-assets.org' do
	gem 'rails-assets-angular', '~> 1.4.8'
	gem 'rails-assets-angular-cookies', '~> 1.4.8'
	gem 'rails-assets-angular-ui-router', '~> 0.2.15'
	gem 'rails-assets-d3',  '~> 3.5.16'
	gem 'rails-assets-normalize-css', '~> 3.0.3'
end


source 'https://rubygems.org' do 
	gem 'rails', '~> 4.2.5.1'


	# Assets
	gem 'bourbon', '~> 4.2.3'
	gem 'jquery-rails'
	gem 'font-awesome-rails', '~> 4.5'


	# Asset Pipeline
	gem 'angular-rails-templates', '~> 0.1.4'
	gem 'coffee-rails', '~> 4.1.0'
	gem 'sass-rails', '~> 5.0.1'
	gem 'slim-rails', '~> 3.0.1'
	gem 'sprockets', '~> 2.12.3'
	gem 'turbolinks'
	gem 'uglifier', '>= 1.3.0'


	# Application
	gem 'activesupport-json_encoder', '~> 1.1.0' # allow automatic json encoding of big decimal to float 
	gem 'aws-sdk', '~> 1.64.0' # for paperclip
	gem 'faraday', '~> 0.9.1'
	gem 'faraday_middleware', '~> 0.9.1' # for open_graph_reader
	gem 'faraday-cookie_jar', '~> 0.0.6' # for open_graph_reader
	gem 'oj', '~> 2.12.1'
	gem 'nokogiri', '~> 1.6.6.2'


	# Controllers
	gem 'tubesock', '~> 0.2.6' # websocket


	# Models
	gem 'bcrypt', '~> 3.1.9' # has_secure_password
	gem 'paperclip', '~> 4.2.1'
	gem 'protected_attributes', '~> 1.0.9' # for attr_accessible


	# DB
	gem 'pg', '~> 0.18.1' # postgres adapter


	# Server
	gem 'puma', '~> 2.11.3'
	gem 'rack-timeout-puma', '~> 0.0.1' # kill threads on timeout


	group :development do
	  gem 'better_errors', '~> 2.1.0'
		gem 'binding_of_caller', '~> 0.7.2'
		gem 'sdoc', '~> 0.4.0', group: :doc
		gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
	end
end
