# encoding: UTF-8

require 'will_paginate/array' # Extend Array with the paginate method, used in "search"

class RequestsController < ApplicationController
  skip_before_filter :require_login, :only => [
    :index, :in_category, :show, :new, :create, :search, :search_typeahead, :feed]

  # /admin/requests/feed.atom has its own authentication
  skip_before_filter :require_login_based_on_url, :only => [:feed]

  # GET /requests
  # GET /requests.json
  def index
    if is_admin_view?
      @requests = Request.paginate(:page => params[:page], :per_page => 100) \
        .order('coalesce(date_received, created_at) DESC')
      @total = Request.count
      counts = Request.count(:group => "state")
    else
      @requests = Request.paginate(:page => params[:page], :per_page => 20) \
        .where(['is_published = ?', true]) \
        .order('coalesce(date_received, created_at) DESC')
      @total = Request.where(['is_published = ?', true]).count
      counts = Request.where(['is_published = ?', true]).count(:group => "state")
    end
    @badge = "all"
    @category = nil
    @count_by_state = {
      :in_progress => counts.fetch("new", 0) + counts.fetch("assessing", 0),
      :disclosed => counts.fetch("disclosed", 0) + counts.fetch("partially_disclosed", 0),
      :not_disclosed => counts.fetch("not_disclosed", 0)
    }

    respond_to do |format|
      format.html { render :action => self.is_admin_view? ? "admin_index" : "public_index" }
      format.json { render :json => @requests }
    end
  end

  # GET /requests/category/:top_level_lgcs_term_id
  def in_category
    @category = LgcsTerm.find(params[:top_level_lgcs_term_id])

    @requests = Request.paginate(:page => params[:page], :per_page => 20) \
      .where(['top_level_lgcs_term_id = ?', params[:top_level_lgcs_term_id]]) \
      .where(['is_published = ?', true]) \
      .order('coalesce(date_received, created_at) DESC')
    our_requests = Request.where(['top_level_lgcs_term_id = ?', params[:top_level_lgcs_term_id]]) \
      .where(['is_published = ?', true])
    @total = our_requests.count
    counts = our_requests.count(:group => "state")
    @count_by_state = {
      :in_progress => counts.fetch("new", 0) + counts.fetch("assessing", 0),
      :disclosed => counts.fetch("disclosed", 0) + counts.fetch("partially_disclosed", 0),
      :not_disclosed => counts.fetch("not_disclosed", 0)
    }

    respond_to do |format|
      format.html { render :action => "public_index" }
      format.json { render :json => @requests }
    end
  end

  # GET /requests/1
  # GET /requests/1.json
  def show
    @request = Request.find(params[:id])
    raise ActiveRecord::RecordNotFound if !is_admin_view? && !@request.is_published
    @title = @request.title + MySociety::Config.get("PAGE_TITLE_SUFFIX")

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @request }
    end
  end

  # GET /requests/overdue
  def overdue
    @requests = Request.paginate(:page => params[:page], :per_page => 100).overdue
    @badge = "overdue"

    respond_to do |format|
      format.html { render :action => "admin_index" }
      format.json { render :json => @requests }
    end
  end

  # GET /requests/stats
  def stats
    @stats = {
        :by_month => Request.count_by_month(24),
        :by_state => Request.count(:group => "state"),
        :by_month_and_state => Request.count_by_month(24) {|q| q.group("state")}
    }
    respond_to do |format|
      format.html { render }
      format.json { render :json => @stats }
    end
  end

  # GET /requests/search
  def search
    @query = params[:q]
    if @query =~ %r(^FOI:(\d+)(/\d+)?$)
      @request = Request.find($1.to_i)
      if self.is_admin_view?
        redirect_to request_path(@request, :is_admin => 'admin')
      else
        redirect_to request_path(@request)
      end
      return
    end

    options = {}
    options[:offset] = params[:offset].to_i if params.has_key?(:offset)
    options[:limit] = params[:limit].to_i if params.has_key?(:limit)
    options[:sort_by_prefix] = params[:sort_by_prefix].to_i if params.has_key?(:sort_by_prefix)

    s = ActsAsXapian::Search.new([
      Request, Response # Attachment?
    ], @query, options)

    @requests = s.results.map do |r|
      m = r[:model]
      m.instance_of?(Response) ? m.request : m
    end.uniq

    @requests = @requests.select(&:is_published) if !self.is_admin_view?

    respond_to do |format|
      format.html do
        @requests = @requests.paginate
        render :action => self.is_admin_view? ? "admin_search_results" : "public_search_results"
      end
      format.json { render :json => @requests }
    end
  end

  def search_typeahead
    query_words = params[:q].split(/ +(?![-+]+)/)
    if query_words.last.nil? || query_words.last.strip.length < 3
        @requests = nil
    else
      query = ActsAsXapian::Search.new([
          Request, Response # Attachment?
        ], params[:q].strip + '*', {
          :limit => 10,
          :sort_by_prefix => nil,
          :sort_by_ascending => true,
          :additional_flags => Xapian::QueryParser::FLAG_WILDCARD,
          :default_op => Xapian::Query::OP_OR,
        })
      logger.info "Parsed typeahead query: " + query.description

      @requests = query.results.map do |r|
          m = r[:model]
          m.instance_of?(Response) ? m.request : m
        end.uniq
      @requests = @requests.select(&:is_published) if !self.is_admin_view?
    end

    render :json => @requests
  end

  # GET /requests/new
  # GET /requests/new.json
  def new
    @request = Request.new
    @request.requestor = Requestor.new
    respond_to do |format|
      format.html { render :action => self.is_admin_view? ? "admin_new" : "public_new" }
      format.json { render :json => @request }
    end
  end

  # GET /requests/feed
  # GET /requests/feed.atom
  def feed
    if params[:k] != MySociety::Config.get("FEED_AUTH_TOKEN")
      head :forbidden
      return
    end
    days_to_show = params[:days] ? params[:days].to_i : 30
    @requests = Request.where(["created_at >= ?", Date.today - days_to_show.days]).order("created_at DESC")
    if !@requests.empty?
      @updated = @requests.first.created_at
    else
      most_recent = Request.order('created_at DESC').limit(1)
      if !most_recent.empty?
        @updated = most_recent.first.created_at
      end
    end
    respond_to do |format|
      format.atom { render :layout => false } # feed.atom.builder
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
      request[:state] = "new"
      request[:medium] = "web"
      request[:due_date] = Date.today + 28.days
      request[:lgcs_term_id] = nil
      request[:is_published] = true
    else
      if request.has_key? :due_date
        request[:due_date] = Date.strptime(request[:due_date], "%d/%m/%Y")
      end
    end

    @request = Request.new(request)

    if requestor[:id].nil? || requestor[:id].empty?
      @request.requestor = Requestor.new(requestor)
      requestor_is_new = true
    else
      @request.requestor = Requestor.find_by_id(requestor[:id])
      requestor_is_new = false
    end

    saved_ok = @request.save
    if requestor_is_new && !self.is_admin_view? && @request.requestor.errors[:email].empty?
      @request.requestor.errors.add_on_blank(:email)
      e = @request.requestor.errors[:email]
      if !e.empty?
        @request.errors.add("requestor.email", e[0])
        saved_ok = false
      end
    end

    @request.send_to_alaveteli if saved_ok
    @request.send_acknowledgement
    @request.send_notification if !self.is_admin_view?

    respond_to do |format|
      if saved_ok
        format.html do
            if self.is_admin_view?
                redirect_to requests_path(:is_admin=>"admin"), :notice => 'Request was successfully created.'
            else
                redirect_to requests_path, :notice => "Your request has been received. A response will be sent to <#{@request.requestor.email}>."
            end
        end
        format.json { render :json => @request, :status => :created, :location => @request }
      else
        format.html { render :action => self.is_admin_view? ? "admin_new" : "public_new" }
        format.json { render :json => @request.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST /admin/requests/1/update_state.json
  def update_state
    request = Request.find(params[:id])
    state_tag = params[:state]
    state = Request::STATES[state_tag]

    request.state = state_tag
    if request.save!
      render :json => {
        "ok" => true,
        "name" => state[0],
        "description" => state[1]
      }
    else
      render :json => {
        "ok" => false
      }
    end
  end

  # PUT /requests/1
  # PUT /requests/1.json
  def update
    @request = Request.find_by_id(params[:id])
    is_published_remotely = !@request.remote_url.nil?
    reason_for_unpublishing = params.delete(:reason_for_unpublishing)

    if params[:request].has_key? :due_date
      params[:request][:due_date] = Date.strptime(params[:request][:due_date], "%d/%m/%Y")
    end

    respond_to do |format|
      if @request.update_attributes(params[:request])
        if is_published_remotely && !@request.is_published
          if reason_for_unpublishing.nil? || reason_for_unpublishing.empty?
            raise "No reason_for_unpublishing given"
          end
          RequestMailer.takedown_notification(@request, reason_for_unpublishing).deliver
        end
        format.html { redirect_to request_path(@request, :is_admin=>"admin"),
                                  :notice => 'Request was successfully updated.' }
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
      format.html {
        if request.env['HTTP_REFERER'] =~ /[?&]page=(\d+)$/
          redirect_to requests_path(:is_admin => "admin", :page => $1)
        else
          redirect_to requests_path(:is_admin => "admin")
        end
      }
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
