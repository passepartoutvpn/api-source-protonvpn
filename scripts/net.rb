require "json"
require "resolv"
require "ipaddr"

cwd = File.dirname(__FILE__)
Dir.chdir(cwd)
load "util.rb"

###

template = File.read("../template/servers.json")
ca = File.read("../static/ca.crt")
tls_wrap = read_tls_wrap("auth", 1, "../static/ta.key", 2)

cfg = {
  ca: ca,
  tlsWrap: tls_wrap,
  cipher: "AES-256-CBC",
  digest: "SHA512",
  compressionFraming: 1,
  renegotiatesAfterSeconds: 0,
  checksEKU: true,
  randomizeEndpoint: true
}

recommended = {
  id: "default",
  name: "Default",
  comment: "256-bit encryption",
  ovpn: {
    cfg: cfg,
    endpoints: [
      "UDP:80",
      "UDP:443",
      "UDP:4569",
      "UDP:1194",
      "TCP:443",
      "TCP:8443"
    ]
  }
}
presets = [recommended]

defaults = {
  :username => "ABCdefGH012_jklMNop34Q_R",
  :country => "US"
}

###

servers = []

json = JSON.parse(template)
json["LogicalServers"].each { |server|
  name = server["Name"]
  name_comps = name.split("#")

  #id = server["ID"]
  id = name
  country = server["ExitCountry"]
  extraCountry = server["EntryCountry"]
  area = server["City"] || server["Region"]
  if name_comps.size > 1
    num = name_comps[1].to_i
  else
    num = nil
  end
  hostname = server["Domain"]
  resolved = server["Servers"].map { |s|
    s["EntryIP"]
  }

  if country == "UK"
    country = "GB"
  end
  if extraCountry == "UK"
    extraCountry = "GB"
  end
  if extraCountry == country
    extraCountry = nil
  end

  if server["Features"].to_i & 1 == 1
    category = "Secure Core"
  else
    case server["Tier"]
    when 0
      category = "Free"
    when 1, 2
      category = ""
    end
  end

  addresses = nil
  if resolved.nil?
    if hostname.nil?
      next
    end
    if ARGV.include? "noresolv"
      addresses = []
    else
      addresses = Resolv.getaddresses(hostname)
    end
    addresses.map! { |a|
      IPAddr.new(a).to_i
    }
  else
    addresses = resolved.map { |a|
      IPAddr.new(a).to_i
    }
  end

  server = {
    :id => id,
    :country => country.upcase
  }
  server[:category] = category if !category.empty?
  server[:extra_countries] = [extraCountry.upcase] if !extraCountry.nil?
  server[:area] = area if !area.nil?
  server[:num] = num.to_i
  if hostname.empty?
    server[:resolved] = true
  else
    server[:hostname] = hostname
  end
  server[:addrs] = addresses
  servers << server
}

###

infra = {
  :servers => servers,
  :presets => presets,
  :defaults => defaults
}

puts infra.to_json
puts
