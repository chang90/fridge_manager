class User < ActiveRecord::Base
	has_secure_password
	has_many :fridge_user_relationships
  has_many :fridges, through: :fridge_user_relationships
end
