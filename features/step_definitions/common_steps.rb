def replacePlaceHolders(input_hash)
  input_hash.each do |key,value|
    if value.start_with? "$."
      if last_response_exists()
        @last_json = JSON.parse(read_last_response())
      end
      if not @last_json.nil?
        results = JsonPath.new(value).on(@last_json).to_a.map(&:to_s)
        input_hash[key] = results[0]
      end
    end
    if value.start_with? "#"
      sname, v = value.match(/#(.*)#(.*)/i).captures
      if response_exists(sname)
        res_json = JSON.parse(read_response(sname))
      end
      if not res_json.nil?
        results = JsonPath.new(v).on(res_json).to_a.map(&:to_s)
        input_hash[key] = results[0]
      end
    end
  end
  return input_hash
end

Given /^I set the following configuration for the tests:$/ do |table|
  @config = table.rows_hash
  logs("I set the following configuration for the tests:\n"+PP.pp(@config," "))
  @config = replacePlaceHolders(@config)
  logp("I set the following configuration for the tests:\n"+PP.pp(@config,""))
end

Given /^I set the parameters for request as:$/ do |input|
  @requestparameters = Hash.new
  @requestparameters = input.rows_hash
  logs("I set the parameters for request as:\n"+PP.pp(@requestparameters," "))
  rp = replacePlaceHolders(@requestparameters)
  @requestparameters = Hash.new
  rp.each do |key,value|
    if key.eql? "reqname" or key.eql? "stepname"
      @sname = value
    else
      @requestparameters[key] = value
    end
  end
  logp("I set the parameters for request as:\n"+PP.pp(@requestparameters," "))
end

Given /^I set the headers for requests as:$/ do |input|
  @requestheaders = Hash.new
  @requestheaders = input.rows_hash
  logs("I set the headers for requests as:\n"+PP.pp(@requestheaders," "))
  @requestheaders = replacePlaceHolders(@requestheaders)  
  logp("I set the headers for requests as:\n"+PP.pp(@requestheaders," "))
end

Given /^I send (GET|POST|PUT|DELETE) request to "([^"]*)"(?: with the following:)?$/ do |*args|
  @httpclient = MyHttpClient.new()
  if @config.nil?
    @config = Hash.new
  end
  if @requestparameters.nil?
    @requestparameters = Hash.new
  end
  if @requestheaders.nil?
    @requestheaders = Hash.new
  end
  request_type = args.shift
  path2 = args.shift
  input = args.shift
  indexed=false
  if @sname.nil?
    @sname = Digest::MD5.hexdigest(request_type+":"+path2)
    indexed=true
  end
  stepname = "I send "+request_type+" request to \""+path2+"\" "
  request_opts = {method: request_type.downcase.to_sym}
  path,used = get_request_path(path2,@requestparameters)
  unless input.nil?
    if input.class == Cucumber::Ast::Table
      inputparams = input.rows_hash
      stepname = stepname +" with the following:"+inputparams.to_s
      if inputparams.has_key?("body")
        request_opts[:input] = inputparams['body']
        inputparams.delete('body')
      end
      request_opts[:params] = inputparams
    else
      request_opts[:input] = input
    end
  end
  @requestheaders.each { |key,value|
    @httpclient.header(key,value)
  }
  logs(stepname)
  if not ENV['API_ENDPOINT'].nil?
    @config['API_ENDPOINT'] = ENV['API_ENDPOINT']
  elsif @config['API_ENDPOINT'].nil?
    pute "No API EndPoint provided."
    logf stepname
    fail
  end
  setCookie(@requestparameters['Cookie'])

  @httpclient.send_request(@config['API_ENDPOINT'],path,request_opts)
  @last_response = @httpclient.last_response
  if not @last_response.body.nil?
    begin
      @last_json    = JSON.parse(@last_response.body)
    rescue
    end
    save_last_response(@sname,@last_response.body,indexed)
  end
  logp(stepname)
end

Given /^the response status should be "([^"]*)"$/ do |status|
  stepname = "the response status should be \""+status.to_s+"\""
  logs(stepname)
  if not @httpclient.last_response.code == status
    pute("Expecting "+status.to_s+" Received="+@httpclient.last_response.code)
    if not @last_response.body.nil?
      pute "--------Last Response--------"
      pute @last_response.body
      pute "-----------------------------"
    end
    logf(stepname)
    fail ("Expecting "+status.to_s+" Received="+@httpclient.last_response.code)
  else
    logp(stepname)
  end
end

Then /^the JSON response should (not)?\s?have "([^"]*)"$/ do |negative, json_path|
  stepname = "the JSON response should "
  begin
    json    = JSON.parse(@httpclient.last_response.body)
    results = JsonPath.new(json_path).on(json).to_a.map(&:to_s)
    if not negative.nil?
      stepname += "not have \""+json_path+"\""
      logs(stepname)
      results.should be_empty
    else
      stepname += "have \""+json_path+"\""
      logs(stepname)
      putb @httpclient.last_response.body
      results.should_not be_empty
    end
  rescue
    puts "Response: "+@httpclient.last_response.body
    pute "Invalid JSON in response"
    fail
  end
end

Then /^the response should (not)?\s?contain "([^"]*)"$/ do |negative, content|
  stepname = "the response should "
  result = @httpclient.last_response.body.include?(content)
  if negative.nil?
    stepname = stepname+"not contain \""+content+"\""
    logs(stepname)
    fail if not @httpclient.last_response.body.include?(content)
  else
    stepname = stepname+"contain \""+content+"\""
    logs(stepname)
    fail if @httpclient.last_response.body.include?(content)
  end
  logp(stepname)
end

Then /^the JSON response should (not)?\s?have "([^"]*)" with the text "([^"]*)"$/ do |negative, json_path, text|
  stepname = "the JSON response should "
  begin
    json    = JSON.parse(@httpclient.last_response.body)
    results = JsonPath.new(json_path).on(json).to_a.map(&:to_s)
    if self.respond_to?(:should)
      if not negative.nil?
        stepname = stepname + "not have \""+json_path+"\" with the text \""+text+"\""
        logs(stepname)
        results.should_not include(text), "Expected #{text}, Got #{results}"
      else
        stepname = stepname + "have \""+json_path+"\" with the text \""+text+"\""
        logs(stepname)
        results.should include(text) , "Expected #{text}, Got #{results}"
      end
    else
      if not negative.nil?
        assert !results.include?(text), "Expected #{text}, Got #{results}"
      else
        assert results.include?(text), "Expected #{text}, Got #{results}"
      end
    end
    logp (stepname)
  rescue
    puts "Response: "+@httpclient.last_response.body
    pute "Invalid JSON in response"
    fail
  end
end

