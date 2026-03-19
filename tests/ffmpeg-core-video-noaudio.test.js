const createFFmpegCore = require("../packages/core-video");
const fs = require("fs");
const path = require("path");

const EXAMPLE_DIR = path.join(__dirname, "../concat-example");

(async () => {
  const core = await createFFmpegCore();
  core.FS.mkdir("frames");
  const frames = fs.readdirSync(path.join(EXAMPLE_DIR, "frames")).filter(f => f.endsWith(".png")).sort();
  for (const f of frames) {
    core.FS.writeFile("frames/" + f, new Uint8Array(fs.readFileSync(path.join(EXAMPLE_DIR, "frames", f))));
  }
  core.FS.writeFile("concat.txt", fs.readFileSync(path.join(EXAMPLE_DIR, "concat.txt"), "utf8"));
  core.setLogger(() => {});

  const ret = core.exec("-f", "concat", "-safe", "0", "-i", "concat.txt", "-c:v", "mpeg4", "-pix_fmt", "yuv420p", "out_noaudio.mp4");
  if (ret !== 0) { console.error("FFmpeg failed:", ret); process.exit(1); }

  const out = core.FS.readFile("out_noaudio.mp4");
  console.log(`video-only:  ${out.length} bytes (${(out.length/1024/1024).toFixed(2)} MB)`);
  console.log(`with audio:  ${fs.statSync(path.join(EXAMPLE_DIR, "output.mp4")).size} bytes (${(fs.statSync(path.join(EXAMPLE_DIR, "output.mp4")).size/1024/1024).toFixed(2)} MB)`);
  process.exit(0);
})().catch(e => { console.error(e); process.exit(1); });
