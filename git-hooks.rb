#!/usr/bin/env ruby
require 'sinatra'

base_path = File.join(ENV['HOME'], 'heaven_container')
git = '/usr/bin/git'

post '/update' do
  branch = params[:branch] or halt 400
  repo = params[:repository] or halt 400

  path = File.expand_path(File.join(base_path, repo))
  halt 400 unless path.start_with? base_path

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

