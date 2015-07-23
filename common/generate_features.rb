#!/usr/bin/ruby
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: generate_features.rb [options]"

  opts.on('-t', '--tags TAGS', 'Tags') { |v| options[:tags] = v }
  opts.on('-f', '--featurename FEATURENAME', 'Feature Name') { |v| options[:featurename] = v }
  opts.on('-b', '--background BACKGROUND', 'Background of Feature') { |v| options[:background] = v }
  opts.on('-s', '--scenario SCENARIO', 'Scenario') { |v| options[:scenario] = v }

end.parse!

contents = Array.new
scenario_only = Array.new

if not options[:featurename].nil?
  feature_file = 'features/app_features/'+options[:featurename]+".feature"
  puts "======================"
  add_background = true
  if File.exist?(feature_file)
    file = File.open(feature_file,"rb")
    file.each_line {|line|
      contents.push line
    }
    file.close
    start_pushing = false
    contents.each {|line|
      if line.include?("Scenario:")
        start_pushing = true
      end
      if start_pushing
        scenario_only.push(line)
      end
    }
  end
  newfile = File.open(feature_file, "w")
  
  #Write the background provided 
  newfile.write(options[:background])
  newfile.puts("")
  newfile.puts("")

  
  #Write the existing scenario
  scenario_only.each {|line|
    newfile.puts(line)
  }
  newfile.puts("")

  #Write the new scenarios
  newfile.puts(options[:tags])
  newfile.puts(options[:scenario])
  newfile.puts("")

  newfile.close
  
  file = File.open(feature_file,"rb")
  contents = file.read
  file.close
  puts contents
end
