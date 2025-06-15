pkgname=vimcheat
pkgver=1.0.0
pkgrel=1
pkgdesc="Vim cheat sheet command line tool in Bash"
arch=('any')
url="https://github.com/example/vimcheat"
license=('MIT')
depends=('bash' 'jq' 'coreutils')
source=(vimcheat.sh)
sha256sums=('SKIP')

package() {
    install -Dm755 "$srcdir/vimcheat.sh" "$pkgdir/usr/bin/vimcheat"
}
