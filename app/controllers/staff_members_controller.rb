# encoding: UTF-8

class StaffMembersController < ApplicationController
  http_basic_authenticate_with :name => "admin", :password => MySociety::Config::get("ADMIN_PASSWORD")
  skip_before_filter :require_login # because we protect with Basic HTTP Auth instead
  
  def new
    @staff_member = StaffMember.new
  end
  
  def create
    @staff_member = StaffMember.new(params[:staff_member])
    if @staff_member.save
      redirect_to MySociety::Config::get("ADMIN_PREFIX", "/admin") + "/staff_members", :notice => "Created new staff member <#{@staff_member.email}>"
    else
      render "new"
    end
  end
  
  def index
    @staff_members = StaffMember.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @staff_members }
    end
  end
  
  def edit
    @staff_member = StaffMember.find(params[:id])
  end
  def update
    @staff_member = StaffMember.find(params[:id])

    respond_to do |format|
      if @staff_member.update_attributes(params[:staff_member])
        format.html { redirect_to MySociety::Config::get("ADMIN_PREFIX", "/admin") + "/staff_members", :notice => "Staff member <#{@staff_member}> was successfully updated." }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @state.errors, :status => :unprocessable_entity }
      end
    end
  end
  def destroy
    @staff_member = StaffMember.find(params[:id])
    @staff_member.destroy

    respond_to do |format|
      format.html { redirect_to staff_members_url, :notice => "Staff member <#{@staff_member}> was successfully deleted." }
      format.json { head :no_content }
    end
  end
end
