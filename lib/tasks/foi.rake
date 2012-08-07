# encoding: UTF-8

require "cgi"
require "uri"
require "net/http"
require "time"

namespace :foi do
    desc "Fetch the Alaveteli feed"
    task :fetch => :environment do
        if !MySociety::Config.get("PULL_FROM_ALAVETELI")
            puts "Not pulling from Alaveteli, because PULL_FROM_ALAVETELI is false"
            next
        end
        
        feed_url = MySociety::Config.get("ALAVETELI_FEED_URL")
        feed_key = MySociety::Config.get("ALAVETELI_API_KEY")
        
        url = feed_url + "?k=" + CGI::escape(feed_key)
        
        ActiveRecord::Base.transaction do
            last_event_id = AlaveteliFeed.last_event_id
            if !last_event_id.nil?
                url += '&since_event_id=' + last_event_id.to_s
            end
            
            response = Net::HTTP.get_response( URI.parse(url) )
            events = ActiveSupport::JSON.decode(response.body)
            
            events.reverse_each do |event|
                event_type = event["event_type"]
                if event_type == "sent"
                    # Process the event
                    
                    # Get existing user, or make a new one.
                    user_url = event["user_url"]
                    requestor = Requestor.find_by_external_url(user_url)
                    if requestor.nil?
                        requestor = Requestor.new(
                            :name => event["user_name"],
                            :external_url => user_url
                        )
                        requestor.save!
                    end
                    
                    # Create a request
                    date_received = Time.iso8601(event["created_at"])
                    request = Request.new(
                        :medium => "alaveteli",
                        :state => "new",
                        :remote_id => event["request_id"].to_i,
                        :requestor => requestor,
                        :title => event["title"],
                        :body => event["body"],
                        :date_received => date_received,
                        :due_date => date_received + 28.days
                    )
                    request.save!
                end
            end
            AlaveteliFeed.last_event_id = events[0]["event_id"] if !events.empty?
        end
    end
end
