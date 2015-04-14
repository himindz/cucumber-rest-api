require "net/http"
require "net/https"
require "uri"
require 'json'

class MyHttpClient
  GET = 0
  POST= 1
  PUT = 2
  DELETE=3
  @headers == nil
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def present?
    !blank?
  end

  def header(key, value)
    if @headers == nil
      @headers = Hash.new(0)
    end
    @headers[key] = value
  end
  
  def headers
    @headers
  end

  def last_response
    return @response
  end

  def send_request(server,path,request_opts)
    req = server + path
    uri = URI.parse(req)

    http = Net::HTTP.new(uri.host, uri.port)
    request, body = create_request(uri, request_opts)
    if @headers != nil
      @headers.each { |k,v| request.add_field(k, v) }
      @headers = nil
    end

    if req.include? "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      
      @response = http.request(request,body)
      
    else
      @response = http.request(request,body)
    end
  end

  def create_request(uri,request_opts)
    body = nil
    case request_opts[:method]
    when :get
      request = Net::HTTP::Get.new(uri.request_uri)
    when :delete
      request = Net::HTTP::Delete.new(uri.request_uri)
    when :post
      request = Net::HTTP::Post.new(uri.request_uri)
      if :params
        body = request_opts[:params].to_json
        body = body.gsub("\"[","[").gsub("]\"","]")
        body = body.gsub("\"444\"","444")
      else
        body = request_opts[:input]
      end
    when :put
      request = Net::HTTP::Put.new(uri.request_uri)
      body = nil
      if request_opts[:params]
        body = request_opts[:params].to_json
        body = body.gsub("\"[","[").gsub("]\"","]")
        body = body.gsub("\"444\"","444")
      else
        body = request_opts[:input]
      end
    end
    putb "URI="+uri.to_s
    #putb "Request created="+body.to_s
    
    return request, body
  end
  
end
