Rails.application.config.after_initialize do
    request_last_created = HealthChecks::Checks::DaysAgoCheck.new(
                         :failure_message => 'The last request was created over 3 days ago',
                         :success_message => 'The last request was created in the last 3 days',
                         :days => 3) do
                             Request.last.created_at
                         end

    request_last_created_from_alaveteli = HealthChecks::Checks::DaysAgoCheck.new(
                                        :failure_message => 'The last request from alaveteli was created over 14 days ago',
                                        :success_message => 'The last request from alaveteli was created in the last 14 days',
                                        :days => 14) do
                                            if Request.where("medium = 'alaveteli'").empty?
                                              Time.new(1970,1,1,0,0,0)
                                            else
                                              Request.where("medium = 'alaveteli'").last.created_at
                                            end
                                        end

    failed_jobs_exist = HealthChecks::Checks::ExistenceCheck.new(
                      :failure_message => 'There are failed delayed jobs',
                      :success_message => 'There are no failed delayed jobs',
                      :should_exist => false) do
                          Delayed::Job.where("failed_at IS NOT NULL").first
                      end

    reports_sent_to_alaveteli = HealthChecks::Checks::ExistenceCheck.new(
                              :failure_message => "There are requests which haven't been sent to Alaveteli in over an hour",
                              :success_message => 'All requests older than an hour have been sent to Alaveteli',
                              :should_exist => false) do
                                  Request.where("created_at < ? AND medium != 'alaveteli' AND remote_id IS NULL", Time.now - 1.hours).first
                              end


    HealthChecks.add request_last_created
    if MySociety::Config.get('PULL_FROM_ALAVETELI')
      HealthChecks.add request_last_created_from_alaveteli
    end
    HealthChecks.add failed_jobs_exist
    if MySociety::Config.get('PUSH_TO_ALAVETELI')
      HealthChecks.add reports_sent_to_alaveteli
    end
end