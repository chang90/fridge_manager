class Fridge < ActiveRecord::Base
	has_many :goods_stores
	has_many :fridge_user_relationships
  has_many :users, through: :fridge_user_relationships
end