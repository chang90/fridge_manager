# Make sure you have Sinatra installed, then start sidekiq with
# sidekiq -r sinkiq.rb
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
    # clear repeatable task plan, in case there are some in the pass
    Sidekiq::ScheduledSet.new.select {|job| job.klass == self.class.name }.each(&:delete)

    run_schedule_works

    # when finish, give tomorrow's task
    SchedulePerMinuteWorker.perform_in(60*60*24)
  end

  # everyday run 1 times
  def run_schedule_works
    # TODO list
    puts "send email"
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

      user.goods_stores.each{|goods|
        email_content += "<li>food name: #{goods.goods_info.goods_name} food expire date: #{goods.goods_expire_date} fridge: #{goods.fridge.fridge_name}</li>"
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