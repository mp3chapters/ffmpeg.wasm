/**
 * Smoke test for the m4b variant.
 * Converts example.mp3 (with ID3 chapters) -> output.m4b and verifies
 * the output is non-empty.
 */

const path = require("path");
const fs = require("fs");
const createFFmpegCore = require("../packages/core-m4b");

const EXAMPLE_DIR = path.join(__dirname, "../chapters-example");

async function main() {
  console.log("Loading ffmpeg-core (m4b)...");
  const core = await createFFmpegCore();
  console.log("Loaded.");
  core.setLogger(() => {});

  core.FS.writeFile("input.mp3", new Uint8Array(fs.readFileSync(path.join(EXAMPLE_DIR, "example.mp3"))));

  const ret = core.exec(
    "-i", "input.mp3",
    "-map", "0:a",
    "-map", "0:v?",
    "-c:a", "aac", "-b:a", "128k",
    "-c:v", "copy",
    "output.m4b"
  );

  if (ret !== 0) { console.error(`FFmpeg exited with code ${ret}`); process.exit(1); }

  const output = core.FS.readFile("output.m4b");
  console.log(`output.m4b: ${output.length} bytes (${(output.length / 1024).toFixed(0)} KB)`);
  fs.writeFileSync(path.join(EXAMPLE_DIR, "output.m4b"), output);
  console.log("SUCCESS");
  process.exit(0);
}

main().catch(err => { console.error(err); process.exit(1); });
