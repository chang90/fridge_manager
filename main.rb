require 'sinatra'
# require 'sinatra/reloader'
require 'pry'

# using SendGrid's Ruby Library
# https://github.com/sendgrid/sendgrid-ruby
require 'sendgrid-ruby'
include SendGrid

require_relative 'db_config'
require_relative 'models/user'
require_relative 'models/fridge'
require_relative 'models/fridge_user_relationship'
require_relative 'models/goods_store'
require_relative 'models/goods_info'

enable :sessions

helpers do
	def current_user
		User.find_by(id: session[:user_id])
	end

	def logined_in?
		if current_user
			return true
		else
			return false
		end
	end

	def right_user?(fridge_id)
		# find out who own this fridge
		return user_id_arr = FridgeUserRelationship.where(["fridge_id = ?", fridge_id.to_s]).where(relationship: ["0", "1"]).empty?
		# flag = false
		# user_id_arr.each{|user|
		# 	if user.user_id.to_s == current_user.id.to_s
		# 		flag = true
		# 		break
		# 	end
		# }

		# if current_user && flag
		# 	return true
		# else
		# 	return false
		# end
	end

	# def owner?(user_id,fridge_id)
	# 	if Fridge.where(id: fridge_id.to_i).where(owner_id: user_id.to_i).empty?
	# 		return false
	# 	else
	# 		return true
	# 	end
	# end

	def fridge_is_empty?(fridge_id)
		fridge = GoodsStore.find_by(fridge_id: fridge_id.to_s)
		return !fridge
	end
end

get '/' do

	if logined_in?
		own_fridge_list = FridgeUserRelationship.where(user_id: current_user.id).where(relationship: 0)
		
		@own_fridge_detail_list = []
		own_fridge_list.each { |record|
			fridge = Fridge.find_by(id: record.fridge_id.to_s)
			if fridge
				@own_fridge_detail_list.push(fridge)
			end
		}

		@share_fridge_detail_list = []
		share_list = FridgeUserRelationship.where(["user_id = ? and relationship = ?", current_user.id.to_s, "1"])
		share_list.each { |record|
			fridge = Fridge.find_by(id: record.fridge_id.to_s)
			if fridge
				@share_fridge_detail_list.push(fridge)
			end
		}
		# return @fridge_detail_list.to_json
	end

  erb :index
end

get '/users/new' do
	@alert = params[:alert_info]
	erb :signup
end

post '/users' do
	if params[:password] == params[:password_confirmation]
		user = User.new
		user.username = params[:username]
		user.email = params[:email]
		user.password = params[:password]
		user.save

		redirect "/users/#{user.id}"
	else
		redirect '/users/new?alert_info=Please input same password in password and password confirmation'
	end
end

get "/confirm/:id" do

	change_state = FridgeUserRelationship.find_by(id: params[:id])
	change_state.relationship = 1 # sharer
	change_state.save
	redirect '/'
end

get '/users/:id' do
	@id = params[:id]
	redirect '/'
end

post '/session' do 
	#check email
	user = User.find_by(email: params[:email])

	#check password
	if user && user.authenticate(params[:password])
		# have a user and authenticate return truthy
		session[:user_id] = user.id #just a hash
	end
		redirect '/'
end

delete '/session' do
	session[:user_id] = nil
	redirect '/'
end


get '/fridges/new' do
	if logined_in?
		erb :new_fridge
	else
		redirect '/'
	end
end

get '/fridges/:id/share' do
	@fridge_id = params[:id]
	# return 'share'
	erb :new_sharer
end

post '/fridges/:id/share' do
	@fridge_id = params[:id]
	sharer = User.find_by(email: params[:email])
	if sharer && sharer.id != current_user.id then
		add_sharer = FridgeUserRelationship.new
		add_sharer.fridge_id = @fridge_id
		add_sharer.user_id = sharer.id
		add_sharer.relationship = 2 # pending
		# add_sharer.relationship = 1 # sharer
		add_sharer.save

		from = Email.new(email: 'hiby.90hou@gmail.com')
		to = Email.new(email: params[:email])
		subject = "#{current_user.username} invite you to share fridge"
		content = Content.new(type: 'text/html', value: 
			"<p>Your had been added to #{current_user.username}'s list.</p>
			 <p>Click <a href='http://localhost:4567/confirm/#{add_sharer.id}'><button>this button</button></a> to confirm.</p>")
		mail = Mail.new(from, subject, to, content)

		sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
		response = sg.client.mail._('send').post(request_body: mail.to_json)
		puts response.status_code
		puts response.body
		puts response.headers

	else
		redirect "/fridges/#{@fridge_id}/share"
	end

	redirect "/fridges/#{@fridge_id}"
end

get '/fridges/:id' do
	if logined_in? && right_user?(params[:id])
		@record_list = GoodsStore.where(["fridge_id = ?", params[:id].to_i])
		@fridge_id = params[:id]
		@goods_information = GoodsInfo.all

		erb :food_list
	else
		redirect '/'
	end
end

post '/fridges' do
  fridge = Fridge.new
  fridge.fridge_name = params[:fridge_name]
  fridge.fridge_location = params[:fridge_location]
  fridge.owner_id = current_user.id
	fridge.save

	fridge_user_re = FridgeUserRelationship.new
	fridge_user_re.fridge_id = fridge.id
	fridge_user_re.user_id = current_user.id
	fridge_user_re.relationship = 0 # owner
	fridge_user_re.save

	redirect '/'

end

delete '/delete_fridge/:id' do
	single_fridge = Fridge.find_by(id: params[:id])
	single_fridge.destroy
	redirect "/"
end

post '/add_food_item' do
	store_record = GoodsStore.new
	store_record.user_id = params[:user_id]
	store_record.fridge_id = params[:fridge_id]
	store_record.goods_id = params[:goods_id]
	store_record.goods_expire_date = params[:goods_expire_date]
	store_record.goods_quantity = params[:goods_quantity]
	store_record.save

	redirect "/fridges/#{params[:fridge_id]}"
end

delete '/delete_food_record/:id' do
	single_record = GoodsStore.find_by(id: params[:id])
	single_record.destroy
	redirect "/fridges/#{params[:fridge_id]}"
end

get '/change_food_record/:id' do
	@fridge_id = params[:fridge_id]
	@single_record = GoodsStore.find_by(id: params[:id])
	@goods_information = GoodsInfo.all
	# return @single_record.goods_id.to_json
	erb :change_food_record
end

put '/change_food_record/:id' do
	@single_record = GoodsStore.find_by(id: params[:id])
	# return @single_record.to_json
	@single_record.goods_id = params[:goods_id]
	@single_record.goods_expire_date = params[:goods_expire_date]
	@single_record.goods_quantity = params[:goods_quantity]
	@single_record.save
	redirect "/fridges/#{params[:fridge_id]}"
	end

