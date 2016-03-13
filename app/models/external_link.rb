class ExternalLink < ActiveRecord::Base
	has_attached_file :image, 
		styles: { original: ["1024x1024>"], medium: ["500x500>"] }, 
		default_url: ''
end
