require 'open-uri'
require './parse.rb'

class Downloader
  attr_reader :entries, :not_found_eids, :failed_eids

  def initialize
    @entries = {}
    @not_found_eids = []
    @failed_eids = []
  end

  def download(eid)
    return @entries[eid] if @entries[eid]

    begin
      document = Nokogiri::HTML(open("http://jigokuno.com/?eid=#{eid}"))
    rescue OpenURI::HTTPError => e
      @not_found_eids << eid
      return nil
    rescue => e
      @failed_eids << eid
      return nil
    end

    begin
      @entries[eid] = Entry.from_xml(eid, document)
    rescue => e
      STDERR.puts e.message
      @failed_eids << eid
    end
  end
end
