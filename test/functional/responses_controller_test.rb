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

  test "should not create a response when the request state is new" do
    response_attributes = @response_1.attributes
    response_attributes[:request_attributes] = {:state => "new"}
    assert_no_difference('Response.count') do
      post :create, :response => response_attributes, :request_id => @response_1.request_id
    end

    assert response.body =~ /State can&#x27;t be New/
  end

  test "should not create a response when the request state is changed " \
       "to assessing and the public_part is empty" do
    request = Request.find(requests(:overdue).id)
    response_attributes = @response_1.attributes
    response_attributes[:request_attributes] = {:state => "assessing"}
    response_attributes[:public_part] = ""

    assert_no_difference('Response.count') do
      post :create, :response => response_attributes, :request_id => request.id
    end

    request = Request.find(requests(:overdue).id)
    assert_equal(request.state, "assessing")
    assert_redirected_to requests_path(:is_admin => 'admin')
  end

  test "should create a response when the request state is changed " \
       "to assessing and the public_part is NOT empty" do
    request = Request.find(requests(:overdue).id)
    response_attributes = @response_1.attributes
    response_attributes[:request_attributes] = {:state => "assessing"}

    assert_difference('Response.count') do
      post :create, :response => response_attributes, :request_id => request.id
    end

    request = Request.find(requests(:overdue).id)
    assert_equal(request.state, "assessing")
    assert_redirected_to request_path(request, :is_admin => "admin")
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

  test "doesn't retry failed jobs" do
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

        # Check that it's not sent
        assert_equal 1, Delayed::Job.count
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

  test "should include private detail if the request was created by the app" do
    # this will have a stored remote_id
    ActionMailer::Base.deliveries = []
    response_4 = responses(:response_4)
    response_attributes = response_4.attributes
    response_attributes[:request_attributes] = {:state => "disclosed"}
    post :create, :response => response_attributes, :request_id => response_4.request_id

    found_response = false
    request = response_4.request
    expected_recipient = request.requestor.email
    expected_subject = "Re: " + request.title
    ActionMailer::Base.deliveries.each do |delivery|
      if delivery.subject == expected_subject
        found_response = true
        assert_equal delivery.to, [expected_recipient]
        assert_match /Please click on this link to provide feedback/, delivery.html_part.body.to_s
        assert_match /Please click on this link to provide feedback/, delivery.text_part.body.to_s
        assert_match /private part of response/, delivery.html_part.body.to_s
        assert_match /private part of response/, delivery.text_part.body.to_s
      end
    end
    assert found_response
  end

  test "should not include private detail if the request was imported from alaveteli" do
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
        assert_equal [expected_recipient], delivery.to
        assert_no_match /private part of response/, delivery.html_part.body.to_s
        assert_no_match /private part of response/, delivery.text_part.body.to_s
        assert_no_match /Please click on this link to provide feedback/, delivery.html_part.body.to_s
        assert_no_match /Please click on this link to provide feedback/, delivery.text_part.body.to_s
      end
    end
    assert found_response
  end

  test "should add the text 'Rejected as vexatious' if vexatious request submitted without response" do
    fake_response = Response.new
    vexatious_response = responses(:response_3)
    vexatious_response.public_part = nil
    response_attributes = vexatious_response.attributes
    response_attributes[:request_attributes] = {:state => "not_disclosed", :nondisclosure_reason => "rejected_vexatious"}

    Response.expects(:new).returns(fake_response)
    fake_response.stubs(:save).returns(true)
    fake_response.stubs(:send_to_alaveteli)
    fake_response.expects(:public_part=).with("Rejected as vexatious")

    post :create, :response => response_attributes, :request_id => vexatious_response.request_id
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
    # Upload the attachments in our fixture, so that the files really exist
    response_attributes = @response_1.attributes
    response_attributes['attachments_attributes'] = {}
    @response_1.attachments.each_with_index do |attachment, n|
      response_attributes['attachments_attributes'][n] = {'file' => fixture_file_upload("files/#{attachment['file']}", attachment['content_type'])}
    end
    put :update, :request_id => @response_1.request.id, :id => @response_1, :response => response_attributes

    # Reload the response and check the file has been uploaded
    @response_1.reload
    filename = @response_1.attachments[2].file.file.file.to_s
    assert File.exists?(filename)

    # Request to delete the file
    response_attributes = @response_1.attributes
    response_attributes['attachments_attributes'] = {0 => {:id => @response_1.attachments[2].id, :remove_file => '1' }}

    # Check the model was deleted
    assert_difference('Attachment.count', -1) do
      put :update, :request_id => @response_1.request.id, :id => @response_1, :response => response_attributes
    end

    # Check the file was deleted
    assert !File.exists?(filename)

    assert_redirected_to request_path(assigns(:response).request, :is_admin => 'admin')
  end

  test "should destroy response" do
    assert_difference('Response.count', -1) do
      delete :destroy, :request_id => @response_1.request.id, :id => @response_1
    end

    assert_redirected_to request_path(@response_1.request)
  end
end
