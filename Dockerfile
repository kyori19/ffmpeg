FROM kyori/aom-alpine:latest AS aom
FROM kyori/libass-alpine:latest AS libass

FROM alpine:3.13.2

ARG version
ENV VERSION=${version} \
  \
  DEV_PKGS="autoconf automake binutils cmake curl diffutils gcc git g++ libtool make nasm openssl-dev pkgconfig" \
  PREFIX=/tmp/output \
  PKG_CONFIG_PATH=/tmp/output/lib/pkgconfig:/tmp/output/lib64/pkgconfig

COPY --from=aom /output/ /tmp/output/
COPY --from=libass /output/ /tmp/output/

RUN apk add --no-cache ${DEV_PKGS} libgomp libstdc++ &&\
  # AviSynthPlus
  git clone --recurse-submodules https://github.com/AviSynth/AviSynthPlus.git /tmp/AviSynthPlus -b v3.7.0 --depth 1 &&\
  mkdir /tmp/AviSynthPlus/avisynth-build &&\
  cd /tmp/AviSynthPlus/avisynth-build &&\
  cmake ../ -DCMAKE_INSTALL_PREFIX=${PREFIX} &&\
  make -j$(nproc) install &&\
  # fdk-aac
  git clone https://github.com/mstorsjo/fdk-aac.git /tmp/fdk-aac -b v2.0.1 --depth 1 &&\
  cd /tmp/fdk-aac &&\
  autoreconf -fiv &&\
  ./configure --prefix=${PREFIX} --enable-shared --datadir=/tmp/fdk-aac &&\
  make -j$(nproc) install &&\
  # kvazaar
  git clone --recurse-submodules https://github.com/ultravideo/kvazaar.git /tmp/kvazaar -b v2.0.0 --depth 1 &&\
  cd /tmp/kvazaar &&\
  ./autogen.sh &&\
  ./configure --prefix=${PREFIX} --disable-static --enable-shared &&\
  make -j$(nproc) install &&\
  # libmp3lame
  mkdir -p /tmp/lame &&\
  cd /tmp/lame &&\
  curl -sL https://versaweb.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz | tar -zx --strip-components=1 &&\
  ./configure --prefix=${PREFIX} --bindir=${PREFIX}/bin --enable-shared --enable-nasm --disable-frontend &&\
  make -j$(nproc) install &&\
  # opencore-amr
  mkdir -p /tmp/opencore-amr &&\
  cd /tmp/opencore-amr &&\
  curl -sL https://versaweb.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-0.1.5.tar.gz | tar -zx --strip-components=1 &&\
  ./configure --prefix=${PREFIX} --enable-shared &&\
  make -j$(nproc) install &&\
  # openjpeg
  git clone https://github.com/uclouvain/openjpeg.git /tmp/openjpeg -b v2.4.0 --depth 1 &&\
  mkdir \p /tmp/openjpeg/build &&\
  cd /tmp/openjpeg/build &&\
  cmake ../ -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_BUILD_TYPE=Release &&\
  make -j$(nproc) install &&\
  # opus
  git clone https://gitlab.xiph.org/xiph/opus.git /tmp/opus -b v1.3.1 --depth 1 &&\
  cd /tmp/opus &&\
  ./autogen.sh &&\
  ./configure --prefix=${PREFIX} --enable-shared &&\
  make -j$(nproc) install &&\
  # Theora, vorbis -> libogg
  mkdir -p /tmp/libogg &&\
  cd /tmp/libogg &&\
  curl -sL https://downloads.xiph.org/releases/ogg/libogg-1.3.4.tar.gz | tar -zx --strip-components=1 &&\
  ./configure --prefix=${PREFIX} --enable-shared &&\
  make -j$(nproc) install &&\
  # Theora
  mkdir -p /tmp/theora &&\
  cd /tmp/theora &&\
  curl -sL https://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.gz | tar -zx --strip-components=1 &&\
  ./configure --prefix=${PREFIX} --with-ogg=${PREFIX} --enable-shared &&\
  make -j$(nproc) install &&\
  # vid.stab
  git clone https://github.com/georgmartius/vid.stab.git /tmp/vid.stab -b v1.1.0 --depth 1 &&\
  cd /tmp/vid.stab &&\
  cmake . -DCMAKE_INSTALL_PREFIX=${PREFIX} -DBUILD_SHARED_LIBS=OFF &&\
  make -j$(nproc) install &&\
  # vorbis
  mkdir -p /tmp/vorbis &&\
  cd /tmp/vorbis &&\
  curl -sL https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.gz | tar -zx --strip-components=1 &&\
  ./configure --prefix=${PREFIX} --with-ogg=${PREFIX} --enable-shared &&\
  make -j$(nproc) install &&\
  # libvpx
  git clone https://chromium.googlesource.com/webm/libvpx /tmp/libvpx -b v1.9.0 --depth 1 &&\
  cd /tmp/libvpx &&\
  ./configure --prefix=${PREFIX} --enable-vp8 --enable-vp9 --enable-vp9-highbitdepth --enable-pic --enable-shared --disable-debug --disable-examples --disable-docs --disable-install-bins &&\
  make -j$(nproc) install &&\
  # x264
  git clone https://code.videolan.org/videolan/x264.git /tmp/x264 -b stable --depth 1 &&\
  cd /tmp/x264 &&\
  ./configure --prefix="${PREFIX}" --enable-shared --enable-pic --disable-cli &&\
  make -j$(nproc) install &&\
  # x265
  mkdir -p /tmp/x265 &&\
  cd /tmp/x265 &&\
  curl -sL http://download.videolan.org/pub/videolan/x265/x265_3.2.1.tar.gz | tar -zx --strip-components=1 &&\
  cd /tmp/x265/build/linux &&\
  cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} -DENABLE_CLI=OFF ../../source &&\
  make -j$(nproc) install &&\
  # xvid
  mkdir -p /tmp/xvid &&\
  cd /tmp/xvid &&\
  curl -sL https://downloads.xvid.com/downloads/xvidcore-1.3.7.tar.gz | tar -zx --strip-components=1 &&\
  cd /tmp/xvid/build/generic &&\
  ./configure --prefix=${PREFIX} --bindir=${PREFIX}/bin &&\
  make -j$(nproc) &&\
  make install &&\
  # FFmpeg
  mkdir -p /tmp/ffmpeg &&\
  cd /tmp/ffmpeg &&\
  curl -sL https://ffmpeg.org/releases/ffmpeg-${VERSION}.tar.bz2 | tar -jx --strip-components=1 &&\
  ./configure \
    --disable-debug \
    --disable-doc \
    --disable-ffplay \
    --enable-libaom \
    --enable-avisynth \
    --enable-avresample \
    --enable-gpl \
    --enable-libass \
    --enable-libfdk_aac \
    --enable-libfreetype \
    --enable-libkvazaar \
    --enable-libmp3lame \
    --enable-libopencore-amrnb \
    --enable-libopencore-amrwb \
    --enable-libopenjpeg \
    --enable-libopus \
    --enable-libtheora \
    --enable-libvidstab \
    --enable-libvorbis \
    --enable-libvpx \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libxvid \
    --enable-nonfree \
    --enable-openssl \
    --enable-postproc \
    --enable-shared \
    --enable-small \
    --enable-version3 \
    --extra-cflags="-I${PREFIX}/include" \
    --extra-ldflags="-L${PREFIX}/lib" \
    --extra-libs=-ldl \
    --extra-libs=-lpthread \
    --prefix=${PREFIX} &&\
  make -j$(nproc) install &&\
  make distclean &&\
  mkdir -p /output/lib &&\
  LD_LIBRARY_PATH=${PREFIX}/lib:${PREFIX}/lib64 ldd ${PREFIX}/bin/ffmpeg | cut -d ' ' -f 3 | strings | xargs -I R cp R /output/lib &&\
  for lib in /output/lib/*; do strip --strip-all $lib; done &&\
  cp -r ${PREFIX}/bin /output/bin &&\
  cp -r ${PREFIX}/share /output/share &&\
  cp -r ${PREFIX}/include /output/include &&\
  rm -rf /tmp/* &&\
  apk del ${DEV_PKGS} &&\
  LD_LIBRARY_PATH=/output/lib:/output/lib64 /output/bin/ffmpeg -buildconf
