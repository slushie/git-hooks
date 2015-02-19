#!/usr/bin/env ruby
require 'sinatra'
require 'json'

git = '/usr/bin/git'
config_file = File.join(ENV['HOME'], '.git-hooks.conf')

if File.exists? config_file
  repository_paths = File.readlines(config_file).map do |line|
    line.chomp.split(/\s+/)
  end.to_h
else
  repository_paths = Hash.new
end


post '/update' do
  if request.media_type == 'application/json'
    request.body.rewind
    data = JSON.parse(request.body.read)
    branch = data['ref']
    repo = data['repository']['name']
  else
    branch = params[:branch]
    repo = params[:repository]
  end

  halt 400, "Missing required parameters" unless branch and repo
  branch.sub!(%r,^refs/heads/,,'')

  path = repository_paths.fetch(repo) do 
    halt 400, "Repository #{repo} is not configured"
  end

  env = { 'GIT_WORK_TREE' => path, 'GIT_DIR' => File.join(path, '.git') }
  redirect = { err: [:child, :out] }

  checked_out = IO.popen(env, "#{git} rev-parse --abbrev-ref HEAD", redirect) { |io| io.read.chomp }
  
  halt 401, "Git failed: #{checked_out}" unless $?.success?
  halt 406, "Mismatched repository: #{checked_out} != #{branch}\n" if checked_out != branch

  stream do |out|
    IO.popen(env, "#{git} pull", redirect) do |io|
      until io.eof?
        out << io.readline
      end
    end
  end
end

