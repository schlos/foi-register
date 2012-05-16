require "net/http"
require "rexml/document"

def states ; [
    # tag, name, description
    ["new", "New", "A new request that has not even been acknowledged"],
    ["acknowledged", "Acknowledged", "A new request that has been acknowledged, but not had a substantive response or rejection"],
    
    ["done_rejected_vexatious", "Rejected as vexatious", "The request has been rejected as vexatious. In this case there is no legal obligation to respond to the requestor at all."],
    
    # The request is complete, and the requestor has been told:
    ["done_not_held", "Not held", "The information is not held"],
    ["done_supplied_all", "All information supplied", "All the requested information has been supplied"],
    ["done_supplied_some", "Some information supplied", "Some of the requested information has been supplied"],
    
    # Exemptions guidance is at http://www.justice.gov.uk/information-access-rights/foi-guidance-for-practitioners/exemptions-guidance
    ["done_exempt_s21", "Exempt §21 (other means)", "Exempt: Information Accessible By Other Means"],
    ["done_exempt_s22", "Exempt §22 (future publication)", "Exempt: Information Intended For Future Publication"],
    ["done_exempt_s23", "Exempt §23 (security matters)", "Exempt: Information Supplied by, or Related to, Bodies Dealing with Security Matters"],
    ["done_exempt_s24", "Exempt §24 (national security)", "Exempt: National Security"],
    ["done_exempt_s26", "Exempt §26 (defence)", "Exempt: Defence"],
    ["done_exempt_s27", "Exempt §27 (international relations)", "Exempt: International Relations"],
    ["done_exempt_s28", "Exempt §28 (UK relations)", "Exempt: Relations Within The United Kingdom"],
    ["done_exempt_s29", "Exempt §29 (economy)", "Exempt: The Economy"],
    ["done_exempt_s30", "Exempt §30 (investigations)", "Exempt: Investigations And Proceedings Conducted By Public Authorities"],
    ["done_exempt_s31", "Exempt §31 (law enforcement)", "Exempt: Law Enforcement"],
    ["done_exempt_s32", "Exempt §32 (court records)", "Exempt: Court Records"],
    ["done_exempt_s33", "Exempt §33 (audit functions)", "Exempt: Audit Functions"],
    ["done_exempt_s34", "Exempt §34 (parliamentary privilege)", "Exempt: Parliamentary Privilege"],
    ["done_exempt_s35", "Exempt §35 (policy formulation)", "Exempt: Formulation Of Government Policy"],
    ["done_exempt_s36", "Exempt §36 (prejudice to effective conduct)", "Exempt: Prejudice to Effective Conduct of Public Affairs"],
    ["done_exempt_s37", "Exempt §37 (crown)", "Exempt: Communications With Her Majesty, With Other Members Of The Royal Household, And The Conferring By The Crown Of Any Honour Or Dignity"],
    ["done_exempt_s38", "Exempt §38 (health and safety)", "Exempt: Health And Safety"],
    ["done_exempt_s39", "Exempt §39 (environmental information)", "Exempt: Environmental Information"],
    ["done_exempt_s40", "Exempt §40 (personal information)", "Exempt: Personal Information"],
    ["done_exempt_s41", "Exempt §41 (in confidence)", "Exempt: Information Provided In Confidence"],
    ["done_exempt_s42", "Exempt §42 (legal privilege)", "Exempt: Legal Professional Privilege"],
    ["done_exempt_s43", "Exempt §43 (commercial interests)", "Exempt: Commercial Interests"],
    ["done_exempt_s44", "Exempt §44 (prohibitions)", "Exempt: Prohibitions On Disclosure"],
] end
def insert_states
    for tag, title, description in states
      State.create(:tag => tag, :title => title, :description => description)
    end
end


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
  
  desc "Replace the states with the default states"
  task :replace_default_states => :environment do
      ActiveRecord::Base.transaction do
          State.delete_all
          insert_states
      end
  end
  
  desc "Replace the LGCS terms with the ones from the official site"
  task :replace_lgcs_terms => :environment do
      ActiveRecord::Base.transaction do
          LgcsTerm.delete_all
          insert_lgcs_terms
      end
  end
  
  desc "Add the states if they have not yet been added"
  task :add_default_states => :environment do
      ActiveRecord::Base.transaction do
          if State.count == 0
              insert_states
          end
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
  task :replace => [:replace_default_states, :replace_lgcs_terms]
  
  desc "Add all terms, if not yet added"
  task :add => [:add_default_states, :add_lgcs_terms]
end
