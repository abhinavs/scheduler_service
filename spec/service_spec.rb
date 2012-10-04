require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "service" do
  before(:each) do
    Job.delete_all
    @time_now     = Time.now
    @callback_url = "http://example.com/example"
    post '/jobs/new', {
        :callback_url  => @callback_url,
        :scheduled_for => @time_now }.to_json

    @job_id = Yajl::Parser.parse(last_response.body)["_id"]

  end

  describe "POST on /jobs/new" do
    it "should create a job" do
      last_response.should be_ok, last_response.body

      get "/jobs/#{@job_id}"
      attributes = Yajl::Parser.parse(last_response.body)
      Time.parse(attributes["scheduled_for"]).to_s.should  == @time_now.to_s
      attributes["callback_url"].should  == @callback_url
      attributes["locked"].should        == false
      attributes["locked_at"].should     == nil
      attributes["retries_count"].should == 0
      attributes["error"].should         == nil
      attributes["http_code"].should     == nil
    end
  end

  describe "GET on /jobs/:id" do
    it "should return a job by id" do
      get "/jobs/#{@job_id}"
      last_response.should be_ok, last_response.body
      attributes = Yajl::Parser.parse(last_response.body)
      Time.parse(attributes["scheduled_for"]).to_s.should  == @time_now.to_s
      attributes["callback_url"].should == @callback_url
      attributes["locked"].should        == false
      attributes["locked_at"].should     == nil
      attributes["retries_count"].should == 0
      attributes["error"].should         == nil
      attributes["http_code"].should     == nil
    end
  end

end
