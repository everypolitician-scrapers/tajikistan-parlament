#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_en(url)
  noko = noko_for(url)
  noko.css('table.contentpaneopen p').map(&:text).map(&:tidy).reject(&:empty?)
  noko.css('table.contentpaneopen p').select { |n| n.text.match /^\d+/ }.map(&:text)
  
end

def scrape_tj(url)
  noko = noko_for(url)
  noko.css('table.contentpaneopen p').select { |n| n.text.match /^\d+/ }.map { |n|
    [ n.text, URI.join(url, n.css('a/@href').text) ]
  }
end

def scrape_person(url)
  noko = noko_for(url)
  data = { 
    image: noko.css('table.contentpaneopen img/@src').text,
  }
  data[:image] = URI.join(url, URI.escape(data[:image])).to_s unless data[:image].to_s.empty?
  data
end

en = scrape_en('http://www.parlament.tj/en/index.php?option=com_content&view=article&id=53&Itemid=86')
tj = scrape_tj('http://www.parlament.tj/index.php?option=com_content&view=article&id=53&Itemid=86')
tj.each_with_index do |p_tj, i|
  data = { 
    id: p_tj.last.to_s[/id=(\d+)/, 1],
    name: en[i].sub(/^\d+\.\s*/,''),
    name__tj: p_tj.first.sub(/^\d+\.\s*/,''),
    source: p_tj.last.to_s,
  }.merge(scrape_person(p_tj.last))
  ScraperWiki.save_sqlite([:id], data)
  puts data[:name]
end

