#!/usr/bin/env ruby

require 'jubatus/classifier/client'
require 'jubatus/classifier/types'

host = "127.0.0.1"
port = 9199
name = "test"

RETRY_MAX = 5
RETRY_INTERVAL = 3.0

def with_retry(client, max = RETRY_MAX, interval = RETRY_INTERVAL)
  retry_count = 0
  begin
    yield(client)

  rescue MessagePack::RPC::TimeoutError, MessagePack::RPC::TransportError => e
    raise if (retry_count += 1) >= max

    client.get_client.close
    $stderr.puts e
    sleep interval
    retry
  end
end

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

with_retry(client) { |c| c.train(name, train_data) }

$stdout.write "now, classify: "
$stdout.flush
$stdin.gets

test_data =
  [
   Jubatus::Classifier::Datum.new([["hair", "short"], ["top", "T shirt"], ["bottom", "jeans"]], [["height", 1.81]]),
   Jubatus::Classifier::Datum.new([["hair", "long"],  ["top", "shirt"],   ["bottom", "skirt"]], [["height", 1.50]]),
  ]

results = with_retry(client) { |c| c.classify(name, test_data) }

results.each { |result|
  result.each { |(label, score)|
    puts(label + " " + score.to_s)
  }
  puts
}
