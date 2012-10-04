require 'rubygems'
require 'mongoid'
require 'typhoeus'
require 'logger'
require File.expand_path(File.dirname(__FILE__) + '/../models/job')

@logger         = Logger.new("/tmp/scheduler_#{Process.pid}.log")
exit_requested  = false
Kernel.trap( "INT" ) { exit_requested = true }

DEBUG           = true
MAX_CONCURRENCY = 10
TIME_OUT        = 10000 # milliseconds

hydra           = Typhoeus::Hydra.new(:max_concurrency => MAX_CONCURRENCY)
hydra.disable_memoization

Mongoid.configure do |config|
  name          = "scheduler_development"
  host          = "localhost"
  config.master = Mongo::Connection.new.db(name)
end

def log_msg(msg)
  puts msg if DEBUG
  @logger.info msg
end

i= 1
loop do
  locked_jobs = []

  1.upto(Job::BATCH_SIZE) do |i|
    job = Job.reserve!
    job.present? ? locked_jobs.push(job) : break
  end

  locked_jobs.each do |job|

    request = Typhoeus::Request.new(job.callback_url, :timeout => TIME_OUT)

    request.on_complete do |response|
      if response.success? && response.code.to_s =~ /^20./
        log_msg "finished job##{i} #{job.callback_url}|#{job.id}"
        job.delete
      else
        log_msg "failed job##{i} #{job.callback_url}|#{job.id}"
        job.capture_error!(response)
      end
      i = i+1
    end

    hydra.queue(request)
  end

  hydra.run if locked_jobs.size > 0
  break     if exit_requested

end

puts "\nexiting!"
