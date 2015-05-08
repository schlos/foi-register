require 'test_helper'
require 'uri'

class HealthChecksControllerTest < ActionController::TestCase
  self.use_transactional_fixtures = true

  setup do
    # We don't want any requests in the DB because they'll confuse our testing
    Request.destroy_all
  end

  test "should be ok when all is ok" do
    # Create sufficient requests to pass all the tests
    Request.create(
      :due_date => Time.now + 5.days,
      :title => 'Created today, from alaveteli',
      :requestor => requestors(:seb),
      :body => 'Created today, from alaveteli',
      :is_published => true,
      :remote_id => 42,
      :created_at => Time.now,
      :medium => 'alaveteli'
    )

    get :index
    assert_response :success
  end

  test "should not be ok when no requests have been created in 3 days" do
    # Create an old request
    Request.create(
      :due_date => Time.now + 5.days,
      :title => 'Created today, from alaveteli',
      :requestor => requestors(:seb),
      :body => 'Created today, from alaveteli',
      :is_published => true,
      :remote_id => 42,
      :created_at => Time.now - 4.days,
      :medium => 'alaveteli'
    )

    get :index
    assert_response :error
    assert response.body.include? "The last request was created over 3 days ago"
  end

  test "should not be ok when there are no requests from alaveteli" do
    # Create a request to pass the creation test, but that's not from alaveteli
    Request.create(
      :due_date => Time.now + 5.days,
      :title => 'Created today, from alaveteli',
      :requestor => requestors(:seb),
      :body => 'Created today, from alaveteli',
      :remote_id => 42,
      :created_at => Time.now
    )

    get :index
    assert_response :error
    assert response.body.include? "The last request from alaveteli was created over 14 days ago"
  end

  test "should not be ok when there are failed jobs" do
    # Create a request to pass the creation test
    Request.create(
      :due_date => Time.now + 5.days,
      :title => 'Created today, from alaveteli',
      :requestor => requestors(:seb),
      :body => 'Created today, from alaveteli',
      :remote_id => 42,
      :created_at => Time.now,
      :medium => 'alaveteli'
    )

    # Mock delayed_job to say that there's a failed job
    mock_result = mock()
    mock_failed_job = mock()
    mock_result.stubs(:first).returns(mock_failed_job)
    Delayed::Job.stubs(:where).returns(mock_result)

    get :index
    assert_response :error
    assert response.body.include? "There are failed delayed jobs"
  end

  test "should not be ok when there are requests that haven't been sent to alaveteli" do
    # Create a request to pass the creation test
    Request.create(
      :due_date => Time.now + 5.days,
      :title => 'Created today, from alaveteli',
      :requestor => requestors(:seb),
      :body => 'Created today, from alaveteli',
      :remote_id => 42,
      :created_at => Time.now,
      :medium => 'alaveteli'
    )

    # Create a request to fail the sent to alaveteli test
    Request.create(
      :due_date => Time.now + 5.days,
      :title => 'Created today, from alaveteli',
      :requestor => requestors(:seb),
      :body => 'Created today, from alaveteli',
      :is_published => true,
      :remote_id => nil,
      :created_at => Time.now - 2.hours
    )

    get :index
    assert_response :error
    assert response.body.include? "There are requests which haven&#x27;t been sent to Alaveteli in over an hour"
  end
end
