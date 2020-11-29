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
  depends_on "gettext"
  depends_on "glib"
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
      --disable-auth-pam
      --disable-bochs
      --disable-brlapi
      --disable-cap-ng
      --disable-cloop
      --disable-cocoa
      --disable-crypto-afalg
      --disable-curl
      --disable-fdt
      --disable-gcrypt
      --disable-glusterfs
      --disable-gnutls
      --disable-gtk
      --disable-hax
      --disable-libdaxctl
      --disable-libiscsi
      --disable-libnfs
      --disable-libpmem
      --disable-libssh
      --disable-libusb
      --disable-libxml2
      --disable-linux-aio
      --disable-linux-io-uring
      --disable-live-block-migration
      --disable-lzfse
      --disable-lzo
      --disable-mpath
      --disable-netmap
      --disable-nettle
      --disable-numa
      --disable-opengl
      --disable-parallels
      --disable-qed
      --disable-qom-cast-debug
      --disable-rbd
      --disable-rdma
      --disable-replication
      --disable-sdl
      --disable-seccomp
      --disable-sheepdog
      --disable-snappy
      --disable-tpm
      --disable-usb-redir
      --disable-vde
      --disable-vdi
      --disable-vhost-crypto
      --disable-vhost-kernel
      --disable-vhost-net
      --disable-vhost-scsi
      --disable-vhost-user
      --disable-vhost-vdpa
      --disable-vhost-vsock
      --disable-virglrenderer
      --disable-virtfs
      --disable-vnc
      --disable-vvfat
      --disable-xen
      --disable-xfsctl
      --disable-xkbcommon
      --disable-zstd
    ]

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
