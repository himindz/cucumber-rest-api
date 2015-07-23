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
    puts "Server = "+server
    putg "path="+path
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

  UNESCAPES = {
    'a' => "\x07", 'b' => "\x08", 't' => "\x09",
    'n' => "\x0a", 'v' => "\x0b", 'f' => "\x0c",
    'r' => "\x0d", 'e' => "\x1b", "\\\\" => "\x5c",
    "\"" => "\x22", "'" => "\x27"
  }

  def unescape(str)
    # Escape all the things
    str.gsub(/\\(?:([#{UNESCAPES.keys.join}])|u([\da-fA-F]{4}))|\\0?x([\da-fA-F]{2})/) {
      if $1
        if $1 == '\\' then '\\' else UNESCAPES[$1] end
      elsif $2 # escape \u0000 unicode
        ["#$2".hex].pack('U*')
      elsif $3 # escape \0xff or \xff
        [$3].pack('H2')
      end
    }
  end

  def unescape_json(parameters)
    putg parameters.to_s
    putg unescape(parameters.to_json.to_s)

    return unescape(parameters.to_json.gsub('"{','{').gsub('}"','}'))
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
      if request_opts[:input]
        body = request_opts[:input]
        putg body.to_s
      else
        parameters = unescape_json(request_opts[:params])
        body = parameters
        body = body.gsub("\"[","[").gsub("]\"","]")
      end
    when :put
      request = Net::HTTP::Put.new(uri.request_uri)
      body = nil
      if request_opts[:params]
        parameters = unescape_json(request_opts[:params])
        body = parameters
        body = body.gsub("\"[","[").gsub("]\"","]")
      else
        body = request_opts[:input]
      end
    end
    putb "URI="+uri.to_s
    if not body.nil? and body.to_s.length >0
      putb "Request Body="+body.to_s
      putb "Request Body Length="+body.to_s.length.to_s
            
    end
    return request, body
  end

end
