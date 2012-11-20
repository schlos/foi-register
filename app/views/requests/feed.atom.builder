atom_feed do |feed|
    feed.title("New FOI requests to " + MySociety::Config.get("ORG_NAME"))
    feed.updated(@updated)

    for request in @requests
        feed.entry(request) do |entry|
            entry.updated(request.created_at.utc.iso8601)
            entry.title(request.title)
            entry.content(request.body, :type => 'text')
            
            entry.author do |author|
                author.name(request.requestor_name)
                author.email(request.requestor_email) if !request.requestor_email.nil?
            end
        end
    end
end
