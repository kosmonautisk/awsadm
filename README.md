# awsadm

A command-line tool to manage Amazon Web Services (AWS) Elastic Compute Cloud (EC2) spot instance requests, instances and images.

*Note: This tools is highly experimental. Use at your own risk!*

# Installation

```
$ gem install awsadm
```

# Environment variables

* AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY: [Credentials](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys) for using AWS
* AWS_DEFAULT_REGION: Default AWS [region](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions)
* AWSADM_SECURITY_GROUP: Name of [security group](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html) to use

# Usage

```
awsadm commands:
  awsadm cancel REQUEST             # Cancel spot instance REQUEST
  awsadm help [COMMAND]             # Describe available commands or one specific command
  awsadm list OWNER                 # List available images by OWNER
  awsadm price INSTANCE_TYPE        # Show price history for INSTANCE_TYPE
  awsadm save INSTANCE              # Save an image from INSTANCE
  awsadm start IMAGE INSTANCE_TYPE  # Start INSTANCE_TYPE from IMAGE
  awsadm status                     # Return status on spot instance requests and instances
  awsadm stop INSTANCE              # Stop INSTANCE

Options:
  v, [--verbose], [--no-verbose]
```

# To do

* Tests, tests, tests
* More and better environment variable and input checks
* Sort image list by creation date
* Implement support for other parts of the Amazon Web Services

# License

[MIT License](http://opensource.org/licenses/MIT)
