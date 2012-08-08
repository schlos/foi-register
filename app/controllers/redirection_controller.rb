# encoding: UTF-8

class RedirectionController < ApplicationController
  skip_before_filter :require_login
  
  # The front page: redirect to the register list
  def front
    redirect_to :controller => 'requests', :action => 'index', :status => :moved_permanently
  end

  def admin
    redirect_to :controller => 'requests', :action => 'index', :status => :moved_permanently, :is_admin => "admin"
  end
end
