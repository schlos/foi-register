class RequestsController < ApplicationController
  skip_before_filter :require_login, :only => [:index, :show, :new, :create]

  # GET /requests
  # GET /requests.json
  def index
    if is_admin_view?
      @requests = Request.paginate(:page => params[:page], :per_page => 5) \
        .order('coalesce(date_received, created_at) DESC')
    else
      @requests = Request.paginate(:page => params[:page], :per_page => 5) \
        .where(['is_published = ?', true]) \
        .order('coalesce(date_received, created_at) DESC')
    end
    @badge = "all"
    
    respond_to do |format|
      format.html { render :action => self.is_admin_view? ? "admin_index" : "public_index" }
      format.json { render :json => @requests }
    end

  end

  # GET /requests/1
  # GET /requests/1.json
  def show
    @request = Request.find(params[:id])
    raise ActiveRecord::RecordNotFound if !is_admin_view? && !@request.is_published
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @request }
    end
  end
  
  # GET /requests/overdue
  def overdue
    @requests = Request.paginate(:page => params[:page], :per_page => 5).overdue
    @badge = "overdue"
    
    respond_to do |format|
      format.html { render :action => "index" }
      format.json { render :json => @requests }
    end
  end
  
  # GET /requests/stats
  def stats
    @stats = {
        :by_month => Request.count_by_month,
        :by_state => Request.count_by_state,
    }
    respond_to do |format|
      format.html { render }
      format.json { render :json => @stats }
    end
  end
  
  # GET /requests/new
  # GET /requests/new.json
  def new
    @request = Request.new
    @states = State.all()
    @request.requestor = Requestor.new
    respond_to do |format|
      format.html { render :action => self.is_admin_view? ? "admin_new" : "public_new" }
      format.json { render :json => @request }
    end
  end

  # GET /requests/1/edit
  def edit
    @requestor_editable = false
    @request = Request.find(params[:id])
  end

  # POST /requests
  # POST /requests.json
  def create
    request = params[:request]
    requestor = request.delete :requestor_attributes
    
    if !self.is_admin_view?
        request[:state] = State.find_by_tag "new"
        request[:medium] = "web"
        request[:due_date] = Date.today + 28.days
        request[:lgcs_term_id] = nil
        request[:is_published] = false
    end
    
    @request = Request.new(request)
    
    if requestor[:id].nil?
      @request.requestor = Requestor.new(requestor)
    else
      @request.requestor = Requestor.find(requestor[:id])
    end

    respond_to do |format|
      if @request.save
        format.html do
            if self.is_admin_view?
                redirect_to @request, :notice => 'Request was successfully created.'
            else
                redirect_to requests_url, :notice => "Your request has been received. A response will be sent to <#{@request.requestor.email}>."
            end
        end
        format.json { render :json => @request, :status => :created, :location => @request }
      else
        format.html { render :action => "new" }
        format.json { render :json => @request.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /requests/1
  # PUT /requests/1.json
  def update
    @request = Request.find(params[:id])

    respond_to do |format|
      if @request.update_attributes(params[:request])
        format.html { redirect_to @request, :notice => 'Request was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @request.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /requests/1
  # DELETE /requests/1.json
  def destroy
    @request = Request.find(params[:id])
    @request.destroy

    respond_to do |format|
      format.html { redirect_to requests_url }
      format.json { head :no_content }
    end
  end
  
  # GET /requests/1/new_response
  def new_response
    @request = Request.find(params[:id])
    @response = Response.new
    @response.request = @request
  end
end
