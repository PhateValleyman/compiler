#!/bin/bash
set -e

# Universal Package Builder - Enhanced version with colors and optimizations
# Exact replication of original build scripts with download options

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions with colors
log_info() {
    echo -e "${BLUE}${BOLD}[INFO]${NC} ${WHITE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${NC} ${GREEN}$1${NC}"
}

log_warning() {
    echo -e "${YELLOW}${BOLD}[WARNING]${NC} ${YELLOW}$1${NC}"
}

log_error() {
    echo -e "${RED}${BOLD}[ERROR]${NC} ${RED}$1${NC}" >&2
}

log_step() {
    echo -e "${MAGENTA}${BOLD}[STEP]${NC} ${CYAN}$1${NC}"
}

log_package() {
    echo -e "${GREEN}${BOLD}[PACKAGE]${NC} ${WHITE}$1${NC}"
}

# Configuration from original scripts
export FFP_DIR="/data/data/com.termux/files/home/compiler/ffp"
export PATH="$FFP_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$FFP_DIR/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$FFP_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export CPPFLAGS="-I$FFP_DIR/include"
export LDFLAGS="-L$FFP_DIR/lib -Wl,-rpath,$FFP_DIR/lib"
export CFLAGS="-Os -pipe"
export CXXFLAGS="-Os -pipe"
export CC="gcc"
export CXX="g++"

# Global variables
FORCE_BUILD=false

# Progress indicator
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}Progress:${NC} [${GREEN}%*s${NC}${RED}%*s${NC}] %d%% (%d/%d)" \
        $completed "" $remaining "" $percentage $current $total
}

# Create directories with verification
create_directories() {
    log_step "Creating directory structure..."
    
    local dirs=(
        "$FFP_DIR/bin"
        "$FFP_DIR/lib" 
        "$FFP_DIR/include"
        "$FFP_DIR/share"
        "$FFP_DIR/man"
        "$FFP_DIR/share/doc"
        "$FFP_DIR/var/log"
        "$FFP_DIR/var/cache/src"
        "/data/data/com.termux/files/home/compiler/tmp/ffp-build"
    )
    
    for dir in "${dirs[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            log_info "Created: $dir"
        else
            log_warning "Could not create: $dir"
        fi
    done
}

# Source cache directory
SRC_CACHE="$FFP_DIR/var/cache/src"

# Dependency tree based on exact build order
declare -A DEPENDENCIES=(
    ["gmp"]=""
    ["mpfr"]="gmp" 
    ["mpc"]="gmp mpfr"
    ["isl"]="gmp"
    ["libtool"]=""
    ["binutils"]="gmp mpfr mpc isl"
    ["m4"]=""
    ["autoconf"]="m4"
    ["automake"]="autoconf m4"
    ["libiconv"]=""
    ["gettext"]="libiconv"
    ["make"]=""
    ["pkg-config"]=""
    ["intltool"]="autoconf automake libtool"
    ["help2man"]=""
    ["texinfo"]=""
    ["bison"]=""
    ["flex"]=""
    ["tcl"]=""
    ["expect"]="tcl"
    ["dejagnu"]="expect tcl"
    ["check"]=""
)

# Package display names for better output
declare -A PACKAGE_NAMES=(
    ["gmp"]="GMP Arithmetic Library"
    ["mpfr"]="MPFR Floating-Point Library"
    ["mpc"]="MPC Complex Number Library"
    ["isl"]="Integer Set Library"
    ["libtool"]="GNU Libtool"
    ["binutils"]="GNU Binutils"
    ["m4"]="GNU M4"
    ["autoconf"]="GNU Autoconf"
    ["automake"]="GNU Automake"
    ["libiconv"]="GNU libiconv"
    ["gettext"]="GNU gettext"
    ["make"]="GNU Make"
    ["pkg-config"]="pkg-config"
    ["intltool"]="Intltool"
    ["help2man"]="Help2man"
    ["texinfo"]="GNU Texinfo"
    ["bison"]="GNU Bison"
    ["flex"]="Flex"
    ["tcl"]="Tcl"
    ["expect"]="Expect"
    ["dejagnu"]="DejaGNU"
    ["check"]="Check Unit Testing"
)

# Exact versions and URLs from original scripts
declare -A PACKAGE_INFO=(
    # From 1gmp.sh
    ["gmp_version"]="6.3.0"
    ["gmp_url"]="https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz"
    ["gmp_configure"]="--prefix=$FFP_DIR --enable-cxx --enable-static --enable-shared"
    
    # From 2mpfr.sh  
    ["mpfr_version"]="4.2.1"
    ["mpfr_url"]="https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz"
    ["mpfr_configure"]="--prefix=$FFP_DIR --with-gmp=$FFP_DIR --enable-static --enable-shared"
    
    # From 3mpc.sh
    ["mpc_version"]="1.3.1"
    ["mpc_url"]="https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz"
    ["mpc_configure"]="--prefix=$FFP_DIR --with-gmp=$FFP_DIR --with-mpfr=$FFP_DIR --enable-static --enable-shared"
    
    # From 4isl.sh
    ["isl_version"]="0.26"
    ["isl_url"]="https://downloads.sourceforge.net/project/libisl/isl-0.26.tar.xz"
    ["isl_configure"]="--prefix=$FFP_DIR --with-gmp-prefix=$FFP_DIR --enable-static --enable-shared"
    
    # From libtool.sh
    ["libtool_version"]="2.4.7"
    ["libtool_url"]="https://ftp.gnu.org/gnu/libtool/libtool-2.4.7.tar.xz"
    ["libtool_configure"]="--prefix=$FFP_DIR --enable-static --enable-shared"
    
    # From binutils.sh
    ["binutils_version"]="2.42"
    ["binutils_url"]="https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz"
    ["binutils_configure"]="--prefix=$FFP_DIR --with-libiconv-prefix=$FFP_DIR --with-gmp=$FFP_DIR --with-mpfr=$FFP_DIR --with-mpc=$FFP_DIR --with-isl=$FFP_DIR --enable-gold --enable-ld --enable-plugins --enable-threads --disable-werror"
    
    # From m4.sh
    ["m4_version"]="1.4.19"
    ["m4_url"]="https://ftp.gnu.org/gnu/m4/m4-1.4.19.tar.xz"
    ["m4_configure"]="--prefix=$FFP_DIR"
    
    # From autoconf.sh
    ["autoconf_version"]="2.72"
    ["autoconf_url"]="https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz"
    ["autoconf_configure"]="--prefix=$FFP_DIR"
    
    # From automake.sh
    ["automake_version"]="1.16.5"
    ["automake_url"]="https://ftp.gnu.org/gnu/automake/automake-1.16.5.tar.xz"
    ["automake_configure"]="--prefix=$FFP_DIR"
    
    # From libiconv.sh
    ["libiconv_version"]="1.17"
    ["libiconv_url"]="https://ftp.gnu.org/gnu/libiconv/libiconv-1.17.tar.gz"
    ["libiconv_configure"]="--prefix=$FFP_DIR --enable-static --enable-shared"
    
    # From gettext.sh
    ["gettext_version"]="0.22.5"
    ["gettext_url"]="https://ftp.gnu.org/gnu/gettext/gettext-0.22.5.tar.xz"
    ["gettext_configure"]="--prefix=$FFP_DIR --disable-java --disable-native-java --enable-threads --with-libiconv-prefix=$FFP_DIR"
    
    # From make.sh
    ["make_version"]="4.4.1"
    ["make_url"]="https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz"
    ["make_configure"]="--prefix=$FFP_DIR --without-guile"
    
    # From pkg-config.sh
    ["pkg-config_version"]="0.29.2"
    ["pkg-config_url"]="https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz"
    ["pkg-config_configure"]="--prefix=$FFP_DIR --with-internal-glib --disable-host-tool"
    
    # From intltool.sh
    ["intltool_version"]="0.51.0"
    ["intltool_url"]="https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz"
    ["intltool_configure"]="--prefix=$FFP_DIR"
    
    # From help2man.sh
    ["help2man_version"]="1.49.3"
    ["help2man_url"]="https://ftp.gnu.org/gnu/help2man/help2man-1.49.3.tar.xz"
    ["help2man_configure"]="--prefix=$FFP_DIR"
    
    # From texinfo.sh
    ["texinfo_version"]="7.1"
    ["texinfo_url"]="https://ftp.gnu.org/gnu/texinfo/texinfo-7.1.tar.xz"
    ["texinfo_configure"]="--prefix=$FFP_DIR"
    
    # From bison.sh
    ["bison_version"]="3.8.2"
    ["bison_url"]="https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz"
    ["bison_configure"]="--prefix=$FFP_DIR"
    
    # From flex.sh
    ["flex_version"]="2.6.4"
    ["flex_url"]="https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz"
    ["flex_configure"]="--prefix=$FFP_DIR"
    
    # From tcl.sh
    ["tcl_version"]="8.6.13"
    ["tcl_url"]="https://prdownloads.sourceforge.net/tcl/tcl8.6.13-src.tar.gz"
    ["tcl_configure"]="--prefix=$FFP_DIR --enable-threads --enable-shared"
    
    # From expect.sh
    ["expect_version"]="5.45.4"
    ["expect_url"]="https://prdownloads.sourceforge.net/expect/expect5.45.4.tar.gz"
    ["expect_configure"]="--prefix=$FFP_DIR --with-tcl=$FFP_DIR/lib --with-tclinclude=$FFP_DIR/include"
    
    # From dejagnu.sh
    ["dejagnu_version"]="1.6.3"
    ["dejagnu_url"]="https://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz"
    ["dejagnu_configure"]="--prefix=$FFP_DIR"
    
    # From check.sh
    ["check_version"]="0.15.2"
    ["check_url"]="https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz"
    ["check_configure"]="--prefix=$FFP_DIR"
)

