# encoding: UTF-8

class SessionsController < ApplicationController
  skip_before_filter :require_login
  skip_before_filter :require_login_based_on_url

  def new
  end

  def create
    staff_member = StaffMember.find_by_email(params[:email])
    if staff_member && staff_member.authenticate(params[:password])
      session[:staff_member_id] = staff_member.id
      redirect_to MySociety::Config::get("ADMIN_PREFIX", "/admin") + "/requests", :notice => "Logged in"
    else
      flash[:notice] = "Invalid email or password"
      render "new"
    end
  end

  def logout
    session[:staff_member_id] = nil
    redirect_to MySociety::Config::get("ADMIN_PREFIX", "/admin") + "/sessions/new", :notice => "Logged out"
  end
end
