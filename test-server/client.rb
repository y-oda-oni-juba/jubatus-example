#!/usr/bin/env ruby

require 'socket'

host = 'localhost'
port = 9199

if !ARGV.empty?
  host_spec = ARGV[0]
  if host_spec =~ /^(.+):(\d+)$/
    host = $1
    port = $2.to_i
  else
    host = $1
  end
end
$stderr.puts "connect to #{host}:#{port}"

sock = TCPSocket.open( host, port )
sock.write("hello\n")
sock.close

