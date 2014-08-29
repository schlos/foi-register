# encoding: UTF-8

class SessionsController < ApplicationController
  skip_before_filter :require_login, :except => [:change_password, :update_password]
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

  def change_password
    @staff_member = current_staff_member
  end

  def update_password
    @staff_member = current_staff_member

    @staff_member.password = params[:password]
    @staff_member.password_confirmation = params[:password_confirmation]

    if @staff_member.save
      redirect_to MySociety::Config::get("ADMIN_PREFIX", "/admin") + "/requests", :notice => "Password updated"
    else
      render "change_password"
    end
  end

  def logout
    session[:staff_member_id] = nil
    redirect_to MySociety::Config::get("ADMIN_PREFIX", "/admin") + "/sessions/new", :notice => "Logged out"
  end
end
