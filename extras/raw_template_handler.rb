class RawTemplateHandler
  def self.call(template)
    "#{template.source}\n"
  end
end
