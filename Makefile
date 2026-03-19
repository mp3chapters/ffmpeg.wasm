all: dev

MT_FLAGS := -sUSE_PTHREADS -pthread

DEV_ARGS := --progress=plain

DEV_CFLAGS := --profiling
DEV_MT_CFLAGS := $(DEV_CFLAGS) $(MT_FLAGS)
PROD_CFLAGS := -O3 -msimd128
PROD_MT_CFLAGS := $(PROD_CFLAGS) $(MT_FLAGS)

clean:
	rm -rf ./packages/core$(PKG_SUFFIX)/dist

.PHONY: build
build:
	make clean PKG_SUFFIX="$(PKG_SUFFIX)"
	EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
	EXTRA_LDFLAGS="$(EXTRA_LDFLAGS)" \
	FFMPEG_ST="$(FFMPEG_ST)" \
	FFMPEG_MT="$(FFMPEG_MT)" \
	FFMPEG_TARGET="$(FFMPEG_TARGET)" \
		docker buildx build \
			--build-arg EXTRA_CFLAGS \
			--build-arg EXTRA_LDFLAGS \
			--build-arg FFMPEG_MT \
			--build-arg FFMPEG_ST \
			--build-arg FFMPEG_TARGET \
			-o ./packages/core$(PKG_SUFFIX) \
			$(EXTRA_ARGS) \
			.

# mp3 target: merge/concatenate MP3 files
build-st:
	make build \
		FFMPEG_ST=yes \
		FFMPEG_TARGET=mp3

build-mt:
	make build \
		PKG_SUFFIX=-mt \
		FFMPEG_MT=yes \
		FFMPEG_TARGET=mp3

dev:
	make build-st EXTRA_CFLAGS="$(DEV_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

dev-mt:
	make build-mt EXTRA_CFLAGS="$(DEV_MT_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

prd:
	make build-st EXTRA_CFLAGS="$(PROD_CFLAGS)"

prd-mt:
	make build-mt EXTRA_CFLAGS="$(PROD_MT_CFLAGS)"

# m4b target: MP3 with chapters/metadata -> M4A/M4B
build-m4b-st:
	make build \
		FFMPEG_ST=yes \
		FFMPEG_TARGET=m4b \
		PKG_SUFFIX=-m4b

dev-m4b:
	make build-m4b-st EXTRA_CFLAGS="$(DEV_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

prd-m4b:
	make build-m4b-st EXTRA_CFLAGS="$(PROD_CFLAGS)"

# video target: PNG image frames + MP3 audio -> MP4 video
build-video-st:
	make build \
		FFMPEG_ST=yes \
		FFMPEG_TARGET=video \
		PKG_SUFFIX=-video

build-video-mt:
	make build \
		FFMPEG_MT=yes \
		FFMPEG_TARGET=video \
		PKG_SUFFIX=-video-mt

dev-video:
	make build-video-st EXTRA_CFLAGS="$(DEV_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

dev-video-mt:
	make build-video-mt EXTRA_CFLAGS="$(DEV_MT_CFLAGS)" EXTRA_ARGS="$(DEV_ARGS)"

prd-video:
	make build-video-st EXTRA_CFLAGS="$(PROD_CFLAGS)"

prd-video-mt:
	make build-video-mt EXTRA_CFLAGS="$(PROD_MT_CFLAGS)"
