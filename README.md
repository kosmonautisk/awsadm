# awsadm

A command-line tool to manage Amazon Web Services (AWS) Elastic Compute Cloud (EC2) spot instance requests, instances and images. It replicates some functionality of the `aws` command, but takes a little inspiration from the SmartOS command [vmadm](https://smartos.org/man/1m/vmadm). 

*Note: This tool is highly experimental. Use at your own risk!*

## Installation

```
$ gem install awsadm
```

## Environment variables

* AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY: [Credentials](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys) for using AWS
* AWS_DEFAULT_REGION: Default AWS [region](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions)
* AWSADM_SECURITY_GROUP: [Security group](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html) ID

## Usage

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

## To do

* Write tests
* Sort image list by creation date
* Implement better environment variable and command-line input checks
* Implement support for other relevant parts of AWS (security group management, etc)

## License

[MIT License](http://opensource.org/licenses/MIT)
