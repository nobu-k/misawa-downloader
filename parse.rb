# -*- coding: utf-8 -*-
require 'nokogiri'
require 'nkf'

class Character
  @@characters = {}
  @@characters_by_name = {}

  attr_reader :id, :name, :age

  def initialize(id, name, age)
    @id = id
    @name = name
    @age = age
  end

  def to_hash
    {
      'cid' => @id,
      'name' => @name,
      'age' => @age
    }
  end

  def self.get(id)
    @@characters[id]
  end

  def self.get_by_name(name)
    @@characters_by_name[name]
  end

  def self.register(id, name, age)
    new_char = Character.new(id, name, age)
    if @@characters[id].nil?
      @@characters[id] = new_char
      @@characters_by_name[name] = [new_char]
      new_char
    else
      raise "Detected duplicated cid: #{id} for #{name} and #{get(id).name}" unless @@characters[id].name == name
      # Because Rei has two ages, each value of @@characters_by_name must be an Array.
      res = @@characters_by_name[name].detect { |c|
        c.id == id and c.age == age # Zero has two ages
      }
      unless res
        res = new_char
        @@characters_by_name[name] << new_char
      end
      res
    end
  end

  def self.register_from_xml_node(info)
    raise "Format of the cid's link may have been changed" unless info.name == "a"
    unless info['href'] =~ /\?cid=([0-9]+)$/
      raise "Format of the cid may have been changed"
    end

    cid = $1.to_i

    unless info.text =~ /^(.+?)(\(([0-9]+)\))?$/
      raise "Format of the character's name may have been changed"
    end

    name = $1
    age = nil
    age = $3.to_i if $3

    # @age may be nil because of the Sun.
    Character.register(cid, name, age)
  end

  def self.registered_characters
    @@characters
  end
end

class Entry
  attr_reader :id, :character, :entry_number, :title, :img_urls, :date, :time

  def initialize(id, char, entry_number, title, img_urls, date, time)
    @id = id
    @character = char
    @entry_number = entry_number
    @title = title
    @img_urls = img_urls
    @date = date
    @time = time
  end

  def to_hash
    {
      'eid' => @id,
      'cid' => @character.id,
      'entry_number' => @entry_number,
      'title' => @title,
      'img_urls' => @img_urls,
      'date' => @date,
      'time' => @time
    }
  end

  def self.from_xml(eid, document)
    entry = document.xpath("//div[@class='entry_area']")
    raise "There are too many entry_area in one page" unless entry.length == 1
    entry = entry[0]

    lists = entry.xpath("center/ul[@class='state']")[0].element_children
    raise "Format of the page may have been changed" unless lists.length == 5

    raw_title = entry.xpath("h2")[0].text
    unless raw_title =~ /^惚れさせ(.+?).「(.+)」$/
      raise "Format of the title may have been changed"
    end
    title = $2
    entry_number = NKF::nkf('-Z1 -Ww', $1).to_i

    raw_date = lists[0].text
    unless raw_date =~ /.*?([0-9]+).([0-9]+).([0-9]+)/
      raise "Format of the date may have been changed"
    end
    date = $1 + $2 + $3

    img_urls = entry.xpath("//img[@class='pict']").map { |e| e['src'] }
    char_info = lists[1].child

    time = lists[2].child.text.gsub(':', '').to_i
    time = time / 100 * 60 * 60 + time % 100 * 60

    new_char = Character.register_from_xml_node(char_info)
    Entry.new(eid, new_char, entry_number, title, img_urls, date, time)
  end
end
