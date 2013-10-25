# zabbix-cloudwatch


An external script for getting cloudwatch metrics into Zabbix

```
Usage: get_aws_cloudwatch_metric.rb

  -h, --help              This Message
  -n, --namespace         Namespace (AWS/Autoscaling, AWS/EC2, etc...)
  -m, --metricname        Metric Name (GroupInServiceInstances,EstimatedCharges, etc...)
  -d, --dimension-name    Dimension Name (AutoScalingGroupName, etc...)
  -v, --dimension-value   Dimension Value
  -t, --monitoring-type   detailed|basic                            Default: basic
  -s, --statistic         Minimum|Maximum|Average|Sum|SampleCount   Default: Average
```

## Getting it running

* It is only guaranteed to work on ruby 1.8.7 at this time. 
* for some of the gem dependencies, you will need the ruby development packages, gcc, libxml2, and libxslt

Modify these steps to taste (examples given running on the Amazon AMI 2013.03):
```
# git clone git@github.com:randywallace/zabbix-cloudwatch.git /usr/local/zabbix-cloudwatch
# cd /usr/local/zabbix-cloudwatch
# chown zabbix:zabbix get_aws_cloudwatch_metric.rb
# yum install ruby ruby-devel rubygems gcc libxml2-devel libxslt-devel
# gem install bundler
# bundle install
# ln -s /usr/local/zabbix-cloudwatch/get_aws_cloudwatch_metric.rb /var/lib/zabbixsrv/externalscripts/get_aws_cloudwatch_metric.rb
```

## Examples

```
/usr/local/zabbix-cloudwatch/get_aws_cloudwatch_metric.rb -n AWS/EC2 \
                                                          -m CPUUtilization \
                                                          -d AutoScalingGroupName \
                                                          -v your-auto-scaling-group \
                                                          -t detailed \
                                                          -s Sum
```

## Creating the IAM User

The following actions need to be allowed in IAM for this script to work with the keys you provide:

```
"cloudwatch:DescribeAlarms"
"cloudwatch:GetMetricStatistics"
```

## Notes

The class variables within get_aws_cloudwatch_metric.rb should be set if you do not (or don't want to) set environment
variables for your AWS Credentials.

The default behavior is to use the Environment variables *only* if the variables in the script are not set.

### Setting the Environment variables
```
export AWS_ACCESS_KEY_ID="YOUR ACCESS KEY" 
export AWS_SECRET_ACCESS_KEY="YOUR SECRET ACCESS KEY"
export AWS_REGION="YOUR AWS REGION"
```

### Class variables at the top of get_aws_cloudwatch_metric.rb
```
@@aws_access_key=''
@@aws_secret_key=''
@@aws_region=''
```

