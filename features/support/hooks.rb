require 'rubygems'
require 'nokogiri'
require 'json'
require 'date'
require 'fileutils'

def find_bg_steps(scenario)
  raw_steps = Array.new
  current_feature = if scenario.respond_to?('scenario_outline')
    scenario.scenario_outline.feature
  else
    scenario.feature
  end
  total_steps = current_feature.feature_elements[0].send(:steps).to_a
  @bgsteps.clear()
  scenario.raw_steps.each do |raw_step|
    raw_steps.push(raw_step.name)
  end
  total_steps.each do |step|
    if step.name == raw_steps[0]
      break
    else
      @bgsteps.push(step.name)
    end
  end
end

def new_feature_started(scenario,scenarioname,featurename)
  putn "::::::::::::::::::::::::::::::::: Starting New Feature :::::::::::::::::::::::::::::::::"
  sinfo = Hash.new
  sinfo['scenario_name'] = scenarioname
  sinfo['feature_name'] =   featurename
  sinfo['completed'] = false
  sinfo['inbg'] = true
  sinfo['step_count'] =0
  find_bg_steps(scenario)
  sinfo['bgsteps'] = @bgsteps
  @rawsteps.clear()
  scenario.raw_steps.each do |raw_step|
    @rawsteps.push(raw_step.name)
  end
  path = Dir.pwd.to_s
  filename = path+'/scenarioinfo.j'
  putn "Filename="+filename
  sinfo['rawsteps'] = @rawsteps
  file = File.open(filename, 'w')
  file.puts sinfo.to_json
  file.close
  return sinfo
end

def new_scenario_started(scenario)
  json = get_scenario_info
  json["completed"] = true
  json['inbg'] = true
  json['step_count'] =0

  @bgsteps = json['bgsteps']
  @rawsteps.clear()
  scenario.raw_steps.each do |raw_step|
    @rawsteps.push(raw_step.name)
  end
  json['rawsteps'] = @rawsteps
  path = Dir.pwd.to_s
  filename = path+'/scenarioinfo.j'
  file = File.open(filename, 'w')
  file.puts json.to_json
  file.close

  return json
end

Before do |scenario|
  @max_wait
  @active_column_size=1
  @inactive_column_size=1
  @resolved_column_size=1
  @cancelled_column_size=1
  @bgsteps = Array.new
  @rawsteps = Array.new
  @step_count = 0

  path = Dir.pwd.to_s
  filename = path+'/scenarioinfo.j'
  featurename = scenario.feature.name.split("\n")[0]
  scenarioname = scenario.name.split("\n")[0]

  putn "============================ Starting New Scenario =========================="
  begin
    putm "Feature Name:"+featurename
    putm "Scenario Name:"+scenarioname
    raw_steps = Array.new
    if File.exist?(filename)
      json = get_scenario_info
      if not json["feature_name"].eql? featurename
        putn "Starting New Feature File"
        json = new_feature_started(scenario,scenarioname,featurename)

      else
        if not json["scenario_name"].eql? scenarioname
          putn "Starting New Scenario"
          json = new_scenario_started(scenario)
        else
          json['scenario_name'] = scenarioname
          json['feature_name'] =   featurename
          json['completed'] = false
          json['inbg'] = true
          json['step_count'] =0
          file = File.open(filename, 'w')
          file.puts json.to_json
          file.close
        end
      end
    else
      putb "Starting new Test Execution"
      sinfo = Hash.new
      sinfo['scenario_name'] = scenarioname
      sinfo['feature_name'] =   featurename
      sinfo['completed'] = false
      sinfo['inbg'] = true
      sinfo['step_count'] =0
      find_bg_steps(scenario)
      sinfo['bgsteps'] = @bgsteps
      @rawsteps.clear()
      scenario.raw_steps.each do |raw_step|
        @rawsteps.push(raw_step.name)
      end
      sinfo['rawsteps'] = @rawsteps
      file = File.open(filename, 'w')
      file.puts sinfo.to_json
      file.close
      json = get_scenario_info
    end
  rescue Exception=>e
    pute "Error: "+e.message
  end

end

After do |scenario|
  json = get_scenario_info
  take_ios_snapshot(scenario)
  if scenario.failed?
    json["completed"] = false

  end
  path = Dir.pwd.to_s
  filename = path+'/scenarioinfo.j'
  file = File.open(filename, 'w')
  file.puts json.to_json
  file.close
  putn "============================================================================="
end


def take_ios_snapshot(scenario)
  total_steps = get_total_steps(scenario)
  raw_steps = scenario.raw_steps
  json = read_scenarioinfo_file(scenario)
  result = false
  step_name = get_current_step_name()
  step_id = get_step_id()
  here = `pwd`.chomp
  step_id = get_step_id()
  
  #if step_name.nil?
   # putn "Step Name is nil. Step ID="+step_id
  #end
  if not step_name.nil?
    md5digest = Digest::MD5.hexdigest(step_name.to_s)
    begin

      if running_bg_steps
        if not background_completed
          #putn "In Background: Executed Step :"+step_name.to_s
        else
          #putn "In Background: Did not execute step:"+step_name.to_s
        end
      else
        #putn "Not In Background: Executed step:"+step_name.to_s
      end
    rescue Exception=>e
      pute  e.backtrace
      return result
    end

  end
  return result
end

def read_scenarioinfo_file(scenario)
  begin
    path = Dir.pwd.to_s
    filename = path+'/scenarioinfo.j'
    file = File.open(filename, "rb")
    contents = file.read
    json =  JSON.parse(contents)
    file.close
  rescue
    featurename = scenario.feature.name.split("\n")[0]
    scenarioname = scenario.name.split("\n")[0]
    sinfo = Hash.new
    sinfo['scenario_name'] = scenarioname
    sinfo['feature_name'] =   featurename
    sinfo['completed'] = false
    sinfo['inbg'] = true
    sinfo['step_count'] =0
    find_bg_steps(scenario)
    sinfo['bgsteps'] = @bgsteps
    @rawsteps.clear()
    scenario.raw_steps.each do |raw_step|
      @rawsteps.push(raw_step.name)
    end
    sinfo['rawsteps'] = @rawsteps
    json = sinfo.to_json
    file = File.open(filename, 'w')
    file.puts sinfo.to_json
    file.close
  end

  return json
end

def get_total_steps(scenario)
  current_feature = if scenario.respond_to?('scenario_outline')
    scenario.scenario_outline.feature
  else
    scenario.feature
  end
  total_steps = current_feature.feature_elements[0].send(:steps).to_a
  return total_steps
end

AfterStep do |scenario|
  @step_count += 1
  step_name = get_current_step_name()
  if not take_ios_snapshot(scenario)
    
  end
  json = read_scenarioinfo_file(scenario)
  json['step_count'] = @step_count
  if @step_count < @bgsteps.length
    json["inbg"] = true
  else
    json['completed']=true
    json["inbg"] = false
  end
  path = Dir.pwd.to_s
  filename = path+'/scenarioinfo.j'
  file = File.open(filename, 'w')
  file.puts json.to_json
  file.close
  logc(step_name)
  save_step_id()

end