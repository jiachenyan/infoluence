class User < ActiveRecord::Base
	attr_accessible(:name, :username)

	has_secure_password
	has_many :posts

	before_validation :set_user_defaults

	VALID_NAME_REGEX = /\A[a-z\.\-'" ]+\z/i
	validates :name, presence: true, 
		length: { minimum: 1, maximum: 40 },
		format: { with: VALID_NAME_REGEX }

	VALID_USERNAME_REGEX = /\A[0-9a-z_\-]+\z/i
	validates :username, presence: true, 
		length: { minimum: 4, maximum: 20 },
		format: { with: VALID_USERNAME_REGEX },
		uniqueness: { case_sensitive: false }

	validates :password, 
		length: { minimum: 6, maximum: 30 },
		on: :create
	validates :password, presence: true, 
		length: { minimum: 6, maximum: 30 },
		on: :update, if: :password_digest_changed?
	validates :password_confirmation,
		presence: true, 
		on: :update, if: :password_digest_changed?

	has_attached_file :avatar,
		styles: { medium: '300x300#', thumb: '100x100#' },
		default_url: 'http://s3.amazonaws.com/infoluence/default_avatar.jpg'

  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\Z/

  private

	def set_user_defaults # before_save
		# titleize replaces dash with spaces
		self.name = name.strip.split('-').map!(&:titleize).join('-') unless name.nil?
		
		self.email = email.strip.downcase unless email.nil?

		if new_record?
			# initialize login token
			self.token = SecureRandom.urlsafe_base64
			self.total_influence = 0
		end
	end
end
