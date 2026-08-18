#!/bin/bash
difftastic_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$difftastic_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <difftastic_version> <build_version> [architecture]"
    echo "Example: $0 0.70.0 1 arm64"
    echo "Example: $0 0.70.0 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, all"
    exit 1
fi

# Upstream (Wilfred/difftastic) tags releases WITHOUT a leading 'v' and the
# release asset names do NOT contain the version -- it only appears in the URL.
UPSTREAM_REPO="Wilfred/difftastic"

# Map a Debian/Ubuntu architecture to the upstream release target triple.
# Only amd64 and arm64 exist upstream. amd64 uses the fully static musl build
# for maximum suite compatibility; aarch64 only has a glibc build, but it needs
# at most GLIBC_2.18, so it runs on every suite we target (oldest is Ubuntu
# jammy / Debian bookworm, both glibc >= 2.35 / 2.36).
get_difft_target() {
    local arch=$1
    case "$arch" in
        "amd64")
            echo "x86_64-unknown-linux-musl"
            ;;
        "arm64")
            echo "aarch64-unknown-linux-gnu"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Runtime dependencies of the shipped binary, per architecture.
# Upstream recommends depending on a MIME database (tree_magic_mini reads
# /usr/share/mime) -- that is shared-mime-info on Debian/Ubuntu.
get_package_depends() {
    local arch=$1
    case "$arch" in
        "amd64")
            echo "shared-mime-info"
            ;;
        "arm64")
            echo "libc6 (>= 2.18), libgcc-s1, shared-mime-info"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local difft_target difft_release package_depends

    difft_target=$(get_difft_target "$build_arch")
    if [ -z "$difft_target" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64"
        return 1
    fi
    package_depends=$(get_package_depends "$build_arch")
    difft_release="difft-${difftastic_VERSION}-${difft_target}"

    echo "Building for architecture: $build_arch using difft-${difft_target}.tar.gz"

    # Clean up any previous builds for this architecture
    rm -rf "$difft_release" || true
    rm -f "${difft_release}.tar.gz" || true

    # Download and extract the difft binary for this architecture.
    if ! wget -q "https://github.com/${UPSTREAM_REPO}/releases/download/${difftastic_VERSION}/difft-${difft_target}.tar.gz" -O "${difft_release}.tar.gz"; then
        echo "❌ Failed to download difft binary for $build_arch"
        return 1
    fi

    # difftastic tarballs are flat (just 'difft'), extract into a per-release directory
    mkdir -p "$difft_release"
    if ! tar -xf "${difft_release}.tar.gz" -C "$difft_release"; then
        echo "❌ Failed to extract difft binary for $build_arch"
        return 1
    fi

    rm -f "${difft_release}.tar.gz"

    # The release tarballs contain no man page; upstream generates difft.1 and
    # commits it at the repository root, so take it from the same tag.
    if ! wget -q "https://raw.githubusercontent.com/${UPSTREAM_REPO}/${difftastic_VERSION}/difft.1" -O "${difft_release}/difft.1"; then
        echo "❌ Failed to download difft.1 man page for ${difftastic_VERSION}"
        return 1
    fi

    # Build packages for all supported distributions. Upstream ships binaries
    # for amd64 and arm64 only, and both work on every suite we target.
    declare -a arr=("jammy" "noble" "questing" "resolute")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$difftastic_VERSION-${BUILD_VERSION}~${dist}_${build_arch}_ubu"
        echo "  Building $FULL_VERSION"

        if ! docker build . -f Dockerfile.ubu -t "difftastic-ubuntu-$dist-$build_arch" \
            --build-arg UBUNTU_DIST="$dist" \
            --build-arg difftastic_VERSION="$difftastic_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg PACKAGE_DEPENDS="$package_depends" \
            --build-arg DIFFT_RELEASE="$difft_release"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "difftastic-ubuntu-$dist-$build_arch")"
        if ! docker cp "$id:/difftastic_$FULL_VERSION.deb" - > "./difftastic_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./difftastic_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    # Clean up extracted directory
    rm -rf "$difft_release" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building difftastic $difftastic_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    # Upstream only publishes Linux binaries for x86_64 and aarch64.
    ARCHITECTURES=("amd64" "arm64")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la difftastic_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