# Show comprehensive help
show_help() {
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           Universal Package Builder - ZyXEL NSA320          ║"
    echo "║                 FFP (fonz fun plug) Enhanced                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${CYAN}${BOLD}DESCRIPTION${NC}"
    echo "  Build toolchain for ZyXEL NSA320 using FFP (fonz fun plug)"
    echo "  Exact replication of original build scripts with enhancements"
    echo ""
    
    echo -e "${CYAN}${BOLD}SYNOPSIS${NC}"
    echo -e "  ${WHITE}$0 [OPTIONS] [COMMAND] [PACKAGE]${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}BUILD COMMANDS${NC}"
    echo -e "  ${GREEN}build-all${NC}                    Build all packages in exact order"
    echo -e "  ${GREEN}build [PACKAGE]${NC}             Build specific package and dependencies"
    echo -e "  ${GREEN}list${NC}                        Show available packages"
    echo -e "  ${GREEN}clean${NC}                       Clean build and cache directories"
    echo ""
    
    echo -e "${CYAN}${BOLD}DOWNLOAD COMMANDS${NC}"
    echo -e "  ${GREEN}-d, --download [PACKAGE]${NC}    Download source for package and dependencies"
    echo -e "  ${GREEN}-d, --download all${NC}          Download all source packages"
    echo -e "  ${GREEN}-d, --download status${NC}       Show download status"
    echo ""
    
    echo -e "${CYAN}${BOLD}OPTIONS${NC}"
    echo -e "  ${GREEN}-f, --force${NC}                 Force build without dependencies (build command only)"
    echo -e "  ${GREEN}-h, --help${NC}                  Show this help message"
    echo ""
    
    echo -e "${CYAN}${BOLD}AVAILABLE PACKAGES${NC}"
    echo -e "  ${WHITE}gmp mpfr mpc isl libtool binutils m4 autoconf automake${NC}"
    echo -e "  ${WHITE}libiconv gettext make pkg-config intltool help2man${NC}"
    echo -e "  ${WHITE}texinfo bison flex tcl expect dejagnu check${NC}"
    echo ""
    
    echo -e "${YELLOW}${BOLD}EXAMPLES${NC}"
    echo -e "  ${WHITE}$0 build-all${NC}                # Build complete toolchain"
    echo -e "  ${WHITE}$0 build binutils${NC}           # Build binutils and all dependencies"
    echo -e "  ${WHITE}$0 build binutils --force${NC}   # Build only binutils, skip dependencies"
    echo -e "  ${WHITE}$0 -d all${NC}                   # Download all source packages"
    echo -e "  ${WHITE}$0 -d gmp${NC}                   # Download gmp and dependencies"
    echo -e "  ${WHITE}$0 -d status${NC}                # Show download status"
    echo -e "  ${WHITE}$0 list${NC}                     # Show available packages"
    echo -e "  ${WHITE}$0 clean${NC}                    # Clean build and cache"
    echo ""
    
    echo -e "${CYAN}${BOLD}NOTES${NC}"
    echo "  - Build order respects package dependencies"
    echo "  - Use --force to build single package without dependencies"
    echo "  - Source cache: $SRC_CACHE"
    echo "  - Install directory: $FFP_DIR"
    echo ""
}

