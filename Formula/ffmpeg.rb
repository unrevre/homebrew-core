class Ffmpeg < Formula
  desc "Play, record, convert, and stream audio and video"
  homepage "https://ffmpeg.org/"
  # None of these parts are used by default, you have to explicitly pass `--enable-gpl`
  # to configure to activate them. In this case, FFmpeg's license changes to GPL v2+.
  license "GPL-2.0-or-later"
  revision 4
  head "https://github.com/FFmpeg/FFmpeg.git"

  stable do
    url "https://ffmpeg.org/releases/ffmpeg-4.3.1.tar.xz"
    sha256 "ad009240d46e307b4e03a213a0f49c11b650e445b1f8be0dda2a9212b34d2ffb"

    # https://trac.ffmpeg.org/ticket/8760
    # Remove in next release
    patch do
      url "https://github.com/FFmpeg/FFmpeg/commit/7c59e1b0f285cd7c7b35fcd71f49c5fd52cf9315.patch?full_index=1"
      sha256 "1cbe1b68d70eadd49080a6e512a35f3e230de26b6e1b1c859d9119906417737f"
    end
  end

  livecheck do
    url "https://ffmpeg.org/download.html"
    regex(/href=.*?ffmpeg[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    sha256 "32d496fe08e4bd5e8b5589d92cc7c6b9e6abb29a3d05f092760eabba81e98a45" => :big_sur
    sha256 "fa20f49d1650469cc4ea6fe6ef6c8d949106235cec8de9a386dec5839c2bb047" => :catalina
    sha256 "7bf14f3a7ffee5a74dd75f2693bd42c35e2cd479dfa59cdc5db976618494814f" => :mojave
    sha256 "5faa06d8ac2008a03d9ed826e1db8b39f14f5c585b9af20250e798db16247dae" => :high_sierra
  end

  depends_on "nasm" => :build
  depends_on "pkg-config" => :build
  depends_on "opus"
  depends_on "sdl2"
  depends_on "xz"

  uses_from_macos "bzip2"
  uses_from_macos "zlib"

  def install
    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cflags=#{ENV.cflags}
      --host-ldflags=#{ENV.ldflags}
      --disable-autodetect
      --disable-everything
      --disable-network
      --enable-gpl
      --enable-nonfree
      --enable-shared
      --enable-pthreads
      --enable-version3
      --enable-bsf=aac_adtstoasc
      --enable-encoder=aac,mpeg4,libopus
      --enable-decoder=aac,mpeg4,libopus
      --enable-muxer=adts,flv,matroska,mp4,opus
      --enable-demuxer=aac,concat,flv,live_flv,matroska,mov,ogg
      --enable-filter=aresample
      --enable-parser=aac,opus
      --enable-protocol=file,pipe
      --enable-ffmpeg
      --enable-ffplay
      --enable-audiotoolbox
      --enable-avfoundation
      --enable-bzlib
      --enable-libopus
      --enable-lzma
      --enable-sdl2
      --enable-videotoolbox
      --enable-zlib
    ]

    system "./configure", *args
    system "make", "install"

    # Build and install additional FFmpeg tools
    system "make", "alltools"
    bin.install Dir["tools/*"].select { |f| File.executable? f }

    # Fix for Non-executables that were installed to bin/
    mv bin/"python", pkgshare/"python", force: true
  end

  test do
    # Create an example mp4 file
    mp4out = testpath/"video.mp4"
    system bin/"ffmpeg", "-filter_complex", "testsrc=rate=1:duration=1", mp4out
    assert_predicate mp4out, :exist?
  end
end
