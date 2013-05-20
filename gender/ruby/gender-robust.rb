#!/usr/bin/env ruby

host = "127.0.0.1"
port = 9199
name = "test"

RETRY_MAX = 5
RETRY_INTERVAL = 3.0

require 'jubatus/classifier/client'
require 'jubatus/classifier/types'

if !ARGV.empty?
  host_spec = ARGV[0]
  if host_spec =~ /^(.+):(\d+)$/
    host = $1
    port = $2.to_i
  else
    host = $1
  end
end
$stderr.puts "connect server #{host}:#{port}"

client = Jubatus::Classifier::Client::Classifier.new(host, port)

begin
  train_data =
    [
     ["male",   Jubatus::Classifier::Datum.new([["hair", "short"], ["top", "sweater"], ["bottom", "jeans"]], [["height", 1.70]])],
     ["female", Jubatus::Classifier::Datum.new([["hair", "long"],  ["top", "shirt"],   ["bottom", "skirt"]], [["height", 1.56]])],
     ["male",   Jubatus::Classifier::Datum.new([["hair", "short"], ["top", "jacket"],  ["bottom", "chino"]], [["height", 1.65]])],
     ["female", Jubatus::Classifier::Datum.new([["hair", "short"], ["top", "T shirt"], ["bottom", "jeans"]], [["height", 1.72]])],
     ["male",   Jubatus::Classifier::Datum.new([["hair", "long"],  ["top", "T shirt"], ["bottom", "jeans"]], [["height", 1.82]])],
     ["female", Jubatus::Classifier::Datum.new([["hair", "long"],  ["top", "jacket"],  ["bottom", "skirt"]], [["height", 1.43]])],
     #   ["male",   Jubatus::Classifier::Datum.new([["hair", "short"], ["top", "jacket"],  ["bottom", "jeans"]], [["height", 1.76]])],
     #   ["female", Jubatus::Classifier::Datum.new([["hair", "long"],  ["top", "sweater"], ["bottom", "skirt"]], [["height", 1.52]])],
    ]

  retry_count = 0
  begin
    client.train(name, train_data)

  rescue MessagePack::RPC::TimeoutError, MessagePack::RPC::TransportError => e
    raise if (retry_count += 1) >= RETRY_MAX

    client.get_client.close
    $stderr.puts e
    sleep RETRY_INTERVAL
    retry
  end

  sleep 3

  test_data =
    [
     Jubatus::Classifier::Datum.new([["hair", "short"], ["top", "T shirt"], ["bottom", "jeans"]], [["height", 1.81]]),
     Jubatus::Classifier::Datum.new([["hair", "long"],  ["top", "shirt"],   ["bottom", "skirt"]], [["height", 1.50]]),
    ]

  retry_count = 0
  begin
    results = client.classify(name, test_data)

  rescue MessagePack::RPC::TimeoutError, MessagePack::RPC::TransportError => e
    raise if (retry_count += 1) >= RETRY_MAX

    client.get_client.close
    $stderr.puts e
    sleep RETRY_INTERVAL
    retry
  end

  results.each { |result|
    result.each { |(label, score)|
      puts(label + " " + score.to_s)
    }
    puts
  }

rescue MessagePack::RPC::RPCError => e
  $stderr.puts e
ensure
  client.get_client.close
end
