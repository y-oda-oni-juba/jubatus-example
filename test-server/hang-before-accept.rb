#!/usr/bin/env ruby

require 'socket'

port = 9199

service_sock = TCPServer.open( port )
$stderr.puts service_sock.addr.to_s

$stderr.puts "Hang without accept..."

sleep 10000
