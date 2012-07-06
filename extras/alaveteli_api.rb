require 'open-uri'

class AlaveteliApi

    class AlaveteliApiError < StandardError
    end

    def self.send_request(request)
        api_endpoint = MySociety::Config::get("ALAVETELI_API_ENDPOINT")
        if !api_endpoint.nil?
            client = HTTPClient.new
            data = {:title => request.title, 
                :body => request.body,
                :external_user_name => request.requestor_name,
                :external_url => "/XXXworkthisoutlater"
            }
            key = MySociety::Config::get("ALAVETELI_API_KEY")
            response = client.post("#{api_endpoint}/request.json", {:k => key, :request_json => data}).body
            json = ActiveSupport::JSON.decode(response)
            if json['errors'].nil?
                Rails.logger.info("Created new request at #{json['url']}")
                return json['id']                        
            else
                raise AlaveteliApiError, json['errors']
            end
        end
    end

    def self.send_response(response)
        api_endpoint = MySociety::Config::get("ALAVETELI_API_ENDPOINT")
        if !api_endpoint.nil?
            client = HTTPClient.new
            attachments = response.attachments.collect do |attachment|
                {'Content-Type' => attachment.content_type,
                    'Content-Transfer-Encoding' => 'binary',
                    :content => attachment}

            end
            data = {
                :direction => 'response', # or request
                :body => response.body,
                :sent_at => response.created_at,
                :attachments => attachments,
            }
            key = MySociety::Config::get("ALAVETELI_API_KEY")

            response = client.post("#{api_endpoint}/request#{response.request.remote_id}.json", {:k => key, :request_json => data}).read
            json = ActiveSupport::JSON.decode(response)
            if json['errors'].nil?
                Rails.logger.info("Created new response id #{response.id}")
            else
                raise AlaveteliApiError, json['errors']
            end
        end
    end

end
