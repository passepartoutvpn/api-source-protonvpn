require "json"
require "resolv"
require "ipaddr"

cwd = File.dirname(__FILE__)
Dir.chdir(cwd)
load "util.rb"

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
servers.with_index { |line, n|
    id, country, extraCountry, area, num, category, hostname, resolved_joined = line.strip.split(",")

    addresses = nil
    if resolved_joined.nil?
        if ARGV.include? "noresolv"
            addresses = []
        else
            addresses = Resolv.getaddresses(hostname)
        end
        addresses.map! { |a|
            IPAddr.new(a).to_i
        }
    else
        addresses = resolved_joined.split(":").map { |a|
            IPAddr.new(a).to_i
        }
    end

    pool = {
        :id => id,
        :country => country.upcase
    }
    pool[:category] = category if !category.empty?
    pool[:extra_countries] = [extraCountry.upcase] if !extraCountry.empty?
    pool[:area] = area if !area.empty?
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
