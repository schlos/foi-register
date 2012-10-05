# encoding: UTF-8
# == Schema Information
#
# Table name: requests
#
#  id                        :integer          not null, primary key
#  title                     :string(255)      not null
#  requestor_id              :integer          not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  body                      :text             not null
#  date_received             :date
#  due_date                  :date             not null
#  lgcs_term_id              :integer
#  is_published              :boolean          default(TRUE), not null
#  is_requestor_name_visible :boolean          default(FALSE), not null
#  medium                    :string(255)      default("web"), not null
#  remote_id                 :integer
#  remote_url                :string(255)
#  state                     :string(255)      default("new"), not null
#  nondisclosure_reason      :string(255)
#  remote_email              :string(255)
#  top_level_lgcs_term_id    :integer
#

class Request < ActiveRecord::Base
  STATES = ActiveSupport::OrderedHash.new
  # tag => name, description
  STATES["new"] = ["New", "A new request that has not even been acknowledged"]
  # STATES["acknowledged"] = ["Acknowledged", "A new request that has been acknowledged, but not had a substantive response or rejection"]
  STATES["assessing"] = ["Assessing", "The request has been sent through to the relevant service area"]
  STATES["disclosed"] = ["Disclosed", "The request has been sent through to the relevant service area"]
  STATES["partially_disclosed"] = ["Partially Disclosed", "Some of the requested information has been disclosed"]
  STATES["not_disclosed"] = ["Not Disclosed", "All the requested information has been disclosed"]

  NONDISCLOSURE_REASONS = ActiveSupport::OrderedHash.new
  NONDISCLOSURE_REASONS["not_held"] = ["Not held", "The information is not held"]
    
  NONDISCLOSURE_REASONS["rejected_vexatious"] = ["Rejected as vexatious", "The request has been rejected as vexatious. In this case there is no legal obligation to respond to the requestor at all."]
  NONDISCLOSURE_REASONS["rejected_time_limit"] = ["Rejected (more than 2.5 days)", "It would take more than 2.5 days to collect this information"]
    
  # Exemptions guidance is at http://www.justice.gov.uk/information-access-rights/foi-guidance-for-practitioners/exemptions-guidance
  NONDISCLOSURE_REASONS["exempt_s21"] = ["Exempt §21 (other means)", "Exempt: Information Accessible By Other Means"]
  NONDISCLOSURE_REASONS["exempt_s22"] = ["Exempt §22 (future publication)", "Exempt: Information Intended For Future Publication"]
  NONDISCLOSURE_REASONS["exempt_s23"] = ["Exempt §23 (security matters)", "Exempt: Information Supplied by, or Related to, Bodies Dealing with Security Matters"]
  NONDISCLOSURE_REASONS["exempt_s24"] = ["Exempt §24 (national security)", "Exempt: National Security"]
  NONDISCLOSURE_REASONS["exempt_s26"] = ["Exempt §26 (defence)", "Exempt: Defence"]
  NONDISCLOSURE_REASONS["exempt_s27"] = ["Exempt §27 (international relations)", "Exempt: International Relations"]
  NONDISCLOSURE_REASONS["exempt_s28"] = ["Exempt §28 (UK relations)", "Exempt: Relations Within The United Kingdom"]
  NONDISCLOSURE_REASONS["exempt_s29"] = ["Exempt §29 (economy)", "Exempt: The Economy"]
  NONDISCLOSURE_REASONS["exempt_s30"] = ["Exempt §30 (investigations)", "Exempt: Investigations And Proceedings Conducted By Public Authorities"]
  NONDISCLOSURE_REASONS["exempt_s31"] = ["Exempt §31 (law enforcement)", "Exempt: Law Enforcement"]
  NONDISCLOSURE_REASONS["exempt_s32"] = ["Exempt §32 (court records)", "Exempt: Court Records"]
  NONDISCLOSURE_REASONS["exempt_s33"] = ["Exempt §33 (audit functions)", "Exempt: Audit Functions"]
  NONDISCLOSURE_REASONS["exempt_s34"] = ["Exempt §34 (parliamentary privilege)", "Exempt: Parliamentary Privilege"]
  NONDISCLOSURE_REASONS["exempt_s35"] = ["Exempt §35 (policy formulation)", "Exempt: Formulation Of Government Policy"]
  NONDISCLOSURE_REASONS["exempt_s36"] = ["Exempt §36 (prejudice to effective conduct)", "Exempt: Prejudice to Effective Conduct of Public Affairs"]
  NONDISCLOSURE_REASONS["exempt_s37"] = ["Exempt §37 (crown)", "Exempt: Communications With Her Majesty, With Other Members Of The Royal Household, And The Conferring By The Crown Of Any Honour Or Dignity"]
  NONDISCLOSURE_REASONS["exempt_s38"] = ["Exempt §38 (health and safety)", "Exempt: Health And Safety"]
  NONDISCLOSURE_REASONS["exempt_s39"] = ["Exempt §39 (environmental information)", "Exempt: Environmental Information"]
  NONDISCLOSURE_REASONS["exempt_s40"] = ["Exempt §40 (personal information)", "Exempt: Personal Information"]
  NONDISCLOSURE_REASONS["exempt_s41"] = ["Exempt §41 (in confidence)", "Exempt: Information Provided In Confidence"]
  NONDISCLOSURE_REASONS["exempt_s42"] = ["Exempt §42 (legal privilege)", "Exempt: Legal Professional Privilege"]
  NONDISCLOSURE_REASONS["exempt_s43"] = ["Exempt §43 (commercial interests)", "Exempt: Commercial Interests"]
  NONDISCLOSURE_REASONS["exempt_s44"] = ["Exempt §44 (prohibitions)", "Exempt: Prohibitions On Disclosure"]
  
  belongs_to :requestor
  belongs_to :lgcs_term
  belongs_to :top_level_lgcs_term, :class_name => "LgcsTerm"
  validates_presence_of :title
  validates_presence_of :requestor
  validates_presence_of :body
  has_many :responses, :order => 'created_at'
  accepts_nested_attributes_for :requestor
  accepts_nested_attributes_for :responses
  
  validates :nondisclosure_reason, :presence => true, :if => "state == 'not_disclosed'"
  
  validates :medium, :presence => true, :inclusion => {
    :in => [ "web", "email", "phone", "fax", "post", "alaveteli", "other" ]
  }
  validates :state, :inclusion => { :in => STATES.keys }
  
  acts_as_xapian({
    :texts => [ :title, :body, :requestor_name, :requestor_email ],
    :values => [
        [ :created_at, 0, "created_at", :date ]
    ],
    :terms => [
        [ :medium, 'B', "medium" ], # 'M' is reserved for use as the model
        [ :lgcs_term_name, 'T', "lgcs_term" ]
    ]})
 
  def state_title
    STATES[state][0]
  end
  
  def state_description
    STATES[state][1]
  end
  
  def state=(value)
    write_attribute(:state, value)
    if state != 'not_disclosed'
      nondisclosure_reason = nil
    end
  end
  
  def nondisclosure_reason=(value)
    if NONDISCLOSURE_REASONS.has_key? value
      write_attribute(:nondisclosure_reason, value)
    else
      write_attribute(:nondisclosure_reason, nil)
    end
  end

  def nondisclosure_reason_title
    nondisclosure_reason.nil? ? nil : NONDISCLOSURE_REASONS[nondisclosure_reason][0]
  end
  
  def nondisclosure_reason_description
    nondisclosure_reason.nil? ? nil : NONDISCLOSURE_REASONS[nondisclosure_reason][1]
  end
  
  def administrative_id
    "FOI:#{self.id}/#{self.date_received_or_created.year}"
  end
  
  def days_until_due
    if !self.due_date.nil?
      (self.due_date - Date.today).to_i
    end
  end
  
  def date_received_or_created
    date_received || created_at.to_date
  end
  
  def date_responded
    if responses.empty?
      nil
    else
      responses[-1].created_at.to_date
    end
  end
  
  def lgcs_term_name
    lgcs_term.nil? ? nil : lgcs_term.name
  end
  
  class << self
    # Get overdue requests, the most overdue first
    def overdue
      self.where("due_date <= date('now')").order("due_date ASC")
    end
    
    def count_by_month(months_limit=nil)
      if months_limit.nil?
        q = Request
      else
        q = Request.where(["coalesce(date_received, created_at) > ?", Date.today - months_limit.months])
      end
      
      q = yield(q) if block_given?
      
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
        q.count(:group => "to_char(coalesce(date_received, created_at), 'YYYY-MM')")
      elsif ActiveRecord::Base.connection.adapter_name == "SQLite"
        q.count(:group => "strftime('%Y-%m', coalesce(date_received, created_at))")
      else
        raise "Unsupported database"
      end
    end
  end
  
  def requestor_name
    requestor.name
  end

  def requestor_email
    requestor.email
  end
  
  def email_for_response
    if remote_email.nil?
      requestor_email
    else
      remote_email
    end
  end
  
  def send_acknowledgement
    RequestMailer.acknowledgement(self).deliver if !self.email_for_response.nil?
  end

  def send_notification
    RequestMailer.notification(self).deliver
  end
  
  def send_to_alaveteli
      if MySociety::Config.get("PUSH_TO_ALAVETELI") && medium != "alaveteli"
          self.remote_id, self.remote_url = AlaveteliApi.send_request(self)
          save!
      end
  end
  handle_asynchronously :send_to_alaveteli
  
  def set_top_level_lgcs_term
    if lgcs_term_id.nil?
      self.top_level_lgcs_term_id = nil
    else
      t = lgcs_term
      t = t.broader_term while !t.broader_term.nil?
      self.top_level_lgcs_term_id = t.id
    end
  end
  before_save :set_top_level_lgcs_term
  
end
