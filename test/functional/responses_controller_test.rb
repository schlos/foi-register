require 'test_helper'
require 'uri'

class ResponsesControllerTest < ActionController::TestCase

  setup do
    @response_1 = responses(:response_1)
    session[:staff_member_id] = staff_members(:phil).id
  end

  test "should create response" do
    response_attributes = @response_1.attributes
    response_attributes[:request_attributes] = {:state => "disclosed"}
    assert_difference('Response.count') do
      post :create, :response => response_attributes, :request_id => @response_1.request_id
    end

    assert_redirected_to request_path(@response_1.request, :is_admin => "admin")
  end

  test "should set the request state when creating a response" do
    response_attributes = @response_1.attributes
    response_attributes[:request_attributes] = {:state => "disclosed"}
    assert_difference('Response.count') do
      post :create, :response => response_attributes, :request_id => @response_1.request_id
    end

    req = Request.find(requests(:all_your_info).id)
    assert_equal(req.state, "disclosed")
    assert_redirected_to request_path(@response_1.request, :is_admin => "admin")
  end

  # Wrapper for tests that need an Alaveteli connection
  def with_alaveteli
    config = MySociety::Config.load_default()
    host = config['TEST_ALAVETELI_API_HOST']
    if host.nil?
      $stderr.puts "WARNING: skipping Alaveteli integration test.  Set `TEST_ALAVETELI_API_HOST` to run"
    else
      endpoint = "#{host}/api/v2"
      config['ALAVETELI_API_ENDPOINT'] = endpoint
      config['ALAVETELI_API_KEY'] = '3'

      begin
        yield host
      rescue Errno::ECONNREFUSED => e
        raise "TEST_ALAVETELI_API_HOST set in test.yml but no Alaveteli server running"
      ensure
        config['ALAVETELI_API_ENDPOINT'] = nil
      end
    end
  end

  test "should publish a response to Alaveteli endpoint" do
    with_alaveteli do |host|
      # first we need to create a new request, so we have a remote_id to respond to...
      @response_1.request.send_to_alaveteli

      response_attributes = @response_1.attributes
      response_attributes['attachments_attributes'] = {}
      response_attributes[:request_attributes] = {:state => "disclosed"}

      @response_1.attachments.each_with_index do |attachment, n|
        response_attributes['attachments_attributes'][n] = {'file' => fixture_file_upload("files/#{attachment['file']}", attachment['content_type'])}
      end
      post :create, :response => response_attributes, :request_id => @response_1.request.id
      result = open("#{host}/request/#{@response_1.request.remote_id}").read
      assert result =~ /#{@response_1.public_part}/, "#{result} did not contain #{@response_1.public_part}"
      # The following tests have the condition hard coded because
      # the filenames are munged in the Alaveteli display area using
      # code that would otherwise need refactoring
      assert result =~ /attachment%201.txt/
      assert result =~ /attachment%202.pdf/
      assert_redirected_to request_path(@response_1.request, :is_admin => "admin")
    end
  end

  def with_delayed_jobs
      prev_delay_jobs = Delayed::Worker.delay_jobs
      Delayed::Worker.delay_jobs = true
      begin
        # Make failed jobs retry instantly
        # NOTE: this means that if you call work_off with no limit and a job fails, it will keep
        #       retrying till the retry limit is reached. We avoid this by explicitly calling
        #       work_off 1 when we are expecting a job to fail.
        Delayed::PerformableMethod.any_instance.stubs(:reschedule_at).with(:time, :attempts) do |time, attempts|
          time
        end
        yield
      ensure
        Delayed::Worker.delay_jobs = prev_delay_jobs
        Delayed::PerformableMethod.any_instance.unstub(:reschedule_at)
      end
  end

  test "should retry later if Alaveteli is down" do
    with_alaveteli do |host|
      with_delayed_jobs do
        # Make sure the queue is clear to start with
        assert_equal 0, Delayed::Job.count

        # Pretend Alaveteli is down
        AlaveteliApi.stubs(:send_request).raises(AlaveteliApi::AlaveteliApiError)

        # Try to send a request there
        @response_1.request.send_to_alaveteli

        # Run the job queue, and check it fails
        assert_equal 1, Delayed::Job.count
        Delayed::Worker::new.work_off 1 # expect this job to fail
        assert_equal 1, Delayed::Job.count

        # Now bring Alaveteli back up, and try again
        AlaveteliApi.unstub(:send_request)
        Delayed::Worker::new.work_off 1

        # Check that worked
        assert_equal 0, Delayed::Job.count
      end
    end
  end

  test "should send response by email" do
    ActionMailer::Base.deliveries = []
    response_attributes = @response_1.attributes
    response_attributes[:request_attributes] = {:state => "disclosed"}
    post :create, :response => response_attributes, :request_id => @response_1.request_id

    found_response = false
    request = @response_1.request
    expected_recipient = request.requestor.email
    expected_subject = "Re: " + request.title
    ActionMailer::Base.deliveries.each do |delivery|
      if delivery.subject == expected_subject
        found_response = true
        assert_equal delivery.to, [expected_recipient]
      end
    end
    assert found_response
  end

  test "should get edit" do
    get :edit, :request_id => @response_1.request.id, :id => @response_1
    assert_response :success
  end

  test "should update response" do
    put :update, :request_id => @response_1.request.id, :id => @response_1, :response => @response_1.attributes
    assert_redirected_to request_path(assigns(:response).request, :is_admin => 'admin')
  end

  test "should destroy attachment" do
    # Upload the attachments in our fixture, so that they go somewhere
    response_attributes = @response_1.attributes
    response_attributes['attachments_attributes'] = {}
    files = {}
    @response_1.attachments.each_with_index do |attachment, n|
      attachment.destroy
      files[n] = fixture_file_upload("files/#{attachment['file']}", attachment['content_type'])
      response_attributes['attachments_attributes'][n] = {'file' => files[n]}
    end
    put :update, :request_id => @response_1.request.id, :id => @response_1, :response => response_attributes

    @response_1 = Response.find(@response_1.id)
    puts @response_1.attachments
    attachment = @response_1.attachments[0]
    assert_equal true, File.exists?(files[0])

    # Signal that we want to delete an attachment
    response_attributes['attachments_attributes'] = {0 => {:id => attachment.id, :remove_file => '1' }}

    assert_difference('Attachment.count', -1) do
      put :update, :request_id => @response_1.request.id, :id => @response_1, :response => response_attributes
    end
    assert_equal false, File.exists?(files[0])
    assert_redirected_to request_path(assigns(:response).request, :is_admin => 'admin')
  end

  test "should destroy response" do
    assert_difference('Response.count', -1) do
      delete :destroy, :request_id => @response_1.request.id, :id => @response_1
    end

    assert_redirected_to request_path(@response_1.request)
  end
end
