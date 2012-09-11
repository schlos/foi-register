class RequestMailer < ActionMailer::Base
  default :from => MySociety::Config.get("ORG_EMAIL")
  default :subject => MySociety::Config.get("ACKNOWLEDGEMENT_SUBJECT")
  
  def acknowledgement(request)
    @request = request
    mail(:to => @request.email_for_response)
  end
end
