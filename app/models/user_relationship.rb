class UserRelationship < ActiveRecord::Base
	before_validation :validate_self_follow
	validates :follows_id, uniqueness: { scope: :follower_id }
	
	def validate_self_follow
		if follows_id == follower_id
			 errors.add(:follow, "can't self-follow") 
			return false
		end
		true
	end
end
