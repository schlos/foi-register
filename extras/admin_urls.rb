module AdminUrls

  def url_for(options = {})
    url = super(options)
    if url =~ %r(^/admin/)
      return MySociety::Config::get("ADMIN_PREFIX", "/admin") + url["/admin".length..-1]
    else
      return url
    end
  end

end