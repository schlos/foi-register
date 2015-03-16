require 'open-uri'
require 'base64'
require 'net/https'
require 'net/http/post/multipart'

class AlaveteliApi

    class AlaveteliApiError < StandardError
    end

    def self.prepare_connection(url)
      http = Net::HTTP.new(url.host, url.port)
      # Increase the timeout because alaveteli is slow sometimes
      http.read_timeout = 300
      if self.alaveteli_secure?
        http.use_ssl = true
        http.ca_path = MySociety::Config.get("SSL_CA_PATH", "/etc/ssl/certs/")
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      http
    end

    def self.alaveteli_secure?()
      MySociety::Config::get("ALAVETELI_SECURE")
    end

    def self.pull_from_alaveteli?()
        MySociety::Config.get("PULL_FROM_ALAVETELI")
    end

    def self.send_request(request)
        api_endpoint = MySociety::Config::get("ALAVETELI_API_ENDPOINT")
        return nil, nil if api_endpoint.nil?

        data = {:title => request.title,
            :body => request.body,
            :external_url => Rails.application.routes.url_helpers.request_url(nil, request, :host => MySociety::Config.get("DOMAIN", "localhost:3000"))
        }
        data[:external_user_name] = request.requestor_name if request.is_requestor_name_visible?

        key = MySociety::Config::get("ALAVETELI_API_KEY")
        url = URI.parse("#{api_endpoint}/request.json")

        http = self.prepare_connection(url)
        req = Net::HTTP::Post::Multipart.new(url.path,
                                             :k => key,
                                             :request_json => data.to_json)
        response = http.request(req)
        case response
        when Net::HTTPSuccess
          json = ActiveSupport::JSON.decode(response.body)
          if json['errors'].nil?
              Rails.logger.info("Created new request at #{json['url']}")
              return json['id'], json['url']
          else
              raise AlaveteliApiError, json['errors']
          end
        when Net::HTTPUnauthorized
          raise AlaveteliApiError, "Unauthorized: is the API key correct?"
        else
          Rails.logger.error("Alaveteli API error: " + response.body)
          raise AlaveteliApiError, "Error from Alaveteli API: see log for details"
        end
    end

    def self.send_response(response)
        api_endpoint = MySociety::Config::get("ALAVETELI_API_ENDPOINT")
        if !api_endpoint.nil?
            correspondence_data = {
                :direction => 'response', # or request
                :body => response.public_part,
                :state => translate_request_for_alaveteli(response.request.state),
                :sent_at => response.created_at
            }
            key = MySociety::Config::get("ALAVETELI_API_KEY")
            url = URI.parse("#{api_endpoint}/request/#{response.request.remote_id}.json")
            post_data = [[:k, key],
                         [:correspondence_json, correspondence_data.to_json]]
            response.attachments.each do |attachment|
                post_data.push(["attachments[]", UploadIO.new(
                    open(attachment.file.file.file),
                    attachment.content_type,
                    attachment.filename
                )])
            end
            http = self.prepare_connection(url)
            req = Net::HTTP::Post::Multipart.new(url.path, post_data)
            response = http.request(req)
            json = ActiveSupport::JSON.decode(response.body)
            if json['errors'].nil?
                Rails.logger.info("Created new response id #{response.object_id}")
            else
                raise AlaveteliApiError, json['errors']
            end
        end
    end

    def self.status_update(request)
        api_endpoint = MySociety::Config::get("ALAVETELI_API_ENDPOINT")

        if !api_endpoint.nil?
            key = MySociety::Config::get("ALAVETELI_API_KEY")
            url = URI.parse("#{api_endpoint}/request/#{request.remote_id}/update.json")
            post_data = [[:k, key],
                         [:state, translate_request_for_alaveteli(request.requestor_state)]]
        end
        http = self.prepare_connection(url)
        req = Net::HTTP::Post::Multipart.new(url.path, post_data)
        response = http.request(req)
        json = ActiveSupport::JSON.decode(response.body)
        if json['errors'].nil?
            Rails.logger.info("Updated status of reqeust id #{request.object_id}")
        else
            raise AlaveteliApiError, json['errors']
        end
    end

    def self.translate_request_for_alaveteli(state)
        case state
        when "disclosed"
            "successful"
        when "partially_disclosed"
            "partially_successful"
        when "not_disclosed"
            "rejected"
        else "error"
        end
    end

    def self.fetch_feed
        # Fetch new requests from the alaveteli events feed
        feed_url = MySociety::Config.get("ALAVETELI_FEED_URL")
        feed_key = MySociety::Config.get("ALAVETELI_API_KEY")

        url = feed_url + "?k=" + CGI::escape(feed_key)

        ActiveRecord::Base.transaction do
            last_event_id = AlaveteliFeed.last_event_id
            if !last_event_id.nil?
                url += '&since_event_id=' + last_event_id.to_s
            end

            uri = URI.parse(url)
            http = self.prepare_connection(uri)

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

                    # If the user_url is nil, it means that there's no user
                    # logged in Alaveteli, which in all likelihood means that
                    # this is actually a request that *we* sent to alaveteli
                    # but that somehow doesn't have a remote_id yet (maybe
                    # something bombed out whilst sending it to Alaveteli, and
                    # Alaveteli got it but we didn't get their response). This
                    # is a bad situation to be in, and needs investigating by
                    # someone immediately, hence raising an error.
                    if user_url.nil?
                        raise AlaveteliApiError, "Received request from alaveteli feed with no user_url that doesn't match any existing remote_id: #{remote_id}"
                    end

                    requestor = Requestor.find_by_external_url_scheme_insensitive(user_url)

                    # oh, it really is new - better make a new requestor then
                    if requestor.nil?
                        requestor = Requestor.new(
                            :name => event["user_name"],
                            :external_url => user_url
                        )
                    end
                    requestor.save!

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
