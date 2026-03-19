/**
 * Smoke test for JPEG frame support.
 * Uses two separate ffmpeg.wasm instances — one to convert a PNG to JPEG,
 * one to encode the JPEG slideshow — since the WASM module is single-use.
 */

const path = require("path");
const fs = require("fs");
const createFFmpegCore = require("../packages/core-video");

const EXAMPLE_DIR = path.join(__dirname, "../concat-example");
const FRAMES_DIR = path.join(EXAMPLE_DIR, "frames");

async function main() {
  // Step 1: convert one PNG -> JPEG using a dedicated module instance
  console.log("Step 1: converting PNG -> JPEG...");
  const conv = await createFFmpegCore();
  conv.setLogger(() => {});
  conv.FS.writeFile("frame_src.png", new Uint8Array(fs.readFileSync(path.join(FRAMES_DIR, "frame_01.png"))));
  const convRet = conv.exec("-i", "frame_src.png", "-q:v", "2", "frame.jpg");
  if (convRet !== 0) { console.error("PNG->JPEG conversion failed"); process.exit(1); }
  const jpgData = conv.FS.readFile("frame.jpg");
  console.log(`  frame_01.png -> frame.jpg (${jpgData.length} bytes)`);

  // Step 2: encode JPEG frames -> MP4 using a fresh module instance
  console.log("Step 2: encoding JPEG frames -> MP4...");
  const core = await createFFmpegCore();
  core.setLogger(() => {});

  core.FS.mkdir("frames");
  let concatTxt = "";
  for (let i = 1; i <= 10; i++) {
    const name = `frames/frame_${String(i).padStart(2, "0")}.jpg`;
    core.FS.writeFile(name, jpgData);
    concatTxt += `file '${name}'\nduration 180\n`;
  }
  concatTxt += `file 'frames/frame_10.jpg'\n`; // concat demuxer requires last file twice
  core.FS.writeFile("concat.txt", concatTxt);
  core.FS.writeFile("audio.mp3", new Uint8Array(fs.readFileSync(path.join(EXAMPLE_DIR, "audio.mp3"))));

  const ret = core.exec(
    "-f", "concat", "-safe", "0", "-i", "concat.txt",
    "-i", "audio.mp3",
    "-vf", "fps=1,format=yuv420p",
    "-c:v", "libx264", "-crf", "28",
    "-c:a", "aac", "-b:a", "128k",
    "-shortest",
    "output_jpg.mp4"
  );

  if (ret !== 0) { console.error(`FFmpeg exited with code ${ret}`); process.exit(1); }

  const output = core.FS.readFile("output_jpg.mp4");
  console.log(`  output_jpg.mp4 (${output.length} bytes)`);
  fs.writeFileSync(path.join(EXAMPLE_DIR, "output_jpg.mp4"), output);
  console.log("SUCCESS");
  process.exit(0);
}

main().catch(err => { console.error(err); process.exit(1); });
