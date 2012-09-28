require 'alaveteli_api'
require 'raw_template_handler'
ActionView::Template.register_template_handler 'raw', RawTemplateHandler
