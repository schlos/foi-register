# encoding: UTF-8

class ResponsesController < ApplicationController
  skip_before_filter :require_login, :only => [:index, :show, :letter]

  # GET /request/:request_id/responses/:id/edit
  def edit
    @response = Response.find(params[:id])
    @request = @response.request
    @request_states = Request::STATES.dup
  end

  # POST /request/:request_id/responses
  # POST /request/:request_id/responses.json
  def create
    @request = Request.find(params[:request_id])
    @request_states = Request::STATES.dup

    response = params[:response]
    request_attributes = response.delete(:request_attributes)

    # if the state is being changed to "assessing" and response sending is not expected
    if @request.state != "assessing" and request_attributes[:state] == "assessing" and response[:public_part].blank?
      @request.state = "assessing"
      @request.save
      respond_to do |format|
        format.html { redirect_to requests_path(:is_admin => "admin"),
                                  :notice => "Request #{@request.administrative_id} flagged as Assessing (no response sent)" }
      end
      return
    end

    @request.state = request_attributes[:state]
    @response = Response.new(response)
    @response.request = @request

    if request_attributes.has_key? :nondisclosure_reason
      @request.nondisclosure_reason = request_attributes[:nondisclosure_reason]
      if @request.nondisclosure_reason == "rejected_vexatious"
        if @response.public_part.nil? or @response.public_part.empty?
          @response.public_part = "Rejected as vexatious"
        end
      end
    end

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
          attachment = Attachment.find(v["id"])
          attachment.file.remove!
          attachment.destroy
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
