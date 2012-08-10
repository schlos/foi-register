# encoding: UTF-8

class RequestorsController < ApplicationController
  # GET /requestors
  # GET /requestors.json
  def index
    @requestors = Requestor.paginate(:page => params[:page], :per_page => 100).all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @requestors }
    end
  end

  # GET /requestors/1
  # GET /requestors/1.json
  def show
    @requestor = Requestor.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @requestor }
    end
  end

  # GET /requestors/new
  # GET /requestors/new.json
  def new
    @requestor = Requestor.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @requestor }
    end
  end

  # GET /requestors/1/edit
  def edit
    @requestor = Requestor.find(params[:id])
  end

  # POST /requestors
  # POST /requestors.json
  def create
    @requestor = Requestor.new(params[:requestor])

    respond_to do |format|
      if @requestor.save
        format.html { redirect_to @requestor, :notice => 'Requestor was successfully created.' }
        format.json { render :json => @requestor, :status => :created, :location => @requestor }
      else
        format.html { render :action => "new" }
        format.json { render :json => @requestor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /requestors/1
  # PUT /requestors/1.json
  def update
    @requestor = Requestor.find(params[:id])

    respond_to do |format|
      if @requestor.update_attributes(params[:requestor])
        format.html { redirect_to @requestor, :notice => 'Requestor was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @requestor.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /requestors/1
  # DELETE /requestors/1.json
  def destroy
    @requestor = Requestor.find(params[:id])
    @requestor.destroy

    respond_to do |format|
      format.html { redirect_to requestors_url }
      format.json { head :no_content }
    end
  end
end
