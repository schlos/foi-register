# encoding: UTF-8

require "cgi"
require "open-uri"
require "net/https"
require "uri"
require "time"

namespace :foi do
    desc "Fetch the Alaveteli feed"
    task :fetch => :environment do
        api = AlaveteliApi
        if !api.pull_from_alaveteli?
            puts "Not pulling from Alaveteli, because PULL_FROM_ALAVETELI is false"
            next
        else
            api.fetch_feed
        end
    end
end
