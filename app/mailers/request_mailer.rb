class RequestMailer < ActionMailer::Base
  default :from => MySociety::Config.get("ORG_EMAIL")
  default :subject => MySociety::Config.get("ACKNOWLEDGEMENT_SUBJECT")
  
  def notification(request)
    @notifications_to ||= MySociety::Config.get("NOTIFICATIONS_TO")
    @notification_subject ||= MySociety::Config.get("NOTIFICATION_SUBJECT")
    @request = request
    mail(:to => @notifications_to, :subject => @notification_subject)
  end
  
  def acknowledgement(request)
    @request = request
    mail(:to => @request.email_for_response)
  end
end
