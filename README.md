![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/difftastic-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/difftastic-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/difftastic-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/difftastic-debian)

<h1>
   <p align="center">
     <a href="https://difftastic.wilfred.me.uk/"><img src="https://github.com/dariogriffo/difftastic-debian/blob/main/difftastic-logo.png" alt="difftastic Logo" width="200" style="margin-right: 20px"></a>
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/difftastic-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104" style="margin-left: 20px"></a>
     <br>difftastic for Debian
   </p>
</h1>
<p align="center">
 difftastic is a structural diff tool that compares files based on their syntax.
</p>

# difftastic for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for [difftastic](https://github.com/Wilfred/difftastic/) hosted at [deb.griffo.io](https://deb.griffo.io)

Currently supported Debian distros are:
- Bookworm (v12)
- Trixie (v13)
- Forky (v14)
- Sid (testing)

Currently supported Ubuntu distros are:
- Jammy (22.04)
- Noble (24.04)
- Questing (25.10)
- Resolute (26.04)

Supported architectures:
- amd64 (x86_64) - All distributions
- arm64 (aarch64) - All distributions

Upstream publishes Linux binaries for x86_64 and aarch64 only, so no other
architecture is offered. On amd64 the fully static musl build is packaged; on
arm64 upstream only builds against glibc, but that binary requires no symbol
newer than `GLIBC_2.18`, so it runs on every suite listed above.

> **The package is called `difftastic`, the command it installs is `difft`.**

The package ships the `difft` binary and the upstream `difft.1` man page.
Difftastic provides no shell completions and has no completion generator, so
none are shipped.

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the difftastic source code, see
[difftastic](https://github.com/Wilfred/difftastic/).

## Install/Update

📖 **Step-by-step install guide:** [Debian](https://deb.griffo.io/install-latest-difftastic-in-debian.html) · [Ubuntu](https://deb.griffo.io/install-latest-difftastic-in-ubuntu.html)

### The Debian way

> ⚠️ **apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/difftastic-debian/releases) page
> and install it manually (see below).

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y difftastic
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/difftastic-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo dpkg -i <filename>.deb
```
## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Usage

```sh
difft old.js new.js
difft old_dir/ new_dir/
```

### Using difftastic with git

Upstream documents difftastic as a git external diff command
([manual](https://difftastic.wilfred.me.uk/git.html)). One-off:

```sh
git -c diff.external=difft diff
git -c diff.external=difft show --ext-diff
git -c diff.external=difft log -p --ext-diff
```

Upstream's recommended aliases, for `~/.gitconfig`:

```ini
[alias]
    # Difftastic aliases, so `git dlog -p` is `git log -p`
    # with difftastic and likewise for the other subcommands.
    dlog = -c diff.external=difft log --ext-diff
    dshow = -c diff.external=difft show --ext-diff
    ddiff = -c diff.external=difft diff
```

Note that git v2.43.1 and earlier can crash when an external diff is used and
file permissions have changed; upstream suggests the `difftool` configuration
instead if you cannot upgrade git.

## Building

### Build for single architecture
```sh
./build.sh <difftastic_version> <build_version> <architecture>
# Example: ./build.sh 0.70.0 1 arm64
```

### Build for all architectures
```sh
./build.sh <difftastic_version> <build_version> all
# Example: ./build.sh 0.70.0 1 all
```

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates
- [x] Multi-architecture support (amd64, arm64)

## Disclaimer

- This repo is not open for issues related to difftastic. This repo is only for _unofficial_ Debian packaging.
