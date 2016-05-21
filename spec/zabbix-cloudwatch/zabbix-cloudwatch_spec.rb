require 'spec_helper'
require 'date'

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = fake = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  fake.string
end

module ZabbixCloudwatch
  describe GetCloudwatchMetric do
    describe "#new" do
      it "Raises NamespaceArgumentMissingException when options are empty" do
        lambda {ZabbixCloudwatch::GetCloudwatchMetric.new}.should raise_error GetCloudwatchMetric::NamespaceArgumentMissingException
      end
      it "Raises NamespaceArgumentMissingException when there is no namespace key in the options" do
        options = {}
        lambda {ZabbixCloudwatch::GetCloudwatchMetric.new(options)}.should raise_error GetCloudwatchMetric::NamespaceArgumentMissingException
      end
      it "Raises MetricnameArgumentMissingException when there is no metricname key in the options" do
        options = {"namespace" => ''}
        lambda {ZabbixCloudwatch::GetCloudwatchMetric.new(options)}.should raise_error GetCloudwatchMetric::MetricnameArgumentMissingException
      end
      it "Raises DimensionArgumentMissingException when both dimension keys are not in the options" do
        options = {"namespace" => '', "metricname" => ''}
        lambda {ZabbixCloudwatch::GetCloudwatchMetric.new(options)}.should raise_error GetCloudwatchMetric::DimensionArgumentMissingException
        options = {"namespace" => '', "metricname" => '', "dimension-name" => ''}
        lambda {ZabbixCloudwatch::GetCloudwatchMetric.new(options)}.should raise_error GetCloudwatchMetric::DimensionArgumentMissingException
        options = {"namespace" => '', "metricname" => '', "dimension-value" => ''}
        lambda {ZabbixCloudwatch::GetCloudwatchMetric.new(options)}.should raise_error GetCloudwatchMetric::DimensionArgumentMissingException
      end
      it "Raises Exception when aws keys are not in options" do
        options = {"namespace" => '', "metricname" => '', "dimension-value" => '', "dimension-name" => '', "aws-secret-key" => ''}
        lambda {ZabbixCloudwatch::GetCloudwatchMetric.new(options)}.should raise_error GetCloudwatchMetric::AwsAccessKeyMissingException
        options = {"namespace" => '', "metricname" => '', "dimension-value" => '', "dimension-name" => '', "aws-access-key" => ''}
        lambda {ZabbixCloudwatch::GetCloudwatchMetric.new(options)}.should raise_error GetCloudwatchMetric::AwsSecretKeyMissingException
      end
    end
    describe "#time_now" do
      it "Should return an ISO8601 date in UTC" do 
        options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test'}
        ZabbixCloudwatch::GetCloudwatchMetric.new(options).time_now.should =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
      end
    end
    describe "#time_one_minute_ago" do
      it "Should return an ISO8601 date in UTC" do 
        options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test'}
        ZabbixCloudwatch::GetCloudwatchMetric.new(options).time_one_minute_ago.should =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
      end
    end
    describe "#time_five_minutes_ago" do
      it "Should return an ISO8601 date in UTC" do 
        options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test'}
        ZabbixCloudwatch::GetCloudwatchMetric.new(options).time_five_minutes_ago.should =~ /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
      end
    end
    describe "#set_time_range" do
      it "Should set a start_time and end_time that is 450 seconds apart when the monitoring-type is not set" do 
        options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test'}
        @inst = ZabbixCloudwatch::GetCloudwatchMetric.new(options)
        @inst.set_time_range
        (Time.iso8601(@inst.end_time).to_i - Time.iso8601(@inst.start_time).to_i).should eq(450)
      end
      it "Should set a start_time and end_time that is 450 seconds apart when the monitoring-type is set to basic" do 
        options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test', "monitoring-type" => 'basic'}
        @inst = ZabbixCloudwatch::GetCloudwatchMetric.new(options)
        @inst.set_time_range
        (Time.iso8601(@inst.end_time).to_i - Time.iso8601(@inst.start_time).to_i).should eq(450)
      end
      it "Should set a start_time and end_time that is 90 seconds apart when the monitoring-type is set to detailed" do 
        options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test', "monitoring-type" => 'detailed'}
        @inst = ZabbixCloudwatch::GetCloudwatchMetric.new(options)
        @inst.set_time_range
        (Time.iso8601(@inst.end_time).to_i - Time.iso8601(@inst.start_time).to_i).should eq(90)
      end
      it "Should raise a MonitoringTypeArgumentException when the monitoring-type is not set to either basic or detailed" do 
        options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test', "monitoring-type" => 'junk'}
        @inst = ZabbixCloudwatch::GetCloudwatchMetric.new(options)
        lambda {@inst.set_time_range}.should raise_error GetCloudwatchMetric::MonitoringTypeArgumentException
      end
    end
    describe "#set_statistic" do
      it "Should set the statistic type to Average when statistic option is not set" do
        options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test'}
        @inst = ZabbixCloudwatch::GetCloudwatchMetric.new(options)
        @inst.set_statistic
        @inst.statistic.should eq("Average")
      end
      it "Should set the statistic type to Sum when statistic option is set to Sum" do
        options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test', "statistic" => "Sum"}
        @inst = ZabbixCloudwatch::GetCloudwatchMetric.new(options)
        @inst.set_statistic
        @inst.statistic.should eq("Sum")
      end
      it "Should raise a StatisticTypeArgumentException when the statistic option is not set to one of 'Minimum, Maximum, Average, Sum, SampleCount" do
        options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test', "statistic" => "Test"}
        @inst = ZabbixCloudwatch::GetCloudwatchMetric.new(options)
        lambda {@inst.set_statistic}.should raise_error GetCloudwatchMetric::StatisticTypeArgumentException
      end
    end
    #
    # TODO: Fails on SDK 2
    #
    #describe "#run! (real)" do
    #  it "Raises BadAWSAccessKeysException when the AWS Keys and/or Region are incorrect in the options" do
    #    options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => '', "aws-secret-key" => '', "statistic" => "Sum"}
    #    lambda {ZabbixCloudwatch::GetCloudwatchMetric.new(options).run!}.should raise_error GetCloudwatchMetric::BadAWSAccessKeysException
    #  end
    #end
    #
    # TODO: Fails on SDK 2
    #
    #describe "#test_aws_connectivity (real)" do
    #  it "Raises BadAWSAccessKeysException when the AWS Keys and/or Region are incorrect in the options" do
    #    options = {"namespace" => '', "metricname" => '', "dimension-value" => '', "dimension-name" => '', "aws-access-key" => '', "aws-secret-key" => ''}
    #    lambda {ZabbixCloudwatch::GetCloudwatchMetric.new(options).test_aws_connectivity}.should raise_error GetCloudwatchMetric::BadAWSAccessKeysException
    #  end
    #end
    #
    # TODO: Fails on SDK 2
    #
    #describe "#test_aws_connectivity (mock)" do
    #  it "Tests connectivity to AWS" do
    #    options = {"namespace" => '', "metricname" => '', "dimension-value" => '', "dimension-name" => '', "aws-access-key" => '', "aws-secret-key" => ''}
    #    Aws.stub!
    #    @inst = ZabbixCloudwatch::GetCloudwatchMetric.new(options)
    #    lambda {@inst.test_aws_connectivity}.should_not raise_error
    #  end
    #end
    #
    # TODO: Fails on SDK 2
    #
    #describe "#run! (mock)" do
    #  before(:each) do
    #    options = {"namespace" => 'AWS/EC2', "metricname" => 'CPU', "dimension-value" => 'EC2Instance', "dimension-name" => 'test', "aws-access-key" => 'test', "aws-secret-key" => 'test'}
    #    Aws.stub!
    #    @inst = ZabbixCloudwatch::GetCloudwatchMetric.new(options)
    #    @stb = @inst.aws.stub_for(:get_metric_statistics)
    #  end
    #  it "exits 1 when there are no datapoints" do
    #    @stb.data = Hash.new
    #    lambda {@inst.run!}.should raise_error SystemExit
    #  end
    #  it "puts a string when there is one datapoint" do
    #    @stb.data = {:datapoints => [ { :average => '10.0' } ] }
    #    output = capture_stdout {@inst.run!}
    #    output.should eq("10.0\n")
    #  end
    #  it "puts the first datapoint when there is more than one datapoint returned by AWS" do
    #    @stb.data = {:datapoints => [ { :average => '10.0' }, {:average => '10.1'}, {:average => '10.2'}] }
    #    output = capture_stdout {@inst.run!}
    #    output.should eq("10.0\n")
    #  end
    #  it "puts the metric that matches the statistic" do
    #    @stb.data = {:datapoints => [ { :average => '10.0', :minimum => '10.1', :maximum => '10.2', :sample_count => '10.3', :sum => '10.4' } ] }
    #    output = capture_stdout {@inst.run!}
    #    output.should eq("10.0\n")
    #    @inst.options["statistic"] = "Minimum"
    #    output = capture_stdout {@inst.run!}
    #    output.should eq("10.1\n")
    #    @inst.options["statistic"] = "Maximum"
    #    output = capture_stdout {@inst.run!}
    #    output.should eq("10.2\n")
    #    @inst.options["statistic"] = "SampleCount"
    #    output = capture_stdout {@inst.run!}
    #    output.should eq("10.3\n")
    #    @inst.options["statistic"] = "Sum"
    #    output = capture_stdout {@inst.run!}
    #    output.should eq("10.4\n")
    #  end
    #end
  end
end
