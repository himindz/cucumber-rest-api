require 'colorize'

def append_request_parameters(path,requestparameters)
  used = Array.new
  keys = Array.new
  used.push("uri_name")
  used.push("uri_url")
  #Append remaining parameters
  requestparameters.each do |key, value|
    if not used.include? key and not key.include?"Cookie"
      if not path.include?"\?"
        path = path+"?"+key+"="+value
      else
        path = path+"&"+key+"="+value
      end

    end

  end

  return path,used
end

def get_request_path(path,requestparameters)
  used = Array.new
  keys = Array.new

  path.scan(/{(.+?)}/) do |key|
    keys.push(key)
  end
  keys.each do |key|
    mykey = key[0]
    if requestparameters.has_key?(mykey)
      path = path.gsub("{"+mykey+"}", requestparameters[mykey])
      used.push(mykey)

    end
  end
#Append remaining parameters
  
  requestparameters.each do |key, value|
    if not used.include? key and not key.include?"Cookie"
      if not path.include?"\?"
        path = path+"?"+key+"="+value
      else
        path = path+"&"+key+"="+value
      end

    end

  end
  return path,used
end

def puts(o)
  timenow = Time.now
  if o.is_a? Array
    super(timenow.to_s+" OUT: "+o.to_s)
  else
    super(timenow.to_s+" OUT: "+o)
  end
end

def putn(o)
  timenow = Time.now
  if o.is_a? Array
    msg = timenow.to_s+" OUT: "+o.to_s
  else
    msg = timenow.to_s+" OUT: "+o
  end
  Kernel.puts(msg)
end

def pute(o)
  timenow = Time.now
  if o.is_a? Array
    msg = timenow.to_s+" OUT: "+o.to_s
  else
    msg = timenow.to_s+" OUT: "+o
  end
  Kernel.puts(msg.red)
end

def putg(o)
  timenow = Time.now
  if o.is_a? Array
    msg = timenow.to_s+" OUT: "+o.to_s
  else
    msg = timenow.to_s+" OUT: "+o
  end
  Kernel.puts(msg.green)
end

def putb(o)
  timenow = Time.now
  if o.is_a? Array
    msg = timenow.to_s+" OUT: "+o.to_s
  else
    msg = timenow.to_s+" OUT: "+o
  end
  Kernel.puts(msg.blue)
end

def putm(o)
  timenow = Time.now
  if o.is_a? Array
    msg = timenow.to_s+" OUT: "+o.to_s
  else
    msg = timenow.to_s+" OUT: "+o
  end
  Kernel.puts(msg.magenta)
end

def logs(o)
  timenow = Time.now
  msg = "*********** "+timenow.to_s+" OUT: Step:"+o.to_s+"   :Started *********"
  Kernel.puts msg.blue
end

def logf(o)
  timenow = Time.now
  msg = "*********** "+timenow.to_s+" OUT: Step:"+o.to_s+"   :FAILED *********"
  Kernel.puts msg.red
end

def logp(o)
  timenow = Time.now
  msg = "*********** "+timenow.to_s+" OUT: Step:"+o.to_s+"   :PASSED *********"
  Kernel.puts  msg.green
end

def logc(o)
  timenow = Time.now
  msg = "*********** "+timenow.to_s+" OUT: Step:"+o.to_s+"   :Completed *********"
  Kernel.puts  msg.blue
end

def running_bg_steps
  path = Dir.pwd.to_s
  filename = path+'/scenarioinfo.j'
  if File.exist?(filename)
    file = File.open(filename, "rb")
    contents = file.read
    json =  JSON.parse(contents)
    file.close
    if json["inbg"]
      return true
    else
      return false
    end
  end

  return false
end

def get_scenario_info
  path = Dir.pwd.to_s
  filename = path+'/scenarioinfo.j'
  if File.exist?(filename)
    file = File.open(filename, "rb")
    contents = file.read
    json =  JSON.parse(contents)
    file.close
    return json
  end
  return Hash.new
end

def get_current_step_number
  json = get_scenario_info
  if json.has_key?('step_count')
    return json['step_count']
  end
  return 0

end

def get_current_step_name
  json = get_scenario_info
  stepcount = 1
  if json.has_key?('step_count')
    stepcount= json['step_count']+1
    bgsteps = json['bgsteps']
    rawsteps = json['rawsteps']
    if stepcount <= bgsteps.length
      name = bgsteps[stepcount-1]
    else
      count = stepcount - bgsteps.length
      name = rawsteps[count-1]
    end
  end

  return name
end

def background_completed
  json = get_scenario_info
  if json.has_key?('completed')
    if json["completed"]
      return true
    else
      return false
    end
  end
  return true
end

def get_step_id
  json = get_scenario_info
  if json.has_key?('step_id')
    if json["step_id"]
      return json["step_id"]
    else
      return "0"
    end
  end
  return "0"
end

def save_step_id()
  step_id = DateTime.now.strftime("%d%b%Y%H%M%S")
  json = get_scenario_info
  json["step_id"]=step_id
  path = Dir.pwd.to_s
  filename = path+'/scenarioinfo.j'
  file = File.open(filename, 'w')
  file.puts json.to_json
  file.close
  #putb "Saving Step ID ="+step_id.to_s
  return
end