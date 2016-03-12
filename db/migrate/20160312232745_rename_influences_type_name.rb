class RenameInfluencesTypeName < ActiveRecord::Migration
	def change
		rename_column :influences, :type, :inf_type
	end
end
