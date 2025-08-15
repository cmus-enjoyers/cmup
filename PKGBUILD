# Maintainer: Viktor Yenokh <viktorenokh@gmail.com>
pkgname=zmup-git
pkgver=0.0.0.r
pkgrel=1
pkgdesc="Cmus playlist generator"
arch=(x86_64 aarch64)
url="https://github.com/cmus-enjoyers/cmup"
license=('MIT')
depends=()
provides=("${pkgname%-git}")
conflicts=("${pkgname%-git}")
makedepends=('zig' 'git')
source=("$pkgname::git+$url.git")
sha256sums=('SKIP')

pkgver() {
    cd "$srcdir"

    echo '0.0.0.r'
    
    # git describe --tags --long 2>/dev/null \
    #     | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g' \
    #     || echo "0.0.0.r$(git rev-list --count HEAD).g$(git rev-parse --short HEAD)"

}

build() {
    cd $pkgname

    zig build -Doptimize=ReleaseFast
}

package() {
    cd $pkgname

    install -Dm755 "zig-out/bin/zmup" "$pkgdir/usr/bin/zmup"
}

