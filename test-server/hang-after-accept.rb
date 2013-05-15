#!/usr/bin/env ruby

require 'socket'

port = 9199

service_sock = TCPServer.open( port )
$stderr.puts service_sock.addr.to_s

$stderr.puts "wait client..."

client_sock = service_sock.accept

$stderr.puts "Hang after accept..."

sleep 10000
