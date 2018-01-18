require 'pry'
require_relative 'db_config'
# require 'sendgrid-ruby'
# include SendGrid

require_relative 'models/user'
require_relative 'models/fridge'
require_relative 'models/fridge_user_relationship'
require_relative 'models/goods_store'
require_relative 'models/goods_info'

# from = Email.new(email: 'test@example.com')
# to = Email.new(email: 'hiby.90hou@gmail.com')
# subject = 'Sending with SendGrid is Fun'
# content = Content.new(type: 'text/plain', value: 'and easy to do anywhere, even with Ruby')
# mail = Mail.new(from, subject, to, content)

# sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
# response = sg.client.mail._('send').post(request_body: mail.to_json)
# puts response.status_code
# puts response.body
# puts response.headers

# binding.pry