# == Schema Information
#
# Table name: lgcs_terms
#
#  id              :integer          not null, primary key
#  name            :string(255)      not null
#  broader_term_id :integer
#  notes           :text
#

# A term of the LGCS taxonomy, used for classifying the subject of requests

class LgcsTerm < ActiveRecord::Base
  belongs_to :broader_term, :class_name => 'LgcsTerm',
             :foreign_key => "broader_term_id"
  has_many :child_terms, :class_name => 'LgcsTerm',
           :inverse_of => :broader_term, :foreign_key => "broader_term_id", :order => "id"
  has_many :requests
  
  def to_s
    if broader_term_id.nil?
      return name
    else
      return broader_term.to_s + " > " + name
    end
  end
  
  class << self
    def top_level_terms
      return self.where("broader_term_id is null").order("id")
    end
  end
end
