require 'sinatra'
# require 'sinatra/reloader'
# require 'pry'

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

	def fridge_owner?(fridge_id)
		# find out who own this fridge
		return user_id_arr = !(FridgeUserRelationship.where(["fridge_id = ?", fridge_id.to_s]).where(relationship: ["0", "1"]).empty?)
	end

	def goods_owner?(user_id,goods_info_id)
		if GoodsStore.where(id: goods_info_id.to_i).where(user_id: user_id.to_i).empty?
			return false
		else
			return true
		end
	end

	def fridge_is_empty?(fridge_id)
		fridge = GoodsStore.find_by(fridge_id: fridge_id.to_s)
		return !fridge
	end

	def get_user_name(user_id)
		user_name = User.find_by(id: user_id)
		return user_name.username
	end

	def today
		today = Time.now.strftime('%Y-%m-%d')
	end

	def guess_expire_date(expire_period)
		guess_expire_date = (Time.now + 3600 * 24 * (expire_period).to_i).strftime('%Y-%m-%d')
	end

	def own_fridge_list(user_id)
		return own_fridge_detail_list = Fridge.joins(:fridge_user_relationships).where("fridge_user_relationships.relationship = ? and fridge_user_relationships.user_id = ?","0",user_id)
	end

	def share_fridge_list(user_id)
		return share_fridge_detail_list = Fridge.joins(:fridge_user_relationships).where("fridge_user_relationships.relationship = ? and fridge_user_relationships.user_id = ?","1",user_id)
	end

	def signup_alert(alert_name)
		alert_arr = {
		"password_nomatch"=>"Please input same password in password and password confirmation",
		"password_short"=>"Please input at least 6 letters in password",
		"email-wrong"=>"Please input a valid email address"
		}
		return alert_arr[alert_name]
	end
	
	def is_food_list_page?
		return !!(request.path_info =~ /\/fridges\/(.*)/)
	end
end

get '/' do

	if logined_in?
		@own_fridge_detail_list = own_fridge_list(current_user.id)
		@share_fridge_detail_list = share_fridge_list(current_user.id)
	end

  erb :index
end

get '/users/new' do
	@alert = params[:alert_info]
	erb :signup
end

post '/users' do
	if params[:password] != params[:password_confirmation]
		redirect "/users/new?alert_info=#{signup_alert("password_nomatch")}"
	elsif params[:password].length < 6
		redirect "/users/new?alert_info=#{signup_alert("password_short")}"
	elsif (!!User.find_by(email:params[:email]))
		redirect "/users/new?alert_info=#{signup_alert("email-wrong")}"
	else	
		user = User.new
		user.username = params[:username]
		user.email = params[:email]
		user.password = params[:password]
		user.save
		session[:user_id] = user.id

		redirect "/users/#{user.id}"
	end
end

get "/confirm/:id" do

	# clean all kinds of expired record in FridgeUserRelationship table
	expired_record = FridgeUserRelationship.where(relationship: '2').where(["request_expire_date < ?",Time.now.strftime('%Y-%m-%d')])
	FridgeUserRelationship.delete(expired_record)

	change_state = FridgeUserRelationship.find_by(id: params[:id])
	if change_state
		change_state.relationship = 1 # sharer
		change_state.save
		redirect '/'
	else
		erb :confirm_error
	end
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
	@alert = nil
	if params[:info] == 'msg_already_send'
		@alert = "Your request is already send, please do not send again within 24 hours!"
	end
	# return 'share'
	erb :new_sharer
end

post '/fridges/:id/share' do
	@fridge_id = params[:id]
	sharer = User.find_by(email: params[:email])
	if sharer && sharer.id != current_user.id then

		if FridgeUserRelationship.where(["fridge_id = ? and user_id = ?", @fridge_id, "1"]).where.not(relationship: '0').length > 0
			redirect "/fridges/#{@fridge_id}/share?info=msg_already_send"
			return
		end

		add_sharer = FridgeUserRelationship.new
		add_sharer.fridge_id = @fridge_id
		add_sharer.user_id = sharer.id
		add_sharer.relationship = 2 # pending
		# add_sharer.relationship = 1 # sharer
		add_sharer.request_expire_date = (Time.now + 3600 * 24).strftime('%Y-%m-%d')
		add_sharer.save

		# send email
		fridge_name = Fridge.find_by(id: @fridge_id).fridge_name
		from = Email.new(email: 'hiby.90hou@gmail.com')
		to = Email.new(email: params[:email])
		subject = "#{current_user.username} invite you to share fridge"
		content = Content.new(type: 'text/html', value: 
			"<p>Your had been added to #{current_user.username}'s fridge #{fridge_name}.</p>
			 <p>Click <a href='https://cryptic-ocean-77629.herokuapp.com/confirm/#{add_sharer.id}'><button>this button</button></a> to confirm.</p>
			 <p>note: this link will be expired after 24 hours.</p>")
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
	if logined_in? && fridge_owner?(params[:id])
		# @record_list = GoodsStore.where(["fridge_id = ?", params[:id].to_i])
		@fridge_id = params[:id]
		@fridge_name = Fridge.find_by(id: @fridge_id).fridge_name
		@goods_information = GoodsInfo.all
		@record_list = GoodsStore.includes(:goods_info).where(["goods_stores.fridge_id = ?",params[:id]]).sort_by {|record| record.id}

		if params[:sort] == "by_expire_date"
			@record_list = @record_list.sort_by {|record| record.goods_expire_date}
		elsif params[:sort] == "by_user"
			record_self_list = @record_list.where(user_id: current_user.id)
			record_last_list = @record_list.where.not(user_id: current_user.id).sort_by {|record| record.user_id}
			# binding.pry
			@record_list = record_self_list + record_last_list

		end 
		erb :food_list
	else
		redirect '/'
	end
end

post '/fridges' do
  fridge = Fridge.new
  fridge.fridge_name = params[:fridge_name]
  fridge.fridge_location = params[:fridge_location]
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
	store_record.goods_info_id = params[:goods_id]
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
	@single_record.goods_info_id = params[:goods_info_id]
	@single_record.goods_expire_date = params[:goods_expire_date]
	@single_record.goods_quantity = params[:goods_quantity]
	@single_record.save
	redirect "/fridges/#{params[:fridge_id]}"
end

put '/change_share_state/:id' do
	@single_record = GoodsStore.find_by(id: params[:id])
	@single_record.goods_share_state = !@single_record.goods_share_state
	@single_record.save
	redirect "/fridges/#{params[:fridge_id]}"
end

get '/ajax/expire_date' do
	expire_period = GoodsInfo.find_by(id: params[:goods_id]).recommend_expire_period
	return guess_expire_date(expire_period)
end