#! /usr/bin/env ruby
#
# metrics-gearman
#
# DESCRIPTION:
#  This plugin logs the gearman stats
#
# OUTPUT:
#   metric-data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: gearman-ruby
#   gem: sensu-plugin
#
# USAGE:
#   #YELLOW
#
# NOTES:
#
# LICENSE:
#   Copyright 2016 Aaron Brady <aaron@iweb.co.uk>
#   Copyright 2014 99designs, Inc <devops@99designs.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/metric/cli'
require 'json'
require 'gearman/server'

#
# Check Gearman Queues
#
class GearmanMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :host,
         short: '-H HOST',
         default: 'localhost'
  option :port,
         short: '-p PORT',
         default: '4730'
  option :queue,
         short: '-q QUEUE'
  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.gearman"

  def run
    begin
      gearman = Gearman::Server.new(
        "#{config[:host]}:#{config[:port]}"
      )
    rescue => e
      critical "Failed to connect: (#{e})"
    end

    stats = {}

    if config[:queue]
      stat = gearman.status[config[:queue]]
      if stat.nil?
        warning "Queue #{config[:queue]} not found"
      else
        stats = {config[:queue] => stat}
      end
    else
      stats = gearman.status
    end

    stats.each do |key, counts|
      counts.each do |count_key, count_value|
        output "#{config[:scheme]}.#{key}.#{count_key}", count_value
      end
    end

    ok
  end
end
