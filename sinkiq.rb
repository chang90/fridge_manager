# Make sure you have Sinatra installed, then start sidekiq with
# ./bin/sidekiq -r ./examples/sinkiq.rb
# Simply run Sinatra with
# ruby examples/sinkiq.rb
# and then browse to http://localhost:4567
#
require 'bundler/setup'
require 'sinatra'
require 'sidekiq'
require 'redis'
require 'sidekiq/api'

require 'sendgrid-ruby'
include SendGrid

require_relative 'db_config'
require_relative 'models/goods_store'
require_relative 'models/user'
require_relative 'models/goods_info'
require_relative 'models/fridge'

Bundler.require(:default)

$redis = Redis.new

class SchedulePerMinuteWorker
  include Sidekiq::Worker

  def perform
    # 清除重复的任务计划
    Sidekiq::ScheduledSet.new.select {|job| job.klass == self.class.name }.each(&:delete)

    run_schedule_works

    # 结束时将自己推入
    SchedulePerMinuteWorker.perform_in(60*60*24)
  end

  # 每分钟执行的任务
  def run_schedule_works
    # TODO 业务逻辑
    puts "repeat"
    user_list = User.includes(:goods_stores).where('goods_stores.goods_expire_date < ?', Time.now.strftime("%Y-%m-%d")).references(:goods_stores)


    user_list.each{|user|
      if user.goods_stores.length == 0
        next
      end

      email_content = ""
      email_content += "<h1>Alert! Some Item in Your Fridge were expired</h1>"
      email_content += "<p>Hello #{user.username}</p>"
      email_content += "<p>The following item in your fridge is expired</p>"
      email_content += "<ul>"
      # puts "Hello #{user.username}"
      # puts "The following item in your fridge is expired"
      user.goods_stores.each{|goods|
        email_content += "<li>food name: #{goods.goods_info.goods_name} food expire date: #{goods.goods_expire_date} fridge: #{goods.fridge.fridge_name}</li>"
        # puts "food name: #{goods.goods_info.goods_name} food expire date: #{goods.goods_expire_date} "
        # puts "fridge: #{goods.fridge.fridge_name}"
      }
      email_content += "</ul>"
      puts email_content

      from = Email.new(email: 'hiby.90hou@gmail.com')
      to = Email.new(email: user.email)
      subject = "Alert! Some Item in Your Fridge were expired"
      content = Content.new(type: 'text/html', value: email_content)
      mail = Mail.new(from, subject, to, content)

      sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      puts response.status_code
      puts response.body
      puts response.headers
    }

  end
end

SchedulePerMinuteWorker.perform_async

# class SinatraWorker
#   include Sidekiq::Worker

#   def perform(msg="lulz you forgot a msg!")
#     $redis.lpush("sinkiq-example-messages", msg)
#   end
# end

# get '/' do
#   stats = Sidekiq::Stats.new
#   @failed = stats.failed
#   @processed = stats.processed
#   @messages = $redis.lrange('sinkiq-example-messages', 0, -1)
#   erb :index
# end

# post '/msg' do
#   SinatraWorker.perform_in(3, params[:msg])
#   # SinatraWorker.perform_async params[:msg]
#   redirect to('/')
# end

# __END__

# @@ layout
# <html>
#   <head>
#     <title>Sinatra + Sidekiq</title>
#     <body>
#       <%= yield %>
#     </body>
# </html>

# @@ index
#   <h1>Sinatra + Sidekiq Example</h1>
#   <h2>Failed: <%= @failed %></h2>
#   <h2>Processed: <%= @processed %></h2>

#   <form method="post" action="/msg">
#     <input type="text" name="msg">
#     <input type="submit" value="Add Message">
#   </form>

#   <a href="/">Refresh page</a>

#   <h3>Messages</h3>
#   <% @messages.each do |msg| %>
#     <p><%= msg %></p>
#   <% end %>
