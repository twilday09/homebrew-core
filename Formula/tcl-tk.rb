class TclTk < Formula
  desc "Tool Command Language"
  homepage "https://www.tcl.tk/"
  url "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.9/tcl8.6.9-src.tar.gz"
  mirror "https://ftp.osuosl.org/pub/blfs/conglomeration/tcl/tcl8.6.9-src.tar.gz"
  version "8.6.9"
  sha256 "ad0cd2de2c87b9ba8086b43957a0de3eb2eb565c7159d5f53ccbba3feb915f4e"

  bottle do
    sha256 "50cb502bdc8d69a1c19407164aab0aaf3ec7f33a46a098c85972ad6a26285e43" => :mojave
    sha256 "1f97a3b5ceb9419d8410c85cd29bb54a91d9fa3a075d62f47fece3e68078952c" => :high_sierra
    sha256 "4a0b8bfd43f0ef29e8c1f4c1e8d56dd3ebf81cc9d6848675418df8a8dfe73f0d" => :sierra
    sha256 "7d2e3b22248789aa51d24a3b9d3459a525ca25893b5b856ea07520210e2850cd" => :x86_64_linux
  end

  keg_only :provided_by_macos,
    "tk installs some X11 headers and macOS provides an (older) Tcl/Tk"

  depends_on "openssl"
  unless OS.mac?
    depends_on "linuxbrew/xorg/xorg"
    depends_on "pkg-config" => :build
  end

  resource "tcllib" do
    url "https://downloads.sourceforge.net/project/tcllib/tcllib/1.19/tcllib-1.19.tar.gz"
    sha256 "01fe87cf1855b96866cf5394b6a786fd40b314022714b34110aeb6af545f6a9c"
  end

  resource "tcltls" do
    url "https://core.tcl.tk/tcltls/uv/tcltls-1.7.16.tar.gz"
    sha256 "6845000732bedf764e78c234cee646f95bb68df34e590c39434ab8edd6f5b9af"
  end

  resource "tk" do
    url "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.9/tk8.6.9.1-src.tar.gz"
    mirror "https://fossies.org/linux/misc/tk8.6.9.1-src.tar.gz"
    version "8.6.9.1"
    sha256 "8fcbcd958a8fd727e279f4cac00971eee2ce271dc741650b1fc33375fb74ebb4"

    # Upstream issue 7 Jan 2018 "Build failure with Aqua support on OS X 10.8 and 10.9"
    # See https://core.tcl.tk/tcl/tktview/95a8293a2936e34cc8d0658c21e5214f1ca9b435
    if MacOS.version == :mavericks
      patch :p0 do
        url "https://raw.githubusercontent.com/macports/macports-ports/0a883ad388b/x11/tk/files/patch-macosx-tkMacOSXXStubs.c.diff"
        sha256 "2cdba6bbf2503307fe4f4d7200ad57c9926ebf0ff6ed3e65bf551067a30a04a9"
      end
    end
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --mandir=#{man}
      --enable-threads
      --enable-64bit
    ]

    cd "unix" do
      system "./configure", *args
      system "make"
      system "make", "install"
      system "make", "install-private-headers"
      ln_s bin/"tclsh#{version.to_f}", bin/"tclsh"
    end

    # Let tk finds our new tclsh
    ENV.prepend_path "PATH", bin

    resource("tk").stage do
      cd "unix" do
        system "./configure", *args, *("--enable-aqua=yes" if OS.mac?),
                              "--without-x", "--with-tcl=#{lib}"
        system "make"
        system "make", "install"
        system "make", "install-private-headers"
        ln_s bin/"wish#{version.to_f}", bin/"wish"
      end
    end

    resource("tcllib").stage do
      system "./configure", "--prefix=#{prefix}", "--mandir=#{man}"
      system "make", "install"
    end

    resource("tcltls").stage do
      system "./configure", "--with-ssl=openssl", "--with-openssl-dir=#{Formula["openssl"].opt_prefix}", "--prefix=#{prefix}", "--mandir=#{man}"
      system "make", "install"
    end
  end

  test do
    assert_equal "honk", pipe_output("#{bin}/tclsh", "puts honk\n").chomp
  end
end
