module Shoehorn
  class DocumentsBase  < Array

    attr_accessor :connection, :matched_count, :per_page, :category_id, :modified_since, :current_page

    def initialize_options
      unless @skip_initialize_options
        @per_page = 50
        @category_id = nil
        @current_page = 1
        @modified_since = nil
      end
    end

    def refresh
      initialize(@connection)
    end

    # Requires an inserter id from an upload call
    def status(inserter_id)
      status_hash = Hash.new
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.Request(:xmlns => "urn:sbx:apis:SbxBaseComponents") do |xml|
        connection.requester_credentials_block(xml)
        xml.GetDocumentStatusCall do |xml|
          xml.InserterId(inserter_id)
        end
      end
      response = connection.post_xml(xml)
      document = REXML::Document.new(response)
      status_hash[:status] = document.elements["GetDocumentStatusCallResponse"].elements["Status"].text
      status_hash[:document_id] = document.elements["GetDocumentStatusCallResponse"].elements["DocumentId"].text
      status_hash[:document_type] = document.elements["GetDocumentStatusCallResponse"].elements["DocumentType"].text
      status_hash
    end

    # Resets if changing filters
    def category_id=(value)
      if value && (value != @category_id)
        @category_id = value
        @skip_initialize_options = true
        initialize(@connection)
        @skip_initialize_options = false
      end
    end

    def modified_since=(value)
      if value && (value != @modified_since)
        @modified_since = value
        @skip_initialize_options = true
        initialize(@connection)
        @skip_initialize_options = false
      end
    end

    def process_options(options={})
      results = options[:per_page] || per_page
      page_no = options[:page] || current_page
      modified_since = options[:modified_since] || modified_since
      category_id = options[:category_id] || category_id
    end

    # Returns true if we're dealing with anything other than all the records
    def filtered?
      !(modified_since || category_id).nil?
    end

  end
end