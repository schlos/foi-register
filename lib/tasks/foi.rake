# encoding: UTF-8

require "cgi"
require "open-uri"
require "net/https"
require "uri"
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

            uri = URI.parse(url)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true

            http.ca_path = MySociety::Config.get("SSL_CA_PATH", "/etc/ssl/certs/")
            http.verify_mode = OpenSSL::SSL::VERIFY_PEER
            request = Net::HTTP::Get.new(uri.request_uri)
            response = http.request(request)
            events = ActiveSupport::JSON.decode(response.body)
            events.reverse_each do |event|

                event_type = event["event_type"]
                if event_type == "sent"

                    # Check to see if this is one of our own requests
                    remote_id = event['request_id']
                    existing_request = Request.find(:first, :conditions => ['remote_id = ?', remote_id])
                    next if existing_request

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
                        :remote_url => event["request_url"],
                        :remote_email => event["request_email"],
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
