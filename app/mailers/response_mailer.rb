class ResponseMailer < ActionMailer::Base
  default :from => MySociety::Config.get("ORG_EMAIL")

  def email_response(response)
    @response = response
    @request = response.request
    confirmation_link = ConfirmationLink.create(:request_id => @request.id)
    @link_token = confirmation_link.token

    mail(:to => @request.email_for_response, :subject => "Re: " + @request.title)
  end
end
