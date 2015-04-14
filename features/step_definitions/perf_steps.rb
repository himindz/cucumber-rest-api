def runtest(thrds,loop)
  putb @requestinfo['uri1_name'].to_s
  putb "Threads="+thrds.to_s
  putb "loops ="+loop.to_s
  
  uri1 = @requestinfo['uri_url']
  name1 =   @requestinfo['uri_name'].to_s
  uri2,used = get_request_path(uri1,@requestparameters)
  path,used = append_request_parameters(uri2,@requestinfo)
  path1 = @config['API_ENDPOINT']+path.to_s
 
  test do
    with_json
    threads 2, loops: 15 do
      get name: name1,
      url: path1
    end
  end.run(properties: './common/jmeter.properties')
end

Given /^I execute '(.*)' concurrent threads for '(.*)' iterations using:$/ do |threads,loops,table|
  @requestinfo = table.rows_hash
  runtest(threads,loops)
end

Given /^the average response time should be less than 2 seconds$/ do

end
