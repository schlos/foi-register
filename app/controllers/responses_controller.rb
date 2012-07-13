# encoding: UTF-8

class ResponsesController < ApplicationController
  skip_before_filter :require_login, :only => [:index, :show]

  # GET /responses
  # GET /responses.json
  def index
    @request = Request.find(params[:request_id])
    @responses = @request.responses

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @responses }
    end
  end

  # GET /responses/1
  # GET /responses/1.json
  def show
    @response = Response.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @response }
    end
  end

  # GET /responses/1/edit
  def edit
    @response = Response.find(params[:id])
  end

  # POST /responses
  # POST /responses.json
  def create
    request = Request.find(params[:request_id])
    @response = Response.new(params[:response])
    @response.request = request
    
    respond_to do |format|
      if @response.save
        format.html { redirect_to [request, @response], :notice => 'Response was successfully created.' }
        format.json { render :json => @response, :status => :created, :location => @response }
      else
        format.html { render :action => "new" }
        format.json { render :json => @response.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /responses/1
  # PUT /responses/1.json
  def update
    @response = Response.find(params[:id])
    attachments_attributes = params[:response][:attachments_attributes]
    if !attachments_attributes.nil?
      attachments_attributes.each do |k,v|
        if v["remove_file"] == "1"
          Attachment.delete(v["id"])
          attachments_attributes.delete(k)
        end
      end
      params[:response][:attachments_attributes] = attachments_attributes
    end
    respond_to do |format|
      if @response.update_attributes(params[:response])
        format.html { redirect_to @response.request, :notice => 'Response was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @response.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /responses/1
  # DELETE /responses/1.json
  def destroy
    @response = Response.find(params[:id])
    @response.destroy

    respond_to do |format|
      format.html { redirect_to request_responses_url(@response.request) }
      format.json { head :no_content }
    end
  end
end
