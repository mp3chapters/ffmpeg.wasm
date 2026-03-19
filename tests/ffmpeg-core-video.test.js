/**
 * Smoke test for the video build target.
 * Reads PNG frames + audio.mp3 from concat-example/, runs the frames-to-video
 * FFmpeg command, and verifies a non-empty MP4 is produced.
 */

const path = require("path");
const fs = require("fs");
const createFFmpegCore = require("../packages/core-video");

const EXAMPLE_DIR = path.join(__dirname, "../concat-example");
const FRAMES_DIR = path.join(EXAMPLE_DIR, "frames");

async function main() {
  console.log("Loading ffmpeg-core (video)...");
  const core = await createFFmpegCore();
  console.log("Loaded.");

  // Write PNG frames into the WASM virtual filesystem
  const frameFiles = fs.readdirSync(FRAMES_DIR).filter(f => f.endsWith(".png")).sort();
  core.FS.mkdir("frames");
  for (const f of frameFiles) {
    const data = fs.readFileSync(path.join(FRAMES_DIR, f));
    core.FS.writeFile(`frames/${f}`, new Uint8Array(data));
    console.log(`  wrote frames/${f} (${data.length} bytes)`);
  }

  // Write concat.txt
  const concatTxt = fs.readFileSync(path.join(EXAMPLE_DIR, "concat.txt"), "utf8");
  core.FS.writeFile("concat.txt", concatTxt);
  console.log("  wrote concat.txt");

  // Write audio.mp3
  const audio = fs.readFileSync(path.join(EXAMPLE_DIR, "audio.mp3"));
  core.FS.writeFile("audio.mp3", new Uint8Array(audio));
  console.log(`  wrote audio.mp3 (${audio.length} bytes)`);

  // Stream ffmpeg logs to stdout in real time
  core.setLogger(({ message }) => console.log(message));

  // Run the command: concat frames -> mpeg4 video, copy/encode mp3 -> aac, combine into mp4
  console.log("\nRunning ffmpeg command...");
  const ret = core.exec(
    "-f", "concat", "-safe", "0", "-i", "concat.txt",
    "-i", "audio.mp3",
    "-vf", "fps=1,format=yuv420p",  // 1fps slideshow; yuv420p required by libx264
    "-c:v", "libx264", "-crf", "28",
    "-c:a", "aac", "-b:a", "128k",
    "-shortest",
    "output.mp4"
  );

  if (ret !== 0) {
    console.error(`\nFFmpeg exited with code ${ret}`);
    process.exit(1);
  }

  // Verify output
  const output = core.FS.readFile("output.mp4");
  console.log(`\nOutput: output.mp4 (${output.length} bytes)`);
  if (output.length === 0) {
    console.error("ERROR: output.mp4 is empty");
    process.exit(1);
  }

  // Save locally for manual inspection
  const outPath = path.join(EXAMPLE_DIR, "output.mp4");
  fs.writeFileSync(outPath, output);
  console.log(`Saved to ${outPath}`);
  console.log("\nSUCCESS");
  process.exit(0);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
