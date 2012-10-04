require 'mongoid'

class Job
  include Mongoid::Document
  include Mongoid::Timestamps

  COLLECTION_NAME = Job.collection.name
  BATCH_SIZE      = 20
  MAX_RETRIES     = 3
  TIMED_OUT       = "timed_out"

  field :callback_url,  :type => String
  field :scheduled_for, :type => DateTime
  field :locked,        :type => Boolean
  field :locked_at,     :type => DateTime
  field :retries_count, :type => Integer
  field :error,         :type => String
  field :http_code,     :type => Integer

  index [:locked, :retries_count], :background => true

  attr_protected        :locked, :locked_at, :error, :http_code, :retries_count
  validates_presence_of :callback_url
  validates_format_of   :callback_url, :with => /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix, :on => :create
  before_create         :set_essential_attributes

  scope :next_batch, lambda { where(:scheduled_for.lte => Time.now, :locked => false, :retries_count.lt => MAX_RETRIES).limit(BATCH_SIZE) }

  def self.db_time_now
    Time.now.utc
  end

  def self.reserve!
    time_now    = db_time_now
    begin
      result = self.db.collection(COLLECTION_NAME).find_and_modify(
                :query  => {:scheduled_for => {"$lte" => time_now}, :locked => false, :retries_count => {"$lt" => Job::MAX_RETRIES}},
                :update => {"$set" => {:locked_at => time_now, :locked => true}}
                )
      result.present? ? self.find(result["_id"]) : nil
    rescue Mongo::OperationFailure
      nil
    end
  end

  def capture_error!(response)
    unless response.code.to_s =~ /^20./
      if response.timed_out?
        self.error = TIMED_OUT
      elsif response.code == 0
        self.error = response.curl_error_message
      else
        self.error = response.body
      end

      self.http_code      = response.code
      self.locked_at      = nil
      self.locked         = false
      self.retries_count  = retries_count + 1
      save!
    end
  end

  def error?
    error.present? || http_code >= 300
  end

  private

  def set_essential_attributes
    self.scheduled_for = Time.now if scheduled_for.blank?
    self.retries_count = 0
    self.locked        = false
    self.locked_at     = nil
    self.error         = nil
    self.http_code     = nil
  end

end
