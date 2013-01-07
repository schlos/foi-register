class RequestMailer < ActionMailer::Base
  helper :application
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

  def takedown_notification(request, explanation)
    @remote_takedowns_to ||= MySociety::Config.get("ALAVETELI_ADMIN_EMAIL")
    @remote_takedown_subject ||= MySociety::Config.get("ALAVETELI_TAKEDOWN_SUBJECT")

    @request = request
    @explanation = explanation
    mail(:to => @remote_takedowns_to, :subject => @remote_takedown_subject)
  end
end
