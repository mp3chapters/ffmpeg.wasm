#!/bin/bash

set -euo pipefail

CONF_FLAGS=(
  --disable-all

  --enable-protocol=file
  --enable-avcodec
  --enable-avformat
  --enable-avfilter
  --enable-libmp3lame
  --enable-swresample

  --enable-demuxer=mp3
  --enable-demuxer=concat
  --enable-decoder=mp3*
  --enable-encoder=libmp3lame
  --enable-parser=mpegaudio
  --enable-muxer=mp3

  --enable-filter=null,anull
  --enable-filter=atrim
  # configure_output_audio_filter https://github.com/FFmpeg/FFmpeg/blob/45ab5307a6e8c04b4ea91b1e1ccf71ba38195f7c/fftools/ffmpeg_filter.c#L522
  --enable-filter=abuffersink,aformat
  # configure_input_audio_filter https://github.com/FFmpeg/FFmpeg/blob/45ab5307a6e8c04b4ea91b1e1ccf71ba38195f7c/fftools/ffmpeg_filter.c#L835
  --enable-filter=abuffer
  # negotiate_audio https://github.com/FFmpeg/FFmpeg/blob/41a558fea06cc0a23b8d2d0dfb03ef6a25cf5100/libavfilter/formats.c#L336
  --enable-filter=amix,aresample

  --target-os=none              # disable target specific configs
  --arch=x86_32                 # use x86_32 arch
  --enable-cross-compile        # use cross compile configs
  --disable-asm                 # disable asm
  --disable-stripping           # disable stripping as it won't work
  --disable-programs            # disable ffmpeg, ffprobe and ffplay build
  --disable-doc                 # disable doc build
  --disable-debug               # disable debug mode
  --disable-runtime-cpudetect   # disable cpu detection
  --disable-autodetect          # disable env auto detect

  # assign toolchains and extra flags
  --nm=emnm
  --ar=emar
  --ranlib=emranlib
  --cc=emcc
  --cxx=em++
  --objcc=emcc
  --dep-cc=emcc
  --extra-cflags="$CFLAGS"
  --extra-cxxflags="$CXXFLAGS"

  # disable thread when FFMPEG_ST is NOT defined
  ${FFMPEG_ST:+ --disable-pthreads --disable-w32threads --disable-os2threads}
)

emconfigure ./configure "${CONF_FLAGS[@]}" $@
emmake make -j
