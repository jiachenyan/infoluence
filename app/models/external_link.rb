class ExternalLink < ActiveRecord::Base
	# must start with http:\\ or https:\\
	VALID_URL_REGEX = /\A(https?):\/\/(([^:\s]+):([^@\s]+)@)?((www\.)?([^\s\/:]+)\.([^\s\/\.:]+))((\/|:)([^\s]*))?\Z/i
	VALID_URL_IMAGE_EXTENSIONS = [/\A\.jpe?g/i, /\A\.png/i, /\A\.bmp/i]
	VALID_IMAGE_CONTENT_TYPES = [/\Aimage\/jpe?g\Z/, /\Aimage\/png\Z/, /\Aimage\/bmp\Z/]

	USER_AGENT = 'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)'

	@@max_og_reader_unnest_level = 4
	@@max_image_checks = 4

	attr_accessible :url, :origin

	has_attached_file :image,
		styles: { large: ["1024x1024>"], medium: ["500x500>"] }, 
		default_url: ''

	# delete null values in info, shallow
	before_validation :clean_up_info

	validates :url, presence: true, uniqueness: true, format: { with: VALID_URL_REGEX }
	validates :origin, :info_og_url, :info_og_title, presence: true
	validates_attachment_content_type :image, content_type: VALID_IMAGE_CONTENT_TYPES

	# download and save images in link info
	before_save :process_images

	after_touch :increment_trend_value

	def self.find_by_url_or_origin(input)
		where("url = ? OR origin = ?", input, input).first
	end

	def increment_trend_value
		# don't add trend value to non saved links
		return unless self.persisted?
		self.update_column(:trend_value, trend_value + 1.0)
	end

	def add_fetch_error
		set_default_info
		properties['fetch_error'] = true
	end

	# process and save og_reader as link info
	def process_link_info(og_reader)
		og_reader_bases = og_reader.bases.with_indifferent_access
		self.properties = unnest_og_reader(og_reader_bases[:og])

		# save other bases
		og_reader_bases.delete(:og)
		self.properties.merge!(unnest_og_reader(og_reader_bases))
	end

	def info_og_url
		properties.try(:[], 'url')
	end

	def info_og_title
		properties.try(:[], 'title')
	end

	def json_serialize
		publish_time = properties['article_published_time']
		publish_time = Time.parse(publish_time).to_i unless publish_time.blank?

		# use null instead of default image url
		medium_image = image.url(:medium) unless image.blank?
		large_image = image.url(:large) unless image.blank?

		{
			id: id,
			url: url,
			title: properties['title'],

			# all values below may be null
			siteName: properties['site_name'],
			description: properties['description'],

			# articles
			publishTime: publish_time,
			author: properties['article_author'],

			# profile
			firstName: properties['profile_first_name'],
			lastName: properties['profile_last_name'],

			# videos
			video: properties['video_value'],
			videoWidth: properties['video_width'],
			videoHeight: properties['video_height'],
			videoType: properties['video_type'],

			imgSmall: medium_image,
			imgLarge: large_image,
			images: image_urls,
		}
	end

	def image_urls
		return [] if properties.try(:[], 'image').blank?

		if properties['image'].first.is_a?(Hash)
			properties['image'].map! do |image|
				image['value']
			end
		else
			properties['image']
		end
	end

	private

	def unnest_og_reader(object, current_level=0)
		return object if current_level > @@max_og_reader_unnest_level

		# unnest properties and children
		if object.class.name.split('::').first == 'OpenGraphReader'
			unnested_object = Hash.new

			unnested_object.merge!(object.properties) if object.properties.present?
			unnested_object.merge!(object.children) if object.children.present?
			unnested_object[:value] = object.content if object.content.present?

			unnest_og_reader(unnested_object, current_level+1)

		# unnest hash
		elsif object.is_a?(Hash)
			unnested_object = Hash.new

			object.each do |key, value|
				unnested_sub_object = unnest_og_reader(value, current_level+1)

				if unnested_sub_object.is_a?(Hash)
					# continue flattening hashes with merged keys
					unnested_sub_object.each do |sub_key, sub_value|
						unnested_object["#{key}_#{sub_key}"] = sub_value
					end
				else
					unnested_object[key] = unnested_sub_object
				end
			end

			unnested_object

		# unnest items in array
		elsif object.is_a?(Array)
			object.map! do |sub_object|
				unnest_og_reader(sub_object, current_level+1)
			end

		# do nothing
		else
			object
		end
	end

	def set_default_info
		if properties.nil?
			self.properties = {
				'url' => url,
				'title' => url
			}
		else
			# don't overwrite if already set
			properties['url'] = url if properties['url'].blank?
			properties['title'] = url if properties['title'].blank?
		end
	end

	def clean_up_info
		if properties.nil?
			set_default_info
		else
			properties.delete_if {|k,v| v.blank?}
		end
	end

	def process_images
		@link_semaphore = Mutex.new
		thread_list = Array.new

		less_preferred_urls = Array.new
		image_urls[0..@@max_image_checks].each do |image_url|
			# image already set, try no more
			return true if image.present?

			url_ext = File.extname(image_url)
			if url_ext.blank?
				# no file extension, less preferred url, try later
				less_preferred_urls << image_url
				next
			elsif !valid_image_extension?(url_ext)
				# skip images with unsupported image formats, eg. gifs
				next
			end

			thread_list << thread_set_fetched_image(image_url, url_ext)
		end
		thread_list.each {|t| t.join}

		# try less preferred urls
		less_preferred_urls.each do |image_url|
			# image already set, try no more
			return true if image.present?
			thread_list << thread_set_fetched_image(image_url)
		end
		thread_list.each {|t| t.join}

		true # always return true so saving is not halted
	end

	def thread_set_fetched_image(image_url, file_ext = "")
		ThreadUtil.threaded_conn do
			# for html5 links without protocol
			image_url.prepend('http:') if image_url[0..1] == '//'

			# fetch image
			uri = URI.parse(URI.escape(image_url))
			begin
				fetched_image = Timeout.timeout(2){ open(uri, 'User-Agent' => USER_AGENT) }
			rescue => e
				Thread.exit
			end

			# don't try to save file if invalid type
			open_file_ctype = fetched_image.content_type
			Thread.exit unless valid_image_content_type?(open_file_ctype)

			# generate file name with url extension or content type
			file_ext = ".#{open_file_ctype.gsub(/\Aimage\//, '')}" if file_ext.blank?
			rand_file_name = "#{SecureRandom.urlsafe_base64(8)}#{file_ext}"

			@link_semaphore.synchronize do
				# don't try to save another image
				Thread.exit if image.present?

				# set image, time usage is expensive af
				begin
					Timeout.timeout(2.5){ self.image = fetched_image }
				rescue => e
					# image took too long to process or paperclip error, reset image to nil
					self.image = nil
					Thread.exit
				end

				# update record with random file name, and file type based on opened uri
				self.image_content_type = open_file_ctype
				self.image_file_name = rand_file_name

				# reset image if it's invalid
				self.image = nil unless valid?
			end
		end
	end

	def valid_image_extension?(file_ext)
		regex_array_validate(VALID_URL_IMAGE_EXTENSIONS, file_ext)
	end

	def valid_image_content_type?(content_type)
		regex_array_validate(VALID_IMAGE_CONTENT_TYPES, content_type)
	end

	def regex_array_validate(regex_array, check_str)
		regex_array.each do |valid_type|
			return true if check_str =~ valid_type
		end
		false
	end
end
