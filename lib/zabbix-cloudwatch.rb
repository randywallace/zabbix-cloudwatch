require 'zabbix-cloudwatch/version'
require 'aws-sdk'

module ZabbixCloudwatch
  class GetCloudwatchMetric
    class NamespaceArgumentMissingException < StandardError; end
    class MetricnameArgumentMissingException < StandardError; end
    class DimensionArgumentMissingException < StandardError; end
    class MonitoringTypeArgumentException < StandardError; end
    class StatisticTypeArgumentException < StandardError; end
    class AwsAccessKeyMissingException < StandardError; end
    class AwsSecretKeyMissingException < StandardError; end
    class BadAWSAccessKeysException < StandardError; end
  
    attr_accessor :options, :aws, :start_time, :end_time, :period, :statistic
  
    def initialize options = {}
      self.options = options
      usage if options.key?"help"
      raise NamespaceArgumentMissingException unless options.key?"namespace"
      raise MetricnameArgumentMissingException unless options.key?"metricname"
      raise DimensionArgumentMissingException unless options.key?"dimension-name"
      raise DimensionArgumentMissingException unless options.key?"dimension-value"
      self.aws = Aws::CloudWatch::Client.new(get_aws_options)
    end

    def get_aws_options
      raise AwsAccessKeyMissingException unless options.key?"aws-access-key"
      raise AwsSecretKeyMissingException unless options.key?"aws-secret-key"
      if options.key?("aws-region") && options['aws-region'] != ''
        region = options["aws-region"]
      else
        region = 'us-east-1'
      end
      {:access_key_id => options["aws-access-key"], :secret_access_key => options["aws-secret-key"], :region => region}
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
      test_aws_connectivity
      set_time_range
      set_statistic
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
    - The AWS keys provided do not have access to Cloudwatch
    - your server is not synced with NTP
    - The Region setting is missing or incorrect
          EOF
      end
    end
  end
end
