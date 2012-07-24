# == Schema Information
#
# Table name: alaveteli_feeds
#
#  id            :integer          not null, primary key
#  last_event_id :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class AlaveteliFeed < ActiveRecord::Base
    class << self
        def last_event_id
            instance = get_instance
            if instance.nil?
                return MySociety::Config.get("ALAVETELI_INITIAL_LAST_EVENT_ID")
            else
                return instance.last_event_id
            end
        end
        
        def last_event_id=(new_last_event_id)
            instance = self.find_by_id(1)
            if instance.nil?
                instance = self.new(:last_event_id => new_last_event_id)
                instance.id = 1
            else
                instance.last_event_id = new_last_event_id
            end
            
            instance.save!
        end
        
        def get_instance
            return self.find_by_id(1)
        end
    end
end
