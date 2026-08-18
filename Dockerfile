ARG DEBIAN_DIST=bookworm
FROM debian:$DEBIAN_DIST

ARG DEBIAN_DIST
ARG difftastic_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG PACKAGE_DEPENDS
ARG DIFFT_RELEASE

RUN mkdir -p /output/usr/bin
RUN mkdir -p /output/usr/share/doc/difftastic
RUN mkdir -p /output/usr/share/man/man1
RUN mkdir -p /output/DEBIAN

# Upstream ships a flat tarball containing only the difft binary, and no shell
# completions (difft has no completion generator). The man page difft.1 comes
# from the upstream source tree at the same tag and is fetched by build_*.sh.
COPY ${DIFFT_RELEASE}/difft /output/usr/bin/
COPY ${DIFFT_RELEASE}/difft.1 /output/usr/share/man/man1/difft.1
RUN chmod 755 /output/usr/bin/difft
RUN chmod 644 /output/usr/share/man/man1/difft.1
RUN gzip -9n /output/usr/share/man/man1/*.1
COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
RUN chmod 755 /output/DEBIAN/postinst
COPY output/copyright /output/usr/share/doc/difftastic/
COPY output/changelog.Debian /output/usr/share/doc/difftastic/
COPY output/README.md /output/usr/share/doc/difftastic/

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/difftastic/changelog.Debian
RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/difftastic/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/difftastic_VERSION/$difftastic_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control
RUN sed -i "s/PACKAGE_DEPENDS/$PACKAGE_DEPENDS/" /output/DEBIAN/control

# difft is a large binary (~120 MB, tree-sitter parsers for 30+ languages),
# so an accurate Installed-Size matters for apt's disk-space prompt.
RUN INSTALLED_SIZE="$(du -k -s --exclude=DEBIAN /output | cut -f1)" \
    && sed -i "s/INSTALLED_SIZE/$INSTALLED_SIZE/" /output/DEBIAN/control

RUN dpkg-deb --build /output /difftastic_${FULL_VERSION}.deb
