class User < ActiveRecord::Base
	attr_accessible(:name, :username, :email)

	has_secure_password

	before_validation :set_user_defaults

	VALID_NAME_REGEX = /\A[a-z\.\-'" ]+\z/i
	validates :name, presence: true, 
		length: { minimum: 1, maximum: 40 },
		format: { with: VALID_NAME_REGEX }

	VALID_USERNAME_REGEX = /\A[0-9a-z_\-]+\z/i
	validates :username, presence: true, 
		length: { minimum: 1, maximum: 20 },
		format: { with: VALID_USERNAME_REGEX }

	# email is case insensitive and with specific format
	VALID_EMAIL_REGEX = /\A.+@.+\.[a-z]+\z/i
	validates :email, presence: true, 
		format: { with: VALID_EMAIL_REGEX },
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
		default_url: "/"

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
