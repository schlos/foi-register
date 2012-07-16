require 'open-uri'
require 'base64'
require 'net/http/post/multipart'

class AlaveteliApi

    class AlaveteliApiError < StandardError
    end

    def self.send_request(request)
        api_endpoint = MySociety::Config::get("ALAVETELI_API_ENDPOINT")
        if !api_endpoint.nil?
            data = {:title => request.title, 
                :body => request.body,
                :external_user_name => request.requestor_name,
                :external_url => "/XXXworkthisoutlater" # TODO
            }.to_json
            key = MySociety::Config::get("ALAVETELI_API_KEY")
            url = URI.parse("#{api_endpoint}/request.json")
            req = Net::HTTP::Post::Multipart.new(url.path,
                                                 :k => key,
                                                 :request_json => data)

            response = Net::HTTP.start(url.host, url.port) do |http|
                http.request(req)
            end
            json = ActiveSupport::JSON.decode(response.body)
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
            correspondence_data = {
                :direction => 'response', # or request
                :body => response.public_part,
                :sent_at => response.created_at,
            }
            key = MySociety::Config::get("ALAVETELI_API_KEY")
            url = URI.parse("#{api_endpoint}/request/#{response.request.remote_id}.json")
            post_data = {:k => key,
                         :correspondence_json => correspondence_data.to_json}
            response.attachments.collect do |attachment|
                post_data[attachment.filename] = UploadIO.new(open(attachment.file.file.file),
                                                              attachment.content_type,
                                                              attachment.filename)
            end
            req = Net::HTTP::Post::Multipart.new(url.path, post_data)
            response = Net::HTTP.start(url.host, url.port) do |http|
                http.request(req)
            end
            json = ActiveSupport::JSON.decode(response.body)
            if json['errors'].nil?
                Rails.logger.info("Created new response id #{response.object_id}")
            else
                raise AlaveteliApiError, json['errors']
            end
        end
    end

end
