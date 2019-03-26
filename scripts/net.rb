require "json"
require "resolv"
require "ipaddr"

cwd = File.dirname(__FILE__)
Dir.chdir(cwd)

###

def read_tls_wrap(strategy, dir, file, from, to)
    lines = File.foreach(file)
    key = ""
    lines.with_index { |line, n|
        next if n < from or n >= to
        key << line.strip
    }
    key64 = [[key].pack("H*")].pack("m0")

    return {
        strategy: strategy,
        key: {
            dir: dir,
            data: key64
        }
    }
end

###

servers = File.foreach("../template/servers.csv")
ca = File.read("../template/ca.crt")
tls_wrap = read_tls_wrap("auth", 1, "../template/ta.key", 2, 18)

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
    eku: true
}

recommended = {
    id: "default",
    name: "Default",
    comment: "256-bit encryption",
    cfg: cfg
}
presets = [recommended]

defaults = {
    :username => "ABCdefGH012_jklMNop34Q_R",
    :pool => "us-free-01",
    :preset => "default"
}

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

###

infra = {
    :pools => pools,
    :presets => presets,
    :defaults => defaults
}

puts infra.to_json
puts
