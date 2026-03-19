This is a fork of https://github.com/ffmpegwasm/ffmpeg.wasm, with the Dockerfile and build scripts trimmed to only include the libraries needed for two specific use cases. This keeps the WASM bundles small.

## Variants

### `core` -- MP3 merge (1.3 MB WASM)

Concatenates/merges multiple MP3 files into one.

```js
const core = await createFFmpegCore();
core.FS.writeFile("concat.txt", "file 'a.mp3'\nfile 'b.mp3'\n");
core.FS.writeFile("a.mp3", new Uint8Array(/* ... */));
core.FS.writeFile("b.mp3", new Uint8Array(/* ... */));
core.exec("-f", "concat", "-safe", "0", "-i", "concat.txt", "-c", "copy", "out.mp3");
const result = core.FS.readFile("out.mp3");
```

### `core-m4b` -- MP3 with chapters to M4A/M4B (1.1 MB WASM)

Converts an MP3 file to M4A or M4B, preserving ID3 chapter markers, metadata (title, artist, etc.), and cover art.

```js
const core = await createFFmpegCore();
core.FS.writeFile("input.mp3", new Uint8Array(/* ... */));
core.exec(
  "-i", "input.mp3",
  "-map", "0:a", "-map", "0:v?",
  "-c:a", "aac", "-b:a", "128k",
  "-c:v", "copy",
  "output.m4b"  // or output.m4a
);
const result = core.FS.readFile("output.m4b");
```

`-map 0:v?` copies cover art if present, skips it if not. Chapters are preserved automatically.

### `core-video` -- Slideshow to MP4 (3.5 MB WASM)

Turns a sequence of PNG or JPEG image frames plus an MP3 audio track into an MP4 video.

The `concat.txt` uses FFmpeg's concat demuxer format, with each frame's display duration in seconds:

```
file 'frames/frame_01.png'
duration 5
file 'frames/frame_02.png'
duration 5
file 'frames/frame_02.png'
```

The last file must be listed twice (without a duration) -- this is a quirk of the concat demuxer.

```js
const core = await createFFmpegCore();
core.FS.mkdir("frames");
core.FS.writeFile("frames/frame_01.png", new Uint8Array(/* ... */));
// ... write remaining frames and audio.mp3 ...
core.FS.writeFile("concat.txt", concatTxtContents);
core.exec(
  "-f", "concat", "-safe", "0", "-i", "concat.txt",
  "-i", "audio.mp3",
  "-vf", "fps=1,format=yuv420p",
  "-c:v", "libx264", "-crf", "28",
  "-c:a", "aac", "-b:a", "128k",
  "-shortest",
  "output.mp4"
);
const result = core.FS.readFile("output.mp4");
```

Use `-vf fps=1` (or lower) for slideshow content -- at 25 fps, a 3-minute frame generates 4500 duplicate frames and encodes very slowly in WASM.

## Building

```bash
make prd        # mp3 merge    -> packages/core/dist/
make prd-m4b    # m4b convert  -> packages/core-m4b/dist/
make prd-video  # video        -> packages/core-video/dist/
```

Use `make dev` / `make dev-m4b` / `make dev-video` during development (adds `--profiling`, roughly 2x larger).
