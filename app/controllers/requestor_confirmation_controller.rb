# encoding: UTF-8

class RequestorConfirmationController < ApplicationController
  skip_before_filter :require_login
  before_filter :confirm_token

  # GET /c/:token
  def show
    @states = Request::STATES.delete_if{|state, _| state[0] == "new"}
  end

  # POST /c/:token
  def set_response
    @request.requestor_state = params[:state]
    @request.save
    @conf.expired = true
    @conf.save
    # TODO call the status API
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