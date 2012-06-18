# == Schema Information
#
# Table name: requests
#
#  id                        :integer         not null, primary key
#  title                     :string(255)
#  requestor_id              :integer
#  created_at                :datetime        not null
#  updated_at                :datetime        not null
#  body                      :text
#  date_received             :date
#  due_date                  :date            not null
#  lgcs_term_id              :integer
#  is_published              :boolean         default(FALSE), not null
#  is_requestor_name_visible :boolean         default(FALSE), not null
#  medium                    :string(255)     default("web"), not null
#

class Request < ActiveRecord::Base
  belongs_to :requestor
  belongs_to :lgcs_term
  validates_presence_of :title
  has_many :request_states
  has_many :responses
  has_many :attachments, :as => :request_or_response
  has_many :states, :through => :request_states, :order => :created_at
  accepts_nested_attributes_for :requestor
  accepts_nested_attributes_for :responses
  accepts_nested_attributes_for :attachments
  
  validates :medium, :presence => true, :inclusion => {
    :in => [ "web", "email", "phone", "fax", "post", "other" ]
  }
  
  acts_as_xapian({
    :texts => [ :title, :body ],
    :values => [
        [ :created_at, 0, "created_at", :date ]
    ],
    :terms => [
        [ :medium, 'M', "medium" ],
        [ :lgcs_term_name, 'T', "lgcs_term" ]
    ]})

  def state
    self.states.last || State.new
  end

  def state=(state)
    self.states << state
  end
 
  def state_attributes=(attributes)
    # process an attributes hash passed from nested form field
    self.state = State.find(attributes[:id])
  end

  def days_until_due
    if !self.due_date.nil?
      (self.due_date - Date.today).to_i
    end
  end
  
  def date_received_or_created
    date_received || created_at.to_date
  end
  
  def lgcs_term_name
      lgcs_term.name
  end
  
  class << self
    # Get overdue requests, the most overdue first
    def overdue
      self.where("due_date <= date('now')").order("due_date ASC")
    end
    
    def count_by_month
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            Request.count(:group => "to_char(coalesce(date_received, created_at), 'YYYY-MM')")
        elsif ActiveRecord::Base.connection.adapter_name == "SQLite"
            Request.count(:group => "strftime('%Y-%m', coalesce(date_received, created_at))")
        else
            raise "Unsupported database"
        end
    end
    
    def count_by_state
        Request.count(:group => "(
            select states.title
            from request_states
            join states on request_states.state_id = states.id
            where request_id = requests.id
            and not exists (
                select * from request_states newer_state
                where newer_state.request_id = requests.id
                and newer_state.created_at > request_states.created_at
            )
        )")
    end
  end
  
end
