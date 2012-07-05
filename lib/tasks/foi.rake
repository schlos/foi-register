require "cgi"
require "uri"
require "net/http"

namespace :foi do
    desc "Fetch the Alaveteli feed"
    task :fetch => :environment do
        feed_url = MySociety::Config.get("ALAVETELI_FEED_URL")
        feed_key = MySociety::Config.get("ALAVETELI_API_KEY")
        
        url = feed_url + "?k=" + CGI::escape(feed_key)
        
        ActiveRecord::Base.transaction do
            last_event_id = AlaveteliFeed.last_event_id
            if !last_event_id.nil?
                url += '&since_event_id=' + last_event_id
            end
            
            response = Net::HTTP.get_response( URI.parse(url) )
            events = ActiveSupport::JSON.decode(response.body)
            
            events.reverse_each do |event|
                #xxxx insert event ...
            end
            AlaveteliFeed.last_event_id = events[0][:event_id]
        end
    end
end
