#!/bin/bash
# `-o <OUTPUT_FILE_NAME>` must be provided when using this build script.
# ex:
#     bash ffmpeg-wasm.sh -o ffmpeg.js

set -euo pipefail

EXPORT_NAME="createFFmpegCore"

CONF_FLAGS=(
  -I.
  -I./src/fftools
  -I$INSTALL_DIR/include
  -L$INSTALL_DIR/lib
  -Llibavcodec
  -Llibavfilter
  -Llibavformat
  -Llibavutil
  -Llibswresample
  -lavcodec
  -lavfilter
  -lavformat
  -lavutil
  -lswresample
  -Wno-deprecated-declarations
  $LDFLAGS
  -sWASM_BIGINT                            # enable big int support
  -sUSE_SDL=2                              # use emscripten SDL2 lib port
  -sMODULARIZE                             # modularized to use as a library
  ${FFMPEG_MT:+ -sINITIAL_MEMORY=1024MB}   # ALLOW_MEMORY_GROWTH is not recommended when using threads, thus we use a large initial memory
  ${FFMPEG_MT:+ -sPTHREAD_POOL_SIZE=32}    # use 32 threads
  ${FFMPEG_ST:+ -sINITIAL_MEMORY=32MB -sALLOW_MEMORY_GROWTH} # Use just enough memory as memory usage can grow
  -sEXPORT_NAME="$EXPORT_NAME"             # required in browser env, so that user can access this module from window object
  -sEXPORTED_FUNCTIONS=$(node src/bind/ffmpeg/export.js) # exported functions
  -sEXPORTED_RUNTIME_METHODS=$(node src/bind/ffmpeg/export-runtime.js) # exported built-in functions
  -lworkerfs.js
  --pre-js src/bind/ffmpeg/bind.js        # extra bindings, contains most of the ffmpeg.wasm javascript code
  # ffmpeg source code
  src/fftools/cmdutils.c
  src/fftools/ffmpeg.c
  src/fftools/ffmpeg_filter.c
  src/fftools/ffmpeg_hw.c
  src/fftools/ffmpeg_mux.c
  src/fftools/ffmpeg_opt.c
  src/fftools/opt_common.c
)

# Target-specific library linking
if [ "${FFMPEG_TARGET:-mp3}" = "video" ]; then
  # video target: libswscale (FFmpeg-internal) + zlib (PNG decoder) + x264 (H.264 encoder)
  CONF_FLAGS+=(-Llibswscale -lswscale -lx264 -lz)
elif [ "${FFMPEG_TARGET:-mp3}" = "m4b" ]; then
  # m4b target: no external libs needed (mp3 decoder and aac encoder are built into FFmpeg)
  true
else
  # mp3 target: link external libmp3lame
  CONF_FLAGS+=(-lmp3lame)
fi

emcc "${CONF_FLAGS[@]}" $@
