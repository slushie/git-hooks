#!/usr/bin/env ruby
require 'net/http'
require 'uri'

remote_hook = URI.parse('http://git-hooks.heaven.fu.cr/update')

ARGV.each do |refname|
  next unless refname.match %r(^refs/heads/)

  branch = refname.sub %r(^refs/heads/), ''
  repo_path = File.expand_path(ENV['GIT_DIR'] || Dir.pwd)
  repo = File.basename(repo_path.sub(%r(/?.git/?$), ''))

  response = Net::HTTP.post_form remote_hook, {
    'branch'      => branch,
    'repository'  => repo
  }

  if response.code.to_i == 406
    puts response.body.chomp
    next
  end

  if response.code.to_i != 200
    puts "Remote hook #{remote_hook} failed: #{response.code} #{response.message}\n"
  end

  puts response.body
end