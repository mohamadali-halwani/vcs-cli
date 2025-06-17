pkgname=vcs
pkgver=1.0.0
pkgrel=1
pkgdesc="Vim cheat sheet command line tool in Bash"
arch=('any')
url="https://github.com/mohamadali-halwani/vcs-cli.git"
license=('GPL3')
depends=('bash' 'jq' 'coreutils')
source=(vcs.sh)
sha256sums=('SKIP')

package() {
    install -Dm755 "$srcdir/vcs.sh" "$pkgdir/usr/bin/vcs"
}
