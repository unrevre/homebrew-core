class Gnutls < Formula
  desc "GNU Transport Layer Security (TLS) Library"
  homepage "https://gnutls.org/"
  url "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.15.tar.xz"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/gnutls/v3.6/gnutls-3.6.15.tar.xz"
  sha256 "0ea8c3283de8d8335d7ae338ef27c53a916f15f382753b174c18b45ffd481558"
  # license "LGPL-2.1-or-later AND GPL-3.0-only" - review syntax after resolving https://github.com/Homebrew/brew/pull/8260
  license "GPL-3.0-only"

  livecheck do
    url "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/"
    regex(/href=.*?gnutls[._-]v?(\d+(?:\.\d+)*)\.t/i)
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkg-config" => :build
  depends_on "gmp"
  depends_on "guile"
  depends_on "libidn2"
  depends_on "libtasn1"
  depends_on "libunistring"
  depends_on "nettle"
  depends_on "p11-kit"

  on_linux do
    depends_on "autogen" => :build
  end

  def install
    # Fix build with Xcode 12
    # https://gitlab.com/gnutls/gnutls/-/issues/1116
    ENV.append "CFLAGS", "-Wno-implicit-function-declaration"

    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --disable-static
      --prefix=#{prefix}
      --sysconfdir=#{etc}
      --with-default-trust-store-file=#{pkgetc}/cert.pem
      --with-guile-site-dir=#{share}/guile/site/3.0
      --with-guile-site-ccache-dir=#{lib}/guile/3.0/site-ccache
      --with-guile-extension-dir=#{lib}/guile/3.0/extensions
      --disable-heartbeat-support
      --with-p11-kit
    ]

    system "./configure", *args
    # Adding LDFLAGS= to allow the build on Catalina 10.15.4
    # See https://gitlab.com/gnutls/gnutls/-/issues/966
    system "make", "LDFLAGS=", "install"

    # certtool shadows the macOS certtool utility
    mv bin/"certtool", bin/"gnutls-certtool"
    mv man1/"certtool.1", man1/"gnutls-certtool.1"
  end

  def post_install
    keychains = %w[
      /System/Library/Keychains/SystemRootCertificates.keychain
    ]

    certs_list = `security find-certificate -a -p #{keychains.join(" ")}`
    certs = certs_list.scan(/-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m)

    valid_certs = certs.select do |cert|
      IO.popen("openssl x509 -inform pem -checkend 0 -noout", "w") do |openssl_io|
        openssl_io.write(cert)
        openssl_io.close_write
      end

      $CHILD_STATUS.success?
    end

    pkgetc.mkpath
    (pkgetc/"cert.pem").atomic_write(valid_certs.join("\n"))

    # Touch gnutls.go to avoid Guile recompilation.
    # See https://github.com/Homebrew/homebrew-core/pull/60307#discussion_r478917491
    touch "#{lib}/guile/3.0/site-ccache/gnutls.go"
  end

  def caveats
    <<~EOS
      If you are going to use the Guile bindings you will need to add the following
      to your .bashrc or equivalent in order for Guile to find the TLS certificates
      database:
        export GUILE_TLS_CERTIFICATE_DIRECTORY=/usr/local/etc/gnutls/
    EOS
  end

  test do
    system bin/"gnutls-cli", "--version"

    gnutls = testpath/"gnutls.scm"
    gnutls.write <<~EOS
      (use-modules (gnutls))
      (gnutls-version)
    EOS

    ENV["GUILE_AUTO_COMPILE"] = "0"
    ENV["GUILE_LOAD_PATH"] = HOMEBREW_PREFIX/"share/guile/site/3.0"
    ENV["GUILE_LOAD_COMPILED_PATH"] = HOMEBREW_PREFIX/"lib/guile/3.0/site-ccache"
    ENV["GUILE_SYSTEM_EXTENSIONS_PATH"] = HOMEBREW_PREFIX/"lib/guile/3.0/extensions"

    system "guile", gnutls
  end
end
