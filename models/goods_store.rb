class GoodsStore < ActiveRecord::Base
	belongs_to :goods_info
	belongs_to :user
	belongs_to :fridge
end