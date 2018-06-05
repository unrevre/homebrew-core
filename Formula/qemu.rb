class Qemu < Formula
  desc "Emulator for x86 and PowerPC"
  homepage "https://www.qemu.org/"
  url "https://download.qemu.org/qemu-5.1.0.tar.xz"
  sha256 "c9174eb5933d9eb5e61f541cd6d1184cd3118dfe4c5c4955bc1bdc4d390fa4e5"
  license "GPL-2.0-only"
  head "https://git.qemu.org/git/qemu.git"

  bottle do
    sha256 "6d66e4689bda9dc9c43bd3924e49e4722586bb611073ced182c79c6d7f995cb0" => :big_sur
    sha256 "9659d7d483d014be6366a0480de364cc983e1f9e24e9c42e09f0fa19e216d5d1" => :catalina
    sha256 "dc0d52fc6839c7800ec0dc38c78c8ccb862357149141aee669ec29449cb3b810" => :mojave
    sha256 "9a30c423617ebd3dbfc8e67afada9a17f7534a7bba16b3c13189301f53458f36" => :high_sierra
  end

  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "glib"
  depends_on "libpng"
  depends_on "ncurses"
  depends_on "pixman"

  # 820KB floppy disk image file of FreeDOS 1.2, used to test QEMU
  resource "test-image" do
    url "https://dl.bintray.com/homebrew/mirror/FD12FLOPPY.zip"
    sha256 "81237c7b42dc0ffc8b32a2f5734e3480a3f9a470c50c14a9c4576a2561a35807"
  end

  def install
    ENV["LIBTOOL"] = "glibtool"

    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-bsd-user
      --disable-guest-agent
      --target-list=i386-softmmu,x86_64-softmmu
      --audio-drv-list=
      --enable-curses
      --extra-cflags=-DNCURSES_WIDECHAR=1
      --disable-attr
      --disable-brlapi
      --disable-cap-ng
      --disable-curl
      --disable-fdt
      --disable-gcrypt
      --disable-glusterfs
      --disable-gnutls
      --disable-gtk
      --disable-libiscsi
      --disable-libssh
      --disable-linux-aio
      --disable-live-block-migration
      --disable-lzo
      --disable-nettle
      --disable-opengl
      --disable-qom-cast-debug
      --disable-rbd
      --disable-replication
      --disable-sdl
      --disable-seccomp
      --disable-snappy
      --disable-tpm
      --disable-vde
      --disable-vhost-net
      --disable-vhost-scsi
      --disable-vhost-user
      --disable-vhost-vsock
      --disable-virglrenderer
      --disable-virtfs
      --disable-vnc
      --disable-xfsctl
    ]
    # Sharing Samba directories in QEMU requires the samba.org smbd which is
    # incompatible with the macOS-provided version. This will lead to
    # silent runtime failures, so we set it to a Homebrew path in order to
    # obtain sensible runtime errors. This will also be compatible with
    # Samba installations from external taps.
    args << "--smbd=#{HOMEBREW_PREFIX}/sbin/samba-dot-org-smbd"

    on_macos do
      args << "--enable-cocoa"
    end

    system "./configure", *args
    system "make", "V=1", "install"
  end

  test do
    expected = build.stable? ? version.to_s : "QEMU Project"
    assert_match expected, shell_output("#{bin}/qemu-system-i386 --version")
    assert_match expected, shell_output("#{bin}/qemu-system-x86_64 --version")
    resource("test-image").stage testpath
    assert_match "file format: raw", shell_output("#{bin}/qemu-img info FLOPPY.img")
  end
end
