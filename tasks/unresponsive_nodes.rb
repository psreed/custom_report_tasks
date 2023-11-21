#!/opt/puppetlabs/puppet/bin/ruby
#
# Unresponsive Nodes Report Task
#

require 'puppet'
require 'json'
require 'uri'
require 'net/http'

params = JSON.parse(STDIN.read)
debug = params['debug']

# Define the get nodes function for calling the reports API
def get_nodes(uri: "", token: "", pql: "", debug: false)
  uri.query = URI.encode_www_form({ :query => pql, })
  req = Net::HTTP::Get.new(uri)
  req["X-Authentication"] = token
  if (debug) 
    puts "URI: #{uri}"; 
    puts "PQL Query: #{pql}"
    puts
  end
  res = Net::HTTP.start(
      uri.host, uri.port, 
      :use_ssl => uri.scheme == 'https', 
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |https|
    https.request(req)
  end
  if (debug) then puts "Result Code: #{res.code}"; puts end
  if Integer(res.code) < 200 or Integer(res.code) > 299
    raise res.body
  end
  JSON.parse(res.body)
end

# Main
begin
  puts
  if (debug) then puts "Input Parameters: #{JSON.pretty_generate(params)}"; puts end

  # Get Report
  begin
    # Setup URLs
    base_url = "#{params['puppetdb_uri']}/pdb/query/v4"
    if (debug) then puts "PuppetDB Base URL: #{base_url}"; puts end
    uri = URI(base_url) 

    #read token from file if params['token']=='local'
    if params['token'].downcase() == 'local'
      if (debug) then puts "Attempting to reading token from local '#{params['token_location']}' file."; puts end
      begin
        params['token']=File.read(params['token_location'])
      rescue
        fail("Could not read token from local file '#{params['token_location']}'")
      end
    end

    # Setup time variables
    now = Time.now.utc
    time_format = "%Y-%m-%d %H:%M:%S"
    one_hour = 60 * 60
    one_day = one_hour * 24
    seven_days = one_day * 7
    twelve_days = one_day * 12
    forever = 0
    if (debug) then puts "Current UTC Time: #{now.strftime(time_format)}"; puts end

    reports_series = [
      { 
        :description => "Nodes unresponsive more than 1 hr, but less than 1 day", 
        :time_after => one_day, 
        :time_before => one_hour,
      },
      { 
        :description => "Nodes unresponsive more than 1 day, but less than 7 days", 
        :time_after => seven_days, 
        :time_before => one_day,
      },      
      { 
        :description => "Nodes unresponsive more than 7 days, but less than 12 days", 
        :time_after => twelve_days, 
        :time_before => seven_days,
      },      
      { 
        :description => "Nodes unresponsive more than 12 days", 
        :time_after => forever, 
        :time_before => twelve_days,
      },      
    ]

    return_fields = params['return_fields']
    reports=[]
    reports_series.each { | rs |
      pql_query = "reports[#{return_fields}] { latest_report? = true and receive_time >= \"#{(now - rs[:time_after]).strftime(time_format)}\" and receive_time <= \"#{(now - rs[:time_before]).strftime(time_format)}\" }"
      reports << { 
        :description => rs[:description],
        :time_bewteen => "#{(now - rs[:time_after]).strftime(time_format)} and #{(now - rs[:time_before]).strftime(time_format)}",
        :time_now => now.strftime(time_format),
        :nodes => get_nodes(uri: uri, token: params['token'], pql: pql_query, debug: debug) 
      }
    }
 
    puts JSON.pretty_generate(JSON.parse(reports.to_json))
  rescue => e
    puts "Failed to access server. Server response:\n  \"#{e}\""
  rescue
    puts "Could not access URI: #{uri}"
  end

  puts
end
