#!/usr/bin/env ruby

# If these are unset, this script will look for AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION in the environment
@@aws_access_key=''
@@aws_secret_key=''
@@aws_region=''


class RubyVersionException < StandardError; end
class NamespaceArgumentMissingException < StandardError; end
class MetricnameArgumentMissingException < StandardError; end
class DimensionArgumentMissingException < StandardError; end
class MonitoringTypeArgumentException < StandardError; end
class StatisticTypeArgumentException < StandardError; end
class BadAWSAccessKeysException < StandardError; end

raise RubyVersionException, "Ruby version must be 1.8.7" unless RUBY_VERSION == "1.8.7"

require 'rubygems'
require 'bundler/setup'
require 'aws-sdk'
require 'getopt/long'

opts = Getopt::Long.getopts(
   ["--help"],
   ["--namespace",  Getopt::REQUIRED],
   ["--metricname", Getopt::REQUIRED],
   ["--dimension-name",  Getopt::REQUIRED],
   ["--dimension-value","-v",  Getopt::REQUIRED],
   ["--monitoring-type", "-t", Getopt::REQUIRED],
   ["--statistic",Getopt::REQUIRED]
)

class GetCloudwatchMetric

  attr_accessor :options, :aws, :start_time, :end_time, :period, :statistic

  def initialize options
    self.options = options
    usage if options.key?"help"
    raise NamespaceArgumentMissingException unless options.key?"namespace"
    raise MetricnameArgumentMissingException unless options.key?"metricname"
    raise DimensionArgumentMissingException unless options.key?"dimension-name"
    raise DimensionArgumentMissingException unless options.key?"dimension-value"
    self.aws = AWS::CloudWatch.new(get_aws_options).client
    test_aws_connectivity
    set_time_range
    set_statistic
  end

  def get_aws_options
    access_key = (@@aws_access_key == '' && ENV["AWS_ACCESS_KEY_ID"])     || @@aws_access_key
    secret_key = (@@aws_secret_key == '' && ENV["AWS_SECRET_ACCESS_KEY"]) || @@aws_secret_key
    aws_region = (@@aws_region     == '' && ENV["AWS_REGION"])            || @@aws_region
    {:access_key_id => access_key, :secret_access_key => secret_key, :region => aws_region}
  end

  def set_statistic
    unless options.key?"statistic"
      self.statistic = "Average"
    else
      if options["statistic"] =~ /Minimum|Maximum|Average|Sum|SampleCount/
        self.statistic = options["statistic"]
      else
        raise StatisticTypeArgumentException, "Statistic type must be one of: Minimum, Maximum, Average, Sum, SampleCount. "
      end
    end
  end

  def set_time_range
    unless options.key?"monitoring-type"
      detailed = false
    else
      if options["monitoring-type"] =~ /detailed|basic/
        detailed = true if options["monitoring-type"] == 'detailed'
        detailed = false if options["monitoring-type"] == 'basic'
      else
        raise MonitoringTypeArgumentException, "Monitoring type must be either 'detailed' or 'basic'. "
      end
    end
    if detailed
      self.start_time = time_one_minute_ago
      self.period = 60
    else
      self.start_time = time_five_minutes_ago
      self.period = 360
    end
    self.end_time = time_now
  end

  def time_now
    Time.now.utc.iso8601
  end

  def time_one_minute_ago
    # Not really 1 minute ago, but adds a bit of buffer for amazon's silliness 
    (Time.now - 90).utc.iso8601
  end

  def time_five_minutes_ago
    # Not really 5 minutes ago, but adds a bit of buffer for amazon's silliness 
    (Time.now - (60*7+30)).utc.iso8601
  end

  def run!
    ret = aws.get_metric_statistics({
            :namespace => options["namespace"],
            :metric_name => options["metricname"],
            :dimensions => [{:name => options["dimension-name"],:value => options["dimension-value"]}],
            :period => period,
            :start_time => start_time,
            :end_time => end_time,
            :statistics => [statistic]})
    begin
      symbol = statistic.downcase.to_sym
      symbol = :sample_count if symbol == :samplecount
      puts ret[:datapoints][0][symbol]
    rescue
      exit 1
    end
  end

  def test_aws_connectivity
    begin
      aws.describe_alarms(:max_records => 1)
    rescue
      raise BadAWSAccessKeysException, <<-EOF

You cannot access AWS due to one of the following reasons:
  - @aws_access_key and/or @aws_access_key are incorrect/invalid/disabled in #{File.expand_path(__FILE__)}
  - Environment variables AWS_ACCESS_KEY_ID and/or AWS_SECRET_ACCESS_KEY are incorrect/invalid/disabled
  - The AWS keys provided do not have access to Cloudwatch
  - your server is not synced with NTP
  - The Region setting in the environment or this file is incorrect
        EOF
    end
  end
  
  def usage
    puts <<-EOF
      Usage: #{$0}

        -h, --help              This Message
        -n, --namespace         Namespace (AWS/Autoscaling, AWS/EC2, etc...)
        -m, --metricname        Metric Name (GroupInServiceInstances,EstimatedCharges, etc...)
        -d, --dimension-name    Dimension Name (AutoScalingGroupName, etc...)
        -v, --dimension-value   Dimension Value
        -t, --monitoring-type   detailed|basic                            Default: basic
        -s, --statistic         Minimum|Maximum|Average|Sum|SampleCount   Default: Average
      EOF
    exit 1
  end

end

inst = GetCloudwatchMetric.new(opts)
inst.run!
