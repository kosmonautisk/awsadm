module Awsadm::Helpers
  def bid_formula x
    y = 0.02
    (x.max + y).round(3)
  end

  def minutes_since time
    (time - Time.now).to_i.abs / 60
  end

  def time_format time
    time.strftime("%Y-%m-%d")
  end

  def time_string_format time
    time_format(Time.parse(time))
  end

  def truncate string, max=24
    string.length > max ? "#{string[0..max]}..." : string
  end

  def valid_float? string
    !!Float(string) rescue false
  end

  def puts_table header, items, sort=true
    full_table = []
    full_table = items
    full_table.sort! if sort
    full_table.unshift header
    print_table full_table, colwidth: 14
  end

  def empty? string
    (string.nil? or string.empty?)
  end

  def default_security
    [
      {
        ip_protocol: "tcp",
        cidr_ip:     "0.0.0.0/0",
        from_port:   22,
        to_port:     22
      }
    ]
  end
end
