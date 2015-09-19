require 'uri'
require 'json'
require 'net/http'
require 'rexml/document'

class Board < Struct.new(:name, :url); end

if File.exist?('.result_cache')
  # Read from cache
  json = File.read('.result_cache')
  data = JSON.parse(json)
  boards = data.map { |d| Board.new(d['name'], d['url']) }
else
  # Search and write to cache
  key = File.read('.auth_key').strip
  token = File.read('.auth_token').strip
  uri = URI("https://api.trello.com/1/members/me/boards?key=#{key}&token=#{token}")
  body = Net::HTTP.get(uri)
  data = JSON.parse(body)
  boards = data.map { |d| Board.new(d['name'], d['url']) }

  File.open('.result_cache', 'w') do |file|
    file.truncate(0)
    file.puts boards.map(&:to_h).to_json
  end
end

query = Regexp.new(ARGV[0], 'i')
results = boards.select { |b| b.name =~ query }

document = REXML::Document.new
items = REXML::Element.new('items')

results.each do |result|
  item = REXML::Element.new('item')
  item.add_attribute 'autocomplete', result.name
  item.add_attribute 'arg', result.url

  title = REXML::Element.new('title')
  title.text = result.name

  subtitle = REXML::Element.new('subtitle')
  subtitle.text = "Open #{result.url}"

  item.add_element title
  item.add_element subtitle

  items.add_element item
end

document.add_element items
puts document.to_s
