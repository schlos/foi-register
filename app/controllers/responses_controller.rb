# encoding: UTF-8

class ResponsesController < ApplicationController
  skip_before_filter :require_login, :only => [:index, :show, :letter]

  # GET /request/:request_id/responses/:id/edit
  def edit
    @response = Response.find(params[:id])
    @request = @response.request
  end

  # POST /request/:request_id/responses
  # POST /request/:request_id/responses.json
  def create
    @request = Request.find(params[:request_id])
    response = params[:response]
    request_attributes = response.delete(:request_attributes)
    @response = Response.new(response)
    @response.request = @request

    @request.state = request_attributes[:state]
    if request_attributes.has_key? :nondisclosure_reason
      @request.nondisclosure_reason = request_attributes[:nondisclosure_reason]
    end
    @request.save!

    respond_to do |format|
      if @response.save
        @response.send_to_alaveteli
        @response.send_by_email

        format.html { redirect_to request_path(@request, :is_admin => "admin"),
                                  :notice => 'Response was successfully created.' }
        format.json { render :json => @response, :status => :created, :location => @response }
      else
        format.html {
          render "edit"
        }
        format.json { render :json => @response.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /request/:request_id/responses/:id
  # PUT /request/:request_id/responses/:id.json
  def update
    @response = Response.find(params[:id])
    @request = @response.request

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
        format.html { redirect_to request_path(@response.request, :is_admin => 'admin'),
                                  :notice => 'Response was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @response.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /request/:request_id/responses/:id
  # DELETE /request/:request_id/responses/:id.json
  def destroy
    @response = Response.find(params[:id])
    @response.destroy

    respond_to do |format|
      format.html { redirect_to request_url(@response.request) }
      format.json { head :no_content }
    end
  end

  # GET /request/:request_id/responses/:id/letter.pdf
  def letter
    @response = Response.find(params[:id])
    @request = @response.request
    @requestor = @request.requestor

    respond_to do |format|
      format.pdf { @response }
    end
  end
end
