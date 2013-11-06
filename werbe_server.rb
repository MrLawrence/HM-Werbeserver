require 'socket'
require 'logger'

log = Logger.new(STDOUT)
log.level = Logger::INFO

target_url = 'mmix.cs.hm.edu'
ip = 'localhost'
port = 8082

server = TCPServer.new(ip, port)

log.info "Proxy started! Listening to #{ip}:#{port}"
log.info "Redirecting to #{target_url}"


def advertise response_array
  response_array.join.gsub(/<img([^>])*src=(["'])([^"']*)(["'])([^>]*)>/, "<img src=\"http://fi.cs.hm.edu/fi/hm-logo.png\">")
end

loop do
  client = server.accept
  log.info 'Accepted connection'
  target_host = TCPSocket.open(target_url, 80)


  client_request = []
  while line = client.gets and line !~ /^\s*$/
    if line.include?('Host: ')
      line = "Host: #{target_url}\r\n"
    end
    client_request << line
  end
  log.warn "Request is empty!" if client_request.empty?

  if not client_request.empty?
    prepared_request = client_request.join.chomp + "\r\n\r\n"
    target_host.write prepared_request
    log.debug prepared_request

    log.info "Sent request to #{target_url}"

    target_response = []
    while line = target_host.gets
      target_response << line
    end
    log.info "Received response from #{target_url}"
    ad_response = advertise(target_response)
    log.debug ad_response
    client.write ad_response
  end

  target_host.close
  client.close
end

