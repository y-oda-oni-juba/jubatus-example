#!/usr/bin/env ruby

require 'jubatus/classifier/client'
require 'jubatus/classifier/types'

host = "127.0.0.1"
port = 9199
name = "test"

module Retryable
  
  RETRY_MAX = 5
  RETRY_INTERVAL = 3.0

  def with_retry
    Impl.new(self)
  end

  class Impl
    def initialize(target, max = RETRY_MAX, interval = RETRY_INTERVAL)
      @target = target
      @max = max
      @interval = interval
    end
    def method_missing(name, *args)
      retry_count = 0
      begin
        @target.__send__(name, *args)

      rescue MessagePack::RPC::TimeoutError, MessagePack::RPC::TransportError => e
        raise if (retry_count += 1) >= @max

        @target.get_client.close
        $stderr.puts e
        sleep @interval
        retry
      end
    end
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

client = Jubatus::Classifier::Client::Classifier.new(host, port).extend Retryable

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

  client.with_retry.train(name, train_data)

  sleep 3

  test_data =
    [
     Jubatus::Classifier::Datum.new([["hair", "short"], ["top", "T shirt"], ["bottom", "jeans"]], [["height", 1.81]]),
     Jubatus::Classifier::Datum.new([["hair", "long"],  ["top", "shirt"],   ["bottom", "skirt"]], [["height", 1.50]]),
    ]

  results = client.with_retry.classify(name, test_data)

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
