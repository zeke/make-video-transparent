# make-video-transparent

A bash script that converts green screen video into transparent video files for use on the web.

It produces two output files from a single input:

- `.webm` (VP9 with alpha) for Chrome, Firefox, and Edge
- `.mov` (HEVC with alpha) for Safari

## Prerequisites

- [ffmpeg](https://ffmpeg.org/) with `libvpx-vp9` and `hevc_videotoolbox` (macOS) support
- Python 3 (for auto-detecting the green screen color)

On macOS with Homebrew:

```bash
brew install ffmpeg python
```

## Usage

```bash
./make-video-transparent.sh [options] <input>
```

## Options

| Flag                       | Description                                  | Default     |
| -------------------------- | -------------------------------------------- | ----------- |
| `-c, --color <hex>`        | Green screen color, e.g. `97c64c`            | auto-detect |
| `-s, --similarity <float>` | Color match tolerance, 0.0-1.0               | 0.12        |
| `-b, --blend <float>`      | Edge blend amount, 0.0-1.0                   | 0.05        |
| `-o, --output <dir>`       | Output directory                             | same as input |
| `-h, --help`               | Show help                                    |             |

## Examples

```bash
# Auto-detect green screen color from the video
./make-video-transparent.sh video.mp4

# Specify the green color manually
./make-video-transparent.sh -c 97c64c video.mp4

# Tweak similarity and blend for cleaner edges
./make-video-transparent.sh -s 0.15 -b 0.08 video.mp4

# Output to a specific directory
./make-video-transparent.sh -o ~/Desktop/output video.mp4
```

## Using the output in HTML

```html
<video autoplay loop muted playsinline>
  <source src="video.mov" type="video/mp4; codecs=hvc1">
  <source src="video.webm" type="video/webm">
</video>
```

Then change the background with CSS:

```css
video {
  background-color: rebeccapurple;
}
```

## Demo

See the live demo at https://zeke.github.io/make-video-transparent — it shows a transparent video with a color picker to dynamically change the background.

The `demo/` directory contains the source for this page. To test locally with your own videos, generate transparent videos with the script, drop them in `demo/`, and open `demo/index.html` in a browser.

## How it works

1. Auto-detects the green screen color by sampling a 200x200 pixel patch from the top-left corner of the first frame
2. Applies ffmpeg's `colorkey` filter to replace matching pixels with transparency
3. Encodes to WebM (VP9) and MOV (HEVC) with alpha channels

The color auto-detection assumes the top-left corner of the video is green screen. If your subject covers that area, pass the color manually with `-c`.
