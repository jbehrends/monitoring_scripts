#!/usr/bin/env ruby
#
# This script scrapes the Arris SB6183 cable modem's status pages for various
# metrics and then sends those metrics to graphite for trending.
#
# By: Josh Behrends - 01/17/2016
#
# Tested on: Arris SB6183
# Firmware:  D30CM-OSPREY-1.5.0.1-GA-01-NOSH
#
# Notes: Arris's HTML sucks and has a few unclosed html tags.  So we're using the
#        nokogumbo gem to parse and fix the malformed html.
#

require 'nokogumbo'
require 'simple-graphite'

# Setup our graphite server here
g = Graphite.new
g.host = '127.0.0.1'
g.port = 2003

# Metric base
g_base = 'network.sb6183'

# Grab the status page for parsing downstream/upstream channels
page = Nokogiri::HTML(Nokogiri::HTML5.get('http://192.168.100.1/RgConnect.asp').to_html)

# Downstream channels
rows = page.css('#bg3 > div.container > div.content > form > center:nth-child(5) > table > tbody > tr')
down_details = rows.collect do |row|
  detail = {}
  [
    [:channel,     'td[1]/text()'],
    [:channel_id,  'td[4]/text()'],
    [:freq,        'td[5]/text()'],
    [:power,       'td[6]/text()'],
    [:snr,         'td[7]/text()'],
    [:corrected,   'td[8]/text()'],
    [:uncorrected, 'td[9]/text()'],
  ].each do |name, xpath|
    detail[name] = row.at_xpath(xpath).to_s.strip
  end
  detail
end
#puts down_details

# Upstream channels
rows = page.css('#bg3 > div.container > div.content > form > center:nth-child(8) > table > tbody > tr')
up_details = rows.collect do |row|
  detail = {}
  [
    [:channel,     'td[1]/text()'],
    [:channel_id,  'td[4]/text()'],
    [:symbol_rate, 'td[5]/text()'],
    [:freq,        'td[6]/text()'],
    [:power,       'td[7]/text()'],
  ].each do |name, xpath|
    detail[name] = row.at_xpath(xpath).to_s.strip
  end
  detail
end
#puts up_details

# Grab the product information page so we can get the uptime
page = Nokogiri::HTML(Nokogiri::HTML5.get('http://192.168.100.1/RgSwInfo.asp').to_html)

raw_uptime = page.css('#bg3 > div.container > div.content > table:nth-child(5) > tbody > tr:nth-child(2) > td:nth-child(2)').text

# parse uptime (77 days 16h:55m:35s) into seconds
uptime = (raw_uptime.match(/(^\d*)\sdays\s(\d.)h:(\d.)m:(\d.)s/)[1].to_i * 86400) +
         (raw_uptime.match(/(^\d*)\sdays\s(\d.)h:(\d.)m:(\d.)s/)[2].to_i * 3600) +
         (raw_uptime.match(/(^\d*)\sdays\s(\d.)h:(\d.)m:(\d.)s/)[3].to_i * 60) +
         (raw_uptime.match(/(^\d*)\sdays\s(\d.)h:(\d.)m:(\d.)s/)[4].to_i)

#puts uptime

# Send collected metrics to graphite
down_details.each do | channel |
  if channel[:channel] != ''
    g.send_metrics({
      g_base + '.channels.downstream.' + channel[:channel] + '.power_dBmV' => channel[:power].match(/-?.?[0-9]?+.?[0-9]+/).to_s,
      g_base + '.channels.downstream.' + channel[:channel] + '.snr' => channel[:snr].match(/-?.?[0-9]?+.?[0-9]+/).to_s,
      g_base + '.channels.downstream.' + channel[:channel] + '.error_corrected' => channel[:corrected],
      g_base + '.channels.downstream.' + channel[:channel] + '.error_uncorrected' => channel[:uncorrected]
    })
  end
end

up_details.each do | channel |
  if channel[:channel] != ''
    g.send_metrics({
      g_base + '.channels.upstream.' + channel[:channel] + '.power_dBmV' => channel[:power].match(/-?.?[0-9]?+.?[0-9]+/).to_s
    })
  end
end

g.send_metrics({
  g_base + '.uptime.seconds' => uptime.to_s
})
