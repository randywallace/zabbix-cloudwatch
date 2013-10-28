# zabbix-cloudwatch

[![Gem Version](https://badge.fury.io/rb/zabbix-cloudwatch.png)](http://badge.fury.io/rb/zabbix-cloudwatch)
[![Code Climate](https://codeclimate.com/github/randywallace/zabbix-cloudwatch.png)](https://codeclimate.com/github/randywallace/zabbix-cloudwatch)
[![Dependency Status](https://gemnasium.com/randywallace/zabbix-cloudwatch.png)](https://gemnasium.com/randywallace/zabbix-cloudwatch)

An external script for getting cloudwatch metrics into Zabbix

```
Usage: zabbix-cloudwatch

  -h, --help              This Message
  -n, --namespace         Namespace (AWS/Autoscaling, AWS/EC2, etc...)
  -m, --metricname        Metric Name (GroupInServiceInstances,EstimatedCharges, etc...)
  -d, --dimension-name    Dimension Name (AutoScalingGroupName, etc...)
  -v, --dimension-value   Dimension Value
  -t, --monitoring-type   detailed|basic                            Default: basic
  -s, --statistic         Minimum|Maximum|Average|Sum|SampleCount   Default: Average
  --aws-access-key        AWS Access Key
  --aws-secret-key        AWS Secret Key
  --aws-region            AWS Region                                Default: us-east-1
```

## Getting it running

* It is only guaranteed to work on ruby 1.8.7 at this time and will throw an Exception on other rubies. 
* for some of the gem dependencies, you will need the ruby development packages, gcc, libxml2, and libxslt

Modify these steps to taste (examples given running on the Amazon AMI 2013.03):
```bash
yum install ruby ruby-devel rubygems gcc libxml2-devel libxslt-devel
gem install bundler zabbix-cloudwatch
ln -s $(which zabbix-cloudwatch) /var/lib/zabbixsrv/externalscripts/zabbix-cloudwatch
```

## Examples

```bash
zabbix-cloudwatch -n AWS/EC2 \
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

## AWS Credentials

There are (3) ways to get your AWS Credentials into `zabbix-cloudwatch`.

**Note that *none* of these options are "safe", so make sure you are using a set of IAM Keys with extremely restricted 
permissions.**

### 1. Environment Variables (which is difficult with Zabbix):
```bash
export AWS_ACCESS_KEY_ID="YOUR ACCESS KEY" 
export AWS_SECRET_ACCESS_KEY="YOUR SECRET ACCESS KEY"
export AWS_REGION="YOUR AWS REGION"
```

### 2. Within the binary in the gem.  

If you intend to do it this way, I suggest you make a copy of the binary
and place it in your zabbix externalscript path (instead of the suggested symlink in the installation example).

Find the binary like this:

```bash
ls $(gem env gemdir)/gems/zabbix-cloudwatch-$(zabbix-cloudwatch --version)/bin/zabbix-cloudwatch
```

And place it in your externalscripts path like this (your zabbix path/user/group may be different):

```bash
cp $(gem env gemdir)/gems/zabbix-cloudwatch-$(zabbix-cloudwatch --version)/bin/zabbix-cloudwatch \
      /var/lib/zabbixsrv/externalscripts/
chown zabbix:zabbix /var/lib/zabbixsrv/externalscripts/zabbix-cloudwatch
```

The class variables for this are at the very top of the file for your convenience.

### 3. Passing in your AWS Keys when you run zabbix-cloudwatch using the command line flags.

```bash
zabbix-cloudwatch -n AWS/AutoScaling \
                  -m GroupInServiceInstances \
                  -d AutoScalingGroupName \
                  -v your-auto-scaling-group \
                  --aws-access-key 'YOUR ACCESS KEY' \
                  --aws-secret-key 'YOUR SECRET KEY' \
                  --aws-region 'YOUR AWS REGION'
```
## Order of preference

The order of preference that this gem uses for the region and keys (individually) are:

* Commandline flag
* Within the binary
* Environment Variable

