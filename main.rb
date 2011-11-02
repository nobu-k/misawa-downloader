#! /usr/bin/env ruby

require './downloader.rb'
require 'json'

d = Downloader.new
(1..713).each { |i|
  d.download(i)
  sleep 3
}

STDERR.puts "not found eids: #{d.not_found_eids.map{|i| i.to_s}.join(', ')}"
STDERR.puts "failed eids: #{d.failed_eids.map{|i| i.to_s}.join(', ')}"

File.open('entries.json', 'w') { |f|
  d.entries.each_value { |e|
    f.puts e.to_hash.to_json
  }
}

File.open('characters.json', 'w') { |f|
  Character.registered_characters.each_value { |c|
    f.puts c.to_hash.to_json
  }
}
