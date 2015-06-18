#!/usr/bin/ruby
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: generate_features_simple.rb [options]"

  opts.on('-t', '--tags TAGS', 'Tags') { |v| options[:tags] = v }
  opts.on('-f', '--featurename FEATURENAME', 'Feature Name') { |v| options[:featurename] = v }
  opts.on('-s', '--featuretext FEATURETEXT', 'Feature Text') { |v| options[:featuretext] = v }

end.parse!

contents = Array.new
scenario_only = Array.new

if not options[:featurename].nil?
  feature_file = 'features/app_features/'+options[:featurename]+".feature"
  puts "======================"
  
  newfile = File.open(feature_file, "w")
  
  #Write the background provided 
  newfile.write(options[:featuretext])
  newfile.puts("")
  newfile.puts("")
  
  newfile.close
  
  file = File.open(feature_file,"rb")
  contents = file.read
  file.close
  puts contents
end
