class Caddy < Formula
  desc "Alternative general-purpose HTTP/2 web server"
  homepage "https://caddyserver.com/"
  url "https://github.com/mholt/caddy/archive/v0.11.2.tar.gz"
  sha256 "61779a09959bf6a0e7007e8ff5c2a94811dd12b7628166cb31e9648a97c0e75b"
  head "https://github.com/mholt/caddy.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "4de5dbb38d2966a6861ca8071a7e4ee465b0b5b5dd6d48f37fe58cad2b14e341" => :mojave
    sha256 "092c02c2b69119aedb9de0ac83f4a2205ea2e77cbcca061f5a89a4e3689c3a37" => :high_sierra
    sha256 "eff947aafbf28f6b3b473397c5da5e344f371dd0d9c4f4e23c64b60ad5097c90" => :sierra
    sha256 "32dad67078754c50997534d6495f634bae1281b25c5fc87214c21d9073579940" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["GOOS"] = OS.mac? ? "darwin" : "linux"
    ENV["GOARCH"] = "amd64"

    (buildpath/"src/github.com/mholt").mkpath
    ln_s buildpath, "src/github.com/mholt/caddy"

    system "go", "build", "-ldflags",
           "-X github.com/mholt/caddy/caddy/caddymain.gitTag=#{version}",
           "-o", bin/"caddy", "github.com/mholt/caddy/caddy"
  end

  plist_options :manual => "caddy -conf #{HOMEBREW_PREFIX}/etc/Caddyfile"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>KeepAlive</key>
        <true/>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/caddy</string>
          <string>-conf</string>
          <string>#{etc}/Caddyfile</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
      </dict>
    </plist>
  EOS
  end

  test do
    begin
      io = IO.popen("#{bin}/caddy")
      sleep 2
    ensure
      Process.kill("SIGINT", io.pid)
      Process.wait(io.pid)
    end

    io.read =~ /0\.0\.0\.0:2015/
  end
end
