#!/usr/bin/env ruby

require 'socket'

port = 9199

service_sock = TCPServer.open( port )
$stderr.puts service_sock.addr.to_s

loop do
  $stderr.puts "wait client..."
  client_sock = service_sock.accept
  Thread.start(client_sock) do |s|
    $stderr.puts "Hang after accept...: #{s.addr.to_s}"
    sleep 10000
  end
end
