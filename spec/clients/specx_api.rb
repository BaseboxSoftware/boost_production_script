require "httparty"
class SpecxApi
  include HTTParty
  @@basebox_ip = "192.168.0.36"
  base_uri "#{@@basebox_ip}/api"

  attr_accessor :options

  def self.basebox_ip
    @@basebox_ip
  end

  def initialize
    basebox_token = "kM72_o348kGsz1pxfzSB"
    self.options = {
      headers: {
        "Authorization": "token='#{basebox_token}'",
        'Accept': 'application/json;version=1',
        'Content-Type':  'application/json'
      }
    }
  end

  def table(table_id)
    self.class.get("/tables/#{table_id}", self.options)
  end

  def text_attribution_values_by_type(type)
    opts = {}
    opts[:body] = {name: type}.to_json
    self.class.get("/specification_attributions/values", self.options.merge(opts))
  end
end
