class RawTemplateHandler
  def self.call(template)
    "#{template.source}\n"
  end
end

ActionView::Template.register_template_handler 'raw', RawTemplateHandler
