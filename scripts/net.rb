require "json"
require "resolv"
require "ipaddr"

cwd = File.dirname(__FILE__)
Dir.chdir(cwd)
load "util.rb"

###

servers = File.read("../template/servers.json")
ca = File.read("../static/ca.crt")
tls_wrap = read_tls_wrap("auth", 1, "../static/ta.key", 2)

cfg = {
  ca: ca,
  wrap: tls_wrap,
  ep: [
    "UDP:80",
    "UDP:443",
    "UDP:4569",
    "UDP:1194",
    "UDP:5060",
    "TCP:443",
    "TCP:3389",
    "TCP:8080",
    "TCP:8443"
  ],
  cipher: "AES-256-CBC",
  auth: "SHA512",
  frame: 1,
  reneg: 0,
  eku: true,
  random: true
}

external = {
  hostname: "${id}.protonvpn.com"
}

recommended = {
  id: "default",
  name: "Default",
  comment: "256-bit encryption",
  cfg: cfg,
  external: external
}
presets = [recommended]

defaults = {
  :username => "ABCdefGH012_jklMNop34Q_R",
  :pool => "us-free-01",
  :preset => "default"
}

###

pools = []

json = JSON.parse(servers)
json["LogicalServers"].each { |server|
  name = server["Name"]
  name_comps = name.split("#")

  #id = server["ID"]
  id = name
  country = server["EntryCountry"]
  extraCountry = server["ExitCountry"]
  area = server["City"]
  if name_comps.size > 1
    num = name_comps[1].to_i
  else
    num = nil
  end
  hostname = server["Domain"]
  resolved = server["Servers"].map { |s|
    s["EntryIP"]
  }

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

  pool = {
    :id => id,
    :country => country.upcase
  }
  pool[:category] = category if !category.empty?
  pool[:extra_countries] = [extraCountry.upcase] if !extraCountry.nil?
  pool[:area] = area if !area.nil?
  pool[:num] = num.to_i
  if hostname.empty?
    pool[:resolved] = true
  else
    pool[:hostname] = hostname
  end
  pool[:addrs] = addresses
  pools << pool
}

###

infra = {
  :pools => pools,
  :presets => presets,
  :defaults => defaults
}

puts infra.to_json
puts
