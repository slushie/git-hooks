#!/usr/bin/env ruby
require 'net/http'
require 'uri'

callback_hooks = File.readlines('remote-git-hooks.txt').map(&:strip)

ARGV.each do |refname|
  next unless refname.match %r(^refs/heads/)

  branch = refname.sub %r(^refs/heads/), ''
  repo_path = File.expand_path(ENV['GIT_DIR'] || Dir.pwd)
  repo = File.basename(repo_path.sub(%r(/?.git/?$), ''))

  callback_hooks.each do |remote|
    response = 
      begin
        Net::HTTP.post_form URI.parse(remote), {
          'branch'      => branch,
          'repository'  => repo
        }
      rescue => ex
        puts "POST #{remote} failed: #{ex.inspect}"
        next
      end

    if response.code.to_i == 406
      puts "#{remote} => #{response.body.chomp}"
      next
    end

    if response.code.to_i != 200
      puts "Remote hook #{remote} failed: #{response.code} #{response.message}\n"
    end

    puts "#{remote} => #{response.body}"
  end
end
