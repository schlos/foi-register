class ResponseMailer < ActionMailer::Base
  default :from => MySociety::Config.get("ORG_EMAIL")

  def email_response(response)
    @response = response
    @request = response.request

    # send a notification that the request has been closed by the council
    # if a closing response has been sent, otherwise send a status update
    if @request.is_closed?
      confirmation_link = ConfirmationLink.create(:request_id => @request.id)
      @link_token = confirmation_link.token
      template_name = :email_response
    else
      template_name = :email_update
    end

    mail(:to => @request.email_for_response, :subject => "Re: " + @request.title) do |format|
      format.html { render template_name }
      format.text { render template_name }
    end
  end
end
