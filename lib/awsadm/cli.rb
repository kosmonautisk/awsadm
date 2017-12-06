module Awsadm
  class Cli < Thor
    include Awsadm::Helpers

    package_name "awsadm"
    class_option :verbose, type: :boolean, aliases: :v

    def initialize(*args)
      super

      @config = {
        security_name: ENV["AWSADM_SECURITY_GROUP"] || "awsadm",
        security_desc: "Allow port 22 on TCP (ssh)"
      }

      if ENV["AWS_ACCESS_KEY_ID"].nil? or ENV["AWS_SECRET_ACCESS_KEY"].nil?
        abort "ERROR: Amazon Web Services credentials not set"
      end

      if ENV["AWS_DEFAULT_REGION"].nil?
        abort "ERROR: Amazon Web Services default region not set"
      end

      Aws.config.update({
        credentials: Aws::Credentials.new(
          ENV["AWS_ACCESS_KEY_ID"],
          ENV["AWS_SECRET_ACCESS_KEY"]
        ),
        region: ENV["AWS_DEFAULT_REGION"]
      })

      @client = Aws::EC2::Client.new
    end

    desc "list OWNER", "List available images by OWNER"
    def list owner=""
      print "Finding images... " if options[:verbose]

      if owner.empty?
        images = @client.describe_images[0]
      else
        images = @client.describe_images({
          owners: [owner]
        })[0]
      end

      puts "#{images.count} image(s) found." if options[:verbose]

      image_table_header = ["IMAGE", "NAME", "PLATFORM", "STATE", "CREATED"]
      image_table_items  = []

      images.each do |image|
        image_table_items << [
          image.image_id,
          image.name.nil? ? "-" : truncate(image.name),
          image.platform,
          image.state,
          empty?(image.creation_date) ? "-" : time_string_format(image.creation_date)
        ]
      end

      if image_table_items.size > 0
        puts_table image_table_header, image_table_items
      end
    end

    desc "start IMAGE INSTANCE_TYPE", "Start INSTANCE_TYPE from IMAGE"
    def start image_id, instance_type
      print "Finding image... " if options[:verbose]

      begin
        image = @client.describe_images({
          image_ids: [image_id]
        })[0][0]
      rescue Aws::EC2::Errors::InvalidAMIIDMalformed
        abort "ERROR: Invalid image ID"
      rescue Aws::EC2::Errors::InvalidAMIIDNotFound
        abort "ERROR: Image not found"
      end

      puts "Found." if options[:verbose]

      image_table_header = ["IMAGE", "NAME", "PLATFORM", "STATE", "CREATED"]
      image_table_items  = []

      image_table_items = [[
        image.image_id,
        image.name.nil? ? "-" : truncate(image.name),
        image.platform,
        image.state,
        empty?(image.creation_date) ? "-" : time_string_format(image.creation_date)
      ]]

      if image_table_items.size > 0
        puts_table image_table_header, image_table_items
      end

      puts
      print "Finding security group \"#{@config[:security_name]}\"... " if options[:verbose]

      begin
        security_group = @client.describe_security_groups({
          group_names: [@config[:security_name]]
        })[0][0]
      rescue Aws::EC2::Errors::InvalidGroupNotFound
        puts "Not found." if options[:verbose]
        print "Creating one with defaults... " if options[:verbose]

        @client.create_security_group({
          group_name: @config[:security_name],
          description: @config[:security_desc]
        })

        default_security.each do |rule|
          @client.authorize_security_group_ingress(rule.merge({
            group_name: @config[:security_name]
            }))
        end

        security_group = @client.describe_security_groups({
          group_names: [@config[:security_name]]
        })[0][0]
      end

      puts "Done." if options[:verbose]

      rule_table_header = ["PROTOCOL", "PORT RANGE", "IP RANGES"]
      rule_table_items  = []

      security_group.ip_permissions.each do |p|
        ip_ranges = []
        p.ip_ranges.each do |ip|
          ip_ranges << ip.cidr_ip
        end

        rule_table_items << [
          p.ip_protocol,
          "#{p.from_port} to #{p.to_port}",
          "#{ip_ranges.join(", ")}"
        ]
      end

      puts_table rule_table_header, rule_table_items, false
      puts
      print "Retrieving price history... " if options[:verbose]

      if image.platform.nil? or image.platform.empty?
        price_history = @client.describe_spot_price_history({
          instance_types: [instance_type],
          start_time: Time.now
        })[0]
      else
        price_history = @client.describe_spot_price_history({
          instance_types: [instance_type],
          start_time: Time.now,
          product_descriptions: [image.platform.capitalize]
        })[0]
      end

      puts "Retrieved." if options[:verbose]

      price_table_header = ["ZONE", "INSTANCE TYPE", "PLATFORM", "PRICE"]
      price_table_items  = []
      prices = []

      price_history.each do |p|
        price = p.spot_price.to_f.round(3)
        prices << price
        price_table_items << [
          p.availability_zone,
          instance_type,
          p.product_description.downcase,
          price
        ]
      end

      puts_table price_table_header, price_table_items
      puts

      suggested_bid = bid_formula prices
      bid = ask "How much are you willing to bid for the instance (#{suggested_bid} usd/hour)?"
      bid = suggested_bid if bid.nil? or bid.empty?
      exit unless valid_float? bid
      bid.to_f.round(3)

      print "Creating instance request... " if options[:verbose]

      request = @client.request_spot_instances({
        spot_price: bid.to_s,
        launch_specification: {
          image_id: image_id,
          security_groups: [@config[:security_name]],
          instance_type: instance_type
        }
      })

      puts "Created." if options[:verbose]
      puts "Run \"awsadm status\" to see status." if options[:verbose]
    end

    desc "status", "Return status on spot instance requests and instances"
    def status
      requests = @client.describe_spot_instance_requests()[0]

      request_table_header = ["REQUEST", "INSTANCE", "STATE", "PRICE", "AGE"]
      request_table_items  = []

      requests.each do |r|
        request_table_items << [
          r.spot_instance_request_id,
          r.instance_id.nil? ? "-" : r.instance_id,
          r.status.code,
          r.spot_price.to_f.round(3).to_s,
          r.create_time.nil? ? "-" : "#{minutes_since(r.create_time)}m"
        ]
      end

      if request_table_items.size > 0
        puts_table request_table_header, request_table_items
      end

      instances = @client.describe_instances()[0]

      instance_table_header = [
        "INSTANCE", "IMAGE", "STATE", "IP", "ZONE", "AGE"
      ]
      instance_table_items  = []

      instances.each do |i|
        i = i.instances.first
        ni = i.network_interfaces.first

        instance_table_items << [
          i.instance_id,
          i.image_id,
          i.state.name,
          i.state.name == "running" ? ni.association.public_ip : "-",
          i.placement.availability_zone,
          i.state.name == "running" ? "#{minutes_since(i.launch_time)}m" : "-"
        ]
      end

      if instance_table_items.size > 0
        puts
        puts_table instance_table_header, instance_table_items
      end
    end

    desc "stop INSTANCE", "Stop INSTANCE"
    def stop instance_id
      if instance_id == "all"
        instances = @client.describe_instances()[0]
      else
        begin
          instances = @client.describe_instances({
            instance_ids: [instance_id]
          })[0]
        rescue Aws::EC2::Errors::InvalidInstanceIDMalformed
          abort "ERROR: Invalid instance ID"
        rescue Aws::EC2::Errors::InvalidInstanceIDNotFound
          abort "ERROR: Instance not found"
        end
      end

      instance_ids = []
      instances.each do |i|
        i = i.instances.first
        instance_ids << i.instance_id
      end

      @client.terminate_instances({
        instance_ids: instance_ids
      })

      print "Instance(s) have been stopped. " if options[:verbose]
      puts "Run \"awsadm status\" to see status." if options[:verbose]
    end

    desc "cancel REQUEST", "Cancel spot instance REQUEST"
    def cancel request_id
      if request_id == "all"
        requests = @client.describe_spot_instance_requests()[0]
      else
        begin
          requests = @client.describe_spot_instance_requests({
            spot_instance_request_ids: [request_id]
          })[0]
        rescue Aws::EC2::Errors::InvalidSpotInstanceRequestIDMalformed
          abort "ERROR: Invalid request ID"
        rescue Aws::EC2::Errors::InvalidSpotInstanceRequestIDNotFound
          abort "ERROR: Request not found"
        end
      end

      request_ids = []

      requests.each do |r|
        request_ids << r.spot_instance_request_id
      end

      if request_ids.size > 0
        @client.cancel_spot_instance_requests({
          spot_instance_request_ids: request_ids
        })
      end

      print "Instance request(s) cancelled. " if options[:verbose]
      puts "Run \"awsadm status\" to see status." if options[:verbose]
    end

    desc "save INSTANCE", "Save an image from INSTANCE"
    def save instance_id
      begin
        instance = @client.describe_instances({
          instance_ids: [instance_id]
        })[0][0]
      rescue Aws::EC2::Errors::InvalidInstanceIDMalformed
        abort "ERROR: Invalid instance ID"
      rescue Aws::EC2::Errors::InvalidInstanceIDNotFound
        abort "ERROR: Instance not found"
      end

      image = @client.create_image({
        instance_id: instance_id,
        name: "awsadm-#{instance_id}-#{Time.now.strftime('%Y%m%d-%H%M%S%L')}"
      })

      print "Instance saved. " if options[:verbose]
      puts "Run \"awsadm list\" to see images." if options[:verbose]
    end

    desc "price INSTANCE_TYPE", "Show price history for INSTANCE_TYPE"
    def price instance_type
      print "Retrieving price history... " if options[:verbose]

      price_history = @client.describe_spot_price_history({
        instance_types: [instance_type],
        start_time: Time.now
      })[0]

      puts "Retrieved." if options[:verbose]

      price_table_header = ["ZONE", "INSTANCE TYPE", "PLATFORM", "PRICE"]
      price_table_items  = []
      prices = []

      price_history.each do |p|
        price = p.spot_price.to_f.round(3)
        prices << price
        price_table_items << [
          p.availability_zone,
          p.instance_type,
          p.product_description.downcase,
          price
        ]
      end

      puts_table price_table_header, price_table_items
    end
  end
end
