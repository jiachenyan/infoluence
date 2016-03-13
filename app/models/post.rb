class Post < ActiveRecord::Base
	# CT_PG_KEYS = ['body']
	# CT_LK_KEYS = ['imgUrl', 'imgUrlOri', 'description', 'url', 'source']
	# CT_IM_KEYS = ['imgUrlSm', 'imgUrlLg']

	belongs_to :user

	has_many :influences

	before_validation :validate_content

	private

	def validate_content
		# validate content
		unless content.is_a?(Hash)
			errors.add(:content, 'is invalid')
			return false
		end

		# validate title
		title = content['title']
		if !title.is_a?(String) or title.blank?
			errors.add('title', 'is invalid')
			return false
		end

		# validate data
		# validated_dts = Array.new
		# content['data'].each do |dt|
		# 	next unless dt.is_a?(Hash) # skip invalid data types
		# 	case dt['type']
		# 	when 'pg'
		# 		validated_dts << validate_dt!(dt, CT_PG_KEYS)
		# 	when 'lk'
		# 		validated_dts << validate_dt!(dt, CT_LK_KEYS)
		# 	when 'im'
		# 		validated_dts << validate_dt!(dt, CT_IM_KEYS)
		# 	end
		# end
		# self.content['data'] = validated_dts

		true
	end

	# def validate_dt!(dt, keys)
	# 	dt.slice!(*keys)
	# 	dt.each do |key, val|
	# 	 errors.add(key, 'is invalid') unless val.is_a?(String)
	# 	end
	# 	dt
	# end
end