# Download source only (without extraction)
download_source_only() {
    local pkg=$1
    local version=${PACKAGE_INFO[${pkg}_version]}
    local url=${PACKAGE_INFO[${pkg}_url]}
    local display_name=${PACKAGE_NAMES[$pkg]:-$pkg}
    
    local filename=$(basename "$url")
    local cache_path="$SRC_CACHE/$filename"
    
    log_package "$display_name $version"
    
    if [ -f "$cache_path" ]; then
        local existing_size=$(stat -c%s "$cache_path" 2>/dev/null || stat -f%z "$cache_path")
        log_info "Already exists: $filename ($(numfmt --to=iec $existing_size))"
        return 0
    fi
    
    log_info "Downloading: $url"
    log_info "Destination: $cache_path"
    
    if wget --continue -q --show-progress -c -O "$cache_path" "$url"; then
        local file_size=$(stat -c%s "$cache_path" 2>/dev/null || stat -f%z "$cache_path")
        log_success "Downloaded: $(numfmt --to=iec $file_size)"
    else
        log_error "Failed to download $pkg"
        rm -f "$cache_path"
        return 1
    fi
}

# Download and extract function for building
download_extract() {
    local pkg=$1
    local version=${PACKAGE_INFO[${pkg}_version]}
    local url=${PACKAGE_INFO[${pkg}_url]}
    local display_name=${PACKAGE_NAMES[$pkg]:-$pkg}
    
    local filename=$(basename "$url")
    local cache_path="$SRC_CACHE/$filename"
    
    # Download if not in cache
    if [ ! -f "$cache_path" ]; then
        log_package "$display_name $version"
        log_info "Downloading..."
        if ! wget -q --show-progress -c -O "$cache_path" "$url"; then
            log_error "Failed to download $pkg"
            return 1
        fi
    fi
    
    # Copy to tmp for building
    cp "$cache_path" "/tmp/$filename"
    
    log_info "Extracting..."
    if tar -xf "/tmp/$filename" -C /tmp/ffp-build/; then
        local extracted_dir=$(tar -tf "/tmp/$filename" | head -1 | cut -f1 -d"/")
        cd "/tmp/ffp-build/$extracted_dir"
        log_success "Extracted to: /tmp/ffp-build/$extracted_dir"
    else
        log_error "Failed to extract $filename"
        return 1
    fi
}

# Download package and its dependencies
download_package() {
    local pkg=$1
    
    if [ -z "$pkg" ]; then
        log_error "No package specified for download"
        return 1
    fi
    
    if [ -z "${DEPENDENCIES[$pkg]}" ]; then
        log_error "Unknown package '$pkg'"
        echo -e "${CYAN}Available packages:${NC}"
        printf "  %s\n" "${!DEPENDENCIES[@]}" | sort
        return 1
    fi
    
    # Download dependencies first
    local deps=${DEPENDENCIES[$pkg]}
    for dep in $deps; do
        log_info "Downloading dependency: $dep for $pkg"
        download_package "$dep"
    done
    
    # Download the package itself
    download_source_only "$pkg"
}

