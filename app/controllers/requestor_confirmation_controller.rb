# encoding: UTF-8

class RequestorConfirmationController < ApplicationController
  skip_before_filter :require_login
  before_filter :confirm_token

  # GET /c/:token
  def show
    @states = Request::STATES.clone.delete_if do |state, _|
      !Request::CLOSED_STATES.include?(state)
    end
  end

  # POST /c/:token
  def set_response
    @request.requestor_state = params[:state]
    @request.save
    AlaveteliApi.status_update(@request)
    @conf.expired = true
    @conf.save
  end

  protected

  def confirm_token
    begin
      @conf = ConfirmationLink.find_by_token(params[:token])
      @request = @conf.request
      if @conf.nil? or @conf.request.nil? or @conf.expired
        redirect_to :root
      end
    rescue
      redirect_to :root
    end
  end
end