#!/bin/bash

set -euo pipefail

# Flags common to both build targets
COMMON_FLAGS=(
  --disable-all

  --enable-protocol=file
  --enable-avcodec
  --enable-avformat
  --enable-avfilter
  --enable-swresample

  --enable-demuxer=concat

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

if [ "${FFMPEG_TARGET:-mp3}" = "m4b" ]; then
  # M4B target: MP3 with ID3 chapters/metadata -> M4A/M4B
  TARGET_FLAGS=(
    --enable-demuxer=mp3          # reads MP3 audio + ID3 chapters, metadata, cover art
    --enable-decoder=mp3*         # MP3 audio decoder
    --enable-parser=mpegaudio
    --enable-encoder=aac          # AAC audio encoder for M4A/M4B
    --enable-muxer=ipod           # FFmpeg's muxer for .m4a/.m4b (ipod format)
    --enable-muxer=mp4            # ipod muxer depends on mp4
    --enable-bsf=aac_adtstoasc    # required when muxing AAC into MP4/M4B
    --enable-decoder=mjpeg        # needed to identify JPEG cover art for stream copy
  )

elif [ "${FFMPEG_TARGET:-mp3}" = "video" ]; then
  # Video target: PNG image frames + MP3 audio -> MP4 video
  TARGET_FLAGS=(
    --enable-swscale              # pixel format conversion (RGB PNG -> YUV for video encoding)
    --enable-zlib                 # required by the PNG decoder

    --enable-demuxer=mp3          # for reading mp3 audio input
    --enable-demuxer=image2       # for reading PNG image files referenced by concat.txt
    --enable-decoder=mp3*
    --enable-decoder=png          # PNG image decoder (no external lib required)
    --enable-decoder=mjpeg        # JPEG image decoder (no external lib required)
    --enable-parser=mpegaudio
    --enable-libx264              # H.264 video encoder
    --enable-encoder=libx264      # (requires --enable-gpl passed from Dockerfile)
    --enable-muxer=mp4            # MP4 container output
    --enable-encoder=aac          # AAC audio encoder for MP4 (no external lib required)
    --enable-bsf=aac_adtstoasc    # required when muxing AAC audio into MP4

    # video filters
    --enable-filter=buffer        # video source filter (equivalent of abuffer for audio)
    --enable-filter=buffersink    # video sink filter
    --enable-filter=format        # pixel format conversion (equivalent of aformat for audio)
    --enable-filter=scale         # video scaling
    --enable-filter=fps           # frame rate control
  )
else
  # MP3 target: merge/concatenate MP3 files
  TARGET_FLAGS=(
    --enable-libmp3lame
    --enable-demuxer=mp3
    --enable-decoder=mp3*
    --enable-encoder=libmp3lame
    --enable-parser=mpegaudio
    --enable-muxer=mp3
  )
fi

CONF_FLAGS=("${COMMON_FLAGS[@]}" "${TARGET_FLAGS[@]}")

emconfigure ./configure "${CONF_FLAGS[@]}" $@
emmake make -j
