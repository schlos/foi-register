# encoding: UTF-8

require "net/http"
require "rexml/document"


def each_lgcs_item
  Rails.logger.info("Loading LGCS XML data...")
  lgcs_xml = Net::HTTP.get_response("www.esd.org.uk", "/standards/lgcs/2.01/lgcs.xml").body
  Rails.logger.info("Loaded")
  
  REXML::Document.new(lgcs_xml).elements.each("/ControlledList/Item") do |item|
    id = item.attributes["Id"].to_i
    name = item.elements["Name"].text.gsub("?", "’")
    notes = item.elements["ScopeNotes"].text
    broader_items = item.get_elements("BroaderItem")
    if broader_items.size > 0
      if broader_items.size > 1
        raise "Item %d (%s) has >1 BroaderItem" % [id, name]
      end
      broader_item_id = broader_items[0].attributes["Id"].to_i
      
      yield :id => id, :name => name, :notes => notes, :broader_term_id => broader_item_id
    else
      yield :id => id, :name => name, :notes => notes
    end
  end
end

def insert_lgcs_terms
    each_lgcs_item do |item|
      Rails.logger.info "Creating LGCS term '#{item[:name]}' with id #{item[:id]}"
      term = LgcsTerm.new(item)
      term.id = item[:id]
      term.save!
    end
end


namespace :bootstrap do
  
  desc "Replace the LGCS terms with the ones from the official site"
  task :replace_lgcs_terms => :environment do
      ActiveRecord::Base.transaction do
          LgcsTerm.delete_all
          insert_lgcs_terms
      end
  end
  
  desc "Add the LGCS terms if they have not yet been added"
  task :add_lgcs_terms => :environment do
      ActiveRecord::Base.transaction do
          if LgcsTerm.count == 0
              insert_lgcs_terms
          end
      end
  end
  
  desc "Replace all terms"
  task :replace => [:replace_lgcs_terms]
  
  desc "Add all terms, if not yet added"
  task :add => [:add_lgcs_terms]
end
