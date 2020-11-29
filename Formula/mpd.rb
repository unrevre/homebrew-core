class Mpd < Formula
  desc "Music Player Daemon"
  homepage "https://www.musicpd.org/"
  url "https://www.musicpd.org/download/mpd/0.22/mpd-0.22.3.tar.xz"
  sha256 "338012037b5e67730529187c555a54cc567a85b15a7e8ddb3a807b1971566ccf"
  license "GPL-2.0-or-later"
  head "https://github.com/MusicPlayerDaemon/MPD.git"

  bottle do
    cellar :any
    sha256 "035629dc87d70607aeba56d678e493d26e5a8f611592aea77077e4bb4fae62c5" => :catalina
    sha256 "db8b3fe34ec3496c04f7a384005f09f025b45cb40793e5965fbed13288035b72" => :mojave
  end

  depends_on "boost" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "ffmpeg"
  depends_on "glib"
  depends_on "icu4c"
  depends_on "libao"
  depends_on "libmpdclient"
  depends_on "libsamplerate"
  depends_on macos: :mojave # requires C++17 features unavailable in High Sierra

  def install
    # mpd specifies -std=gnu++0x, but clang appears to try to build
    # that against libstdc++ anyway, which won't work.
    # The build is fine with G++.
    ENV.libcxx

    args = std_meson_args + %W[
      --sysconfdir=#{etc}
      -Dauto_features=disabled
      -Dao=enabled
      -Dbzip2=enabled
      -Dcue=false
      -Ddsd=false
      -Dffmpeg=enabled
      -Dhtml_manual=false
      -Dhttpd=false
      -Dicu=enabled
      -Dlibmpdclient=enabled
      -Dlibsamplerate=enabled
      -Dneighbor=false
      -Drecorder=false
      -Dzlib=enabled
    ]

    system "meson", *args, "output/release", "."
    system "ninja", "-C", "output/release"
    ENV.deparallelize # Directories are created in parallel, so let's not do that
    system "ninja", "-C", "output/release", "install"

    (etc/"mpd").install "doc/mpdconf.example" => "mpd.conf"
  end

  def caveats
    <<~EOS
      MPD requires a config file to start.
      Please copy it from #{etc}/mpd/mpd.conf into one of these paths:
        - ~/.mpd/mpd.conf
        - ~/.mpdconf
      and tailor it to your needs.
    EOS
  end

  plist_options manual: "mpd"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>WorkingDirectory</key>
          <string>#{HOMEBREW_PREFIX}</string>
          <key>ProgramArguments</key>
          <array>
              <string>#{opt_bin}/mpd</string>
              <string>--no-daemon</string>
          </array>
          <key>RunAtLoad</key>
          <true/>
          <key>KeepAlive</key>
          <true/>
          <key>ProcessType</key>
          <string>Interactive</string>
      </dict>
      </plist>
    EOS
  end

  test do
    port = free_port

    (testpath/"mpd.conf").write <<~EOS
      bind_to_address "127.0.0.1"
      port "#{port}"
    EOS

    pid = fork do
      exec "#{bin}/mpd --stdout --no-daemon #{testpath}/mpd.conf"
    end
    sleep 5

    begin
      ohai "Connect to MPD command (localhost:#{port})"
      TCPSocket.open("localhost", port) do |sock|
        assert_match "OK MPD", sock.gets
        ohai "Ping server"
        sock.puts("ping")
        assert_match "OK", sock.gets
        sock.close
      end
    ensure
      Process.kill "SIGINT", pid
      Process.wait pid
    end
  end
end
