class Influence < ActiveRecord::Base
  belongs_to :user
  belongs_to :post

  # null user_id when type = oc -- user_id is publisher
  # null user_id when anonymous read, type = rd
  # user_id no null when type = sh

  # only one 'oc' per post_id

  # null from_inf_id when type = oc
end
