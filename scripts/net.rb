require "json"
require "resolv"
require "ipaddr"

cwd = File.dirname(__FILE__)
Dir.chdir(cwd)

servers = File.foreach("../template/servers.csv")

ca = File.read("../certs/ca.crt")
tlsStrategy = "auth" # tls-auth
tlsKeyLines = File.foreach("../certs/ta.key")
tlsDirection = 1

tlsKey = ""
tlsKeyLines.with_index { |line, n|
    next if n < 2 or n >= 18
    tlsKey << line.strip
}
tlsKey = [[tlsKey].pack("H*")].pack("m0")

###

pools = []
servers.with_index { |line, n|
    id, country, area, num, free, hostname = line.strip.split(",")

    addresses = nil
    if ARGV.length > 0 && ARGV[0] == "noresolv"
        addresses = []
    else
        addresses = Resolv.getaddresses(hostname)
    end
    addresses.map! { |a|
        IPAddr.new(a).to_i
    }

    pool = {
        :id => id,
        :name => "",
        :country => country
    }
    pool[:area] = area if !area.empty?
    pool[:num] = num
    pool[:free] = (free == "1")
    pool[:hostname] = hostname
    pool[:addrs] = addresses
    pools << pool
}

recommended = {
    id: "recommended",
    name: "Recommended",
    comment: "256-bit encryption",
    cfg: {
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
        ca: ca,
        wrap: {
            strategy: tlsStrategy,
            key: {
                data: tlsKey,
                dir: tlsDirection
            }
        },
        frame: 1,
        reneg: 0
    }
}
presets = [recommended]

defaults = {
    :username => "ABCdefGH012_jklMNop34Q_R",
    :pool => "us-free-01",
    :preset => "recommended"
}

###

infra = {
    :pools => pools,
    :presets => presets,
    :defaults => defaults
}

puts infra.to_json
puts
