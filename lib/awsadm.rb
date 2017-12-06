require "rubygems"
require "thor"
require "aws-sdk"

module Awsadm
  autoload :Cli,     "awsadm/cli"
  autoload :Helpers, "awsadm/helpers"
  autoload :Version, "awsadm/version"
end