# Download all packages
download_all() {
    log_step "Downloading all source packages..."
    log_info "Cache directory: $SRC_CACHE"
    mkdir -p "$SRC_CACHE"
    
    local total=${#DEPENDENCIES[@]}
    local count=0
    
    for pkg in "${!DEPENDENCIES[@]}"; do
        count=$((count + 1))
        show_progress $count $total
        download_source_only "$pkg"
    done
    
    echo # New line after progress
    log_success "All packages downloaded to $SRC_CACHE"
    log_info "Total files: $(ls "$SRC_CACHE" | wc -l)"
    log_info "Total size: $(du -sh "$SRC_CACHE" | cut -f1)"
}

# Show download status
show_download_status() {
    echo -e "${CYAN}${BOLD}Source cache status: $SRC_CACHE${NC}"
    echo -e "${BLUE}===========================================${NC}"
    
    local total_packages=${#DEPENDENCIES[@]}
    local downloaded=0
    local total_size=0
    
    for pkg in "${!DEPENDENCIES[@]}"; do
        local url=${PACKAGE_INFO[${pkg}_url]}
        local filename=$(basename "$url")
        local cache_path="$SRC_CACHE/$filename"
        local display_name=${PACKAGE_NAMES[$pkg]:-$pkg}
        
        if [ -f "$cache_path" ]; then
            downloaded=$((downloaded + 1))
            local size=$(stat -c%s "$cache_path" 2>/dev/null || stat -f%z "$cache_path")
            total_size=$((total_size + size))
            printf "${GREEN}✓${NC} %-25s %-10s ${GREEN}%s${NC}\n" "$display_name" "$(numfmt --to=iec $size)" "DOWNLOADED"
        else
            printf "${RED}✗${NC} %-25s %-10s ${RED}%s${NC}\n" "$display_name" "---" "MISSING"
        fi
    done
    
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${CYAN}Downloaded:${NC} $downloaded/$total_packages packages"
    echo -e "${CYAN}Total size:${NC} $(numfmt --to=iec $total_size)"
    echo -e "${CYAN}Cache location:${NC} $SRC_CACHE"
}

# Build functions with exact configurations from original scripts
build_gmp() {
    download_extract "gmp"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[gmp_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf gmp-*
}

build_mpfr() {
    download_extract "mpfr" 
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[mpfr_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf mpfr-*
}

build_mpc() {
    download_extract "mpc"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[mpc_configure]}
    log_info "Building..."
    make -j$(nproc) 
    make install
    cd /tmp/ffp-build
    rm -rf mpc-*
}

build_isl() {
    download_extract "isl"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[isl_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf isl-*
}

build_libtool() {
    download_extract "libtool"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[libtool_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    libtool --finish $FFP_DIR/lib
    cd /tmp/ffp-build
    rm -rf libtool-*
}

build_binutils() {
    download_extract "binutils"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[binutils_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd $FFP_DIR/bin
    for link in ar as ld ld.bfd nm objcopy objdump ranlib readelf strip; do
        ln -sf $link $(uname -m)-pc-linux-gnu-$link 2>/dev/null || true
    done
    cd /tmp/ffp-build
    rm -rf binutils-*
}

build_m4() {
    download_extract "m4"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[m4_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf m4-*
}

build_autoconf() {
    download_extract "autoconf"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[autoconf_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf autoconf-*
}

build_automake() {
    download_extract "automake"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[automake_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd $FFP_DIR/bin
    ln -sf aclocal aclocal-1.16 2>/dev/null || true
    cd /tmp/ffp-build
    rm -rf automake-*
}

build_libiconv() {
    download_extract "libiconv"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[libiconv_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    if [ -f $FFP_DIR/lib/charset.alias ]; then
        mv $FFP_DIR/lib/charset.alias $FFP_DIR/lib/charset.alias.iconv
    fi
    cd /tmp/ffp-build
    rm -rf libiconv-*
}

build_gettext() {
    download_extract "gettext"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[gettext_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd $FFP_DIR/bin
    ln -sf msgfmt gmsgfmt 2>/dev/null || true
    cd /tmp/ffp-build
    rm -rf gettext-*
}

build_make() {
    download_extract "make"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[make_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf make-*
}

build_pkg_config() {
    download_extract "pkg-config"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[pkg-config_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf pkg-config-*
}

build_intltool() {
    download_extract "intltool"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[intltool_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf intltool-*
}

build_help2man() {
    download_extract "help2man"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[help2man_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf help2man-*
}

build_texinfo() {
    download_extract "texinfo"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[texinfo_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd $FFP_DIR/bin
    ln -sf makeinfo texi2any 2>/dev/null || true
    cd /tmp/ffp-build
    rm -rf texinfo-*
}

build_bison() {
    download_extract "bison"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[bison_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd $FFP_DIR/bin
    ln -sf bison yacc 2>/dev/null || true
    cd /tmp/ffp-build
    rm -rf bison-*
}

build_flex() {
    download_extract "flex"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[flex_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd $FFP_DIR/bin
    ln -sf flex lex 2>/dev/null || true
    cd /tmp/ffp-build
    rm -rf flex-*
}

build_tcl() {
    download_extract "tcl"
    cd unix
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[tcl_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd $FFP_DIR/bin
    ln -sf tclsh8.6 tclsh 2>/dev/null || true
    cd /tmp/ffp-build
    rm -rf tcl-*
}

build_expect() {
    download_extract "expect"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[expect_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf expect-*
}

build_dejagnu() {
    download_extract "dejagnu"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[dejagnu_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf dejagnu-*
}

build_check() {
    download_extract "check"
    log_info "Configuring..."
    ./configure ${PACKAGE_INFO[check_configure]}
    log_info "Building..."
    make -j$(nproc)
    make install
    cd /tmp/ffp-build
    rm -rf check-*
}

# Package builder with dependency handling
build_package() {
    local pkg=$1
    local force=$2
    local log_file="$FFP_DIR/var/log/${pkg}.log"
    local display_name=${PACKAGE_NAMES[$pkg]:-$pkg}
    
    mkdir -p $(dirname "$log_file")
    
    log_step "Building $display_name..."
    log_info "Log file: $log_file"
    
    # Build dependencies first unless force mode is enabled
    if [ "$force" != "true" ]; then
        local deps=${DEPENDENCIES[$pkg]}
        if [ -n "$deps" ]; then
            log_info "Building dependencies: $deps"
            for dep in $deps; do
                build_package "$dep" "false"
            done
        fi
    else
        log_warning "Force mode: Skipping dependencies for $display_name"
    fi
    
    # Build the package
    {
        echo "=== Starting build of $pkg ==="
        date
        build_$pkg
        echo "=== Completed build of $pkg ==="
        date
    } >> "$log_file" 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "Completed $display_name"
    else
        log_error "Failed to build $display_name"
        log_info "Check log file: $log_file"
        return 1
    fi
}

# Show system information
show_system_info() {
    log_step "System Information"
    echo -e "${CYAN}Architecture:${NC} $(uname -m)"
    echo -e "${CYAN}OS:${NC} $(uname -o)"
    echo -e "${CYAN}Kernel:${NC} $(uname -r)"
    echo -e "${CYAN}CPU Cores:${NC} $(nproc)"
    echo -e "${CYAN}FFP Directory:${NC} $FFP_DIR"
    echo -e "${CYAN}Source Cache:${NC} $SRC_CACHE"
}

# Main function with enhanced argument parsing
main() {
    local command=""
    local package=""
    
    # Show banner
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           Universal Package Builder - ZyXEL NSA320          ║"
    echo "║                 FFP (fonz fun plug) Enhanced                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Show help if no arguments provided
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    show_system_info
    echo
    create_directories
    
    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                FORCE_BUILD=true
                shift
                ;;
            -d|--download)
                if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                    package="$2"
                    shift 2
                else
                    package="all"
                    shift
                fi
                
                case $package in
                    "all")
                        download_all
                        ;;
                    "status")
                        show_download_status
                        ;;
                    *)
                        if [ -n "${DEPENDENCIES[$package]}" ]; then
                            download_package "$package"
                        else
                            log_error "Unknown package '$package'"
                            echo -e "${CYAN}Available packages:${NC}"
                            printf "  %s\n" "${!DEPENDENCIES[@]}" | sort
                            exit 1
                        fi
                        ;;
                esac
                exit 0
                ;;
            build-all)
                command="build-all"
                shift
                ;;
            build)
                command="build"
                if [[ -n "$2" && ! "$2" =~ ^- ]]; then
                    package="$2"
                    shift 2
                else
                    log_error "Build command requires a package name"
                    echo -e "${CYAN}Available packages:${NC}"
                    printf "  %s\n" "${!DEPENDENCIES[@]}" | sort
                    exit 1
                fi
                ;;
            list)
                command="list"
                shift
                ;;
            clean)
                command="clean"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done
    
    case $command in
        "build-all")
            log_step "Building all packages in exact order for ZyXEL NSA320..."
            
            # Phase 1: Core math libraries
            build_package "gmp" "false"
            build_package "mpfr" "false"
            build_package "mpc" "false"
            build_package "isl" "false"
            
            # Phase 2: Libtool first (depends on exact GCC version)
            build_package "libtool" "false"
            
            # Phase 3: Binutils and build tools
            build_package "binutils" "false"
            build_package "m4" "false"
            build_package "autoconf" "false"
            build_package "automake" "false"
            
            # Phase 4: Internationalization (with double libiconv)
            build_package "libiconv" "false"
            build_package "gettext" "false"
            build_package "libiconv" "false"  # Second build as specified
            
            # Phase 5: Additional build tools
            build_package "make" "false"
            build_package "pkg-config" "false"
            build_package "intltool" "false"
            build_package "help2man" "false"
            build_package "texinfo" "false"
            build_package "bison" "false"
            build_package "flex" "false"
            
            # Phase 6: Testing frameworks
            build_package "tcl" "false"
            build_package "expect" "false"
            # dejagnu needs direct terminal access - handle specially
            log_step "Building dejagnu (needs direct terminal access)..."
            build_dejagnu >> $FFP_DIR/var/log/dejagnu.log 2>&1
            
            build_package "check" "false"
            
            log_success "All packages built successfully!"
            log_info "FFP toolchain installed to: $FFP_DIR"
            ;;
            
        "build")
            if [ -n "$package" ]; then
                if [ -n "${DEPENDENCIES[$package]}" ]; then
                    build_package "$package" "$FORCE_BUILD"
                else
                    log_error "Unknown package '$package'"
                    echo -e "${CYAN}Available packages:${NC}"
                    printf "  %s\n" "${!DEPENDENCIES[@]}" | sort
                    exit 1
                fi
            else
                log_error "Please specify a package to build"
                echo -e "${CYAN}Available packages:${NC}"
                printf "  %s\n" "${!DEPENDENCIES[@]}" | sort
            fi
            ;;
            
        "list")
            log_step "Available packages (in build order):"
            echo -e "${CYAN}Phase 1 - Core Math:${NC}"
            echo "  1. gmp - ${PACKAGE_NAMES[gmp]}"
            echo "  2. mpfr - ${PACKAGE_NAMES[mpfr]}"
            echo "  3. mpc - ${PACKAGE_NAMES[mpc]}"
            echo "  4. isl - ${PACKAGE_NAMES[isl]}"
            echo -e "${CYAN}Phase 2 - Libtool:${NC}"
            echo "  5. libtool - ${PACKAGE_NAMES[libtool]}"
            echo -e "${CYAN}Phase 3 - Binutils & Build Tools:${NC}"
            echo "  6. binutils - ${PACKAGE_NAMES[binutils]}"
            echo "  7. m4 - ${PACKAGE_NAMES[m4]}"
            echo "  8. autoconf - ${PACKAGE_NAMES[autoconf]}"
            echo "  9. automake - ${PACKAGE_NAMES[automake]}"
            echo -e "${CYAN}Phase 4 - Internationalization:${NC}"
            echo "  10. libiconv - ${PACKAGE_NAMES[libiconv]}"
            echo "  11. gettext - ${PACKAGE_NAMES[gettext]}"
            echo "  12. libiconv - ${PACKAGE_NAMES[libiconv]} (again)"
            echo -e "${CYAN}Phase 5 - Additional Tools:${NC}"
            echo "  13. make - ${PACKAGE_NAMES[make]}"
            echo "  14. pkg-config - ${PACKAGE_NAMES[pkg-config]}"
            echo "  15. intltool - ${PACKAGE_NAMES[intltool]}"
            echo "  16. help2man - ${PACKAGE_NAMES[help2man]}"
            echo "  17. texinfo - ${PACKAGE_NAMES[texinfo]}"
            echo "  18. bison - ${PACKAGE_NAMES[bison]}"
            echo "  19. flex - ${PACKAGE_NAMES[flex]}"
            echo -e "${CYAN}Phase 6 - Testing Frameworks:${NC}"
            echo "  20. tcl - ${PACKAGE_NAMES[tcl]}"
            echo "  21. expect - ${PACKAGE_NAMES[expect]}"
            echo "  22. dejagnu - ${PACKAGE_NAMES[dejagnu]}"
            echo "  23. check - ${PACKAGE_NAMES[check]}"
            ;;
            
        "clean")
            log_step "Cleaning build directories..."
            rm -rf /tmp/ffp-build/*
            log_step "Cleaning source cache..."
            rm -rf "$SRC_CACHE"/*
            log_success "Clean completed"
            ;;
            
        *)
            log_error "No valid command specified"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
