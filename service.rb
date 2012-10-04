require 'rubygems'
require 'sinatra'
require 'mongoid'
require 'models/job'
require 'yajl'

configure do
  # Mongoid.load!("config/mongoid.yml")
  Mongoid.configure do |config|
    name = "scheduler_development"
    host = "localhost"
    config.master = Mongo::Connection.new.db(name)
  end
end

before { content_type :json }

post '/jobs/new' do
  begin
     job = Job.new(Yajl::Parser.parse(request.body.read))
     if job.save
      job.to_json
    else
      error 400, job.errors.to_json
    end
  rescue => e
    error 500, e.message.to_json
  end
end

get '/jobs/:id' do
  job = Job.find(params[:id])
  if job
    job.to_json
  else
    error 404, {:error => "job not found"}.to_json
  end
end
