# == Schema Information
#
# Table name: requests
#
#  id                        :integer          not null, primary key
#  title                     :string(255)      not null
#  requestor_id              :integer          not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  body                      :text             not null
#  date_received             :date
#  due_date                  :date             not null
#  lgcs_term_id              :integer
#  is_published              :boolean          default(TRUE), not null
#  is_requestor_name_visible :boolean          default(FALSE), not null
#  medium                    :string(255)      default("web"), not null
#  remote_id                 :integer
#  remote_url                :string(255)
#  state                     :string(255)      default("new"), not null
#  nondisclosure_reason      :string(255)
#  remote_email              :string(255)
#  top_level_lgcs_term_id    :integer
#

require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  test "automatic assignment of top_level_lgcs_term" do
    r = requests(:badgers)

    # Check that the values in the fixture are what we expect
    assert_equal "Animal control", r.lgcs_term_name
    assert_nil r.top_level_lgcs_term

    # Check that saving the term sets the top-level term correctly
    r.save
    assert_equal r.top_level_lgcs_term.name, "Consumer affairs"

    # Now test that unsetting the lgcs_term unsets the top-level term
    r.lgcs_term = nil
    r.save
    assert_nil r.top_level_lgcs_term
  end

  test 'should return the requestor name when asked for public requestor name if requestor name is visible' do
    requestor = Requestor.new(:name => 'A test name')
    request = Request.new(:is_requestor_name_visible => true,
                          :requestor => requestor)
    assert_equal 'A test name', request.public_requestor_name
  end

  test 'should return nil when asked for public requestor name if requestor name is not visible' do
    requestor = Requestor.new(:name => 'A test name')
    request = Request.new(:is_requestor_name_visible => false,
                          :requestor => requestor)
    assert_nil request.public_requestor_name
  end

end
