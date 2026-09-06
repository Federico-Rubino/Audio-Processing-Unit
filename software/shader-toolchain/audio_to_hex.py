#!/usr/bin/env python3
"""Decodes an audio file (mp3, wav, etc) to mono 16-bit PCM at 48kHz, rounds
its length to the nearest whole number of 256-sample grains (padding with
zeros or truncating), and writes it as a-ram-ready .hex: one 32-bit word per
line, two 16-bit samples packed per word -- low 16 bits = even sample, high
16 bits = odd sample, matching how audio_in_unit.vhd/audio_out_unit.vhd pack
a-ram cells.

Requires the project venv (decoding needs ffmpeg, not available otherwise):
    python3 -m venv .venv
    .venv/bin/pip install imageio-ffmpeg numpy
    .venv/bin/python3 audio_to_hex.py path/to/file.mp3

Usage:
    python3 audio_to_hex.py path/to/file.mp3 [-o path/to/file.hex]
"""

import argparse
import subprocess
import sys
from pathlib import Path

import numpy as np
import imageio_ffmpeg

SAMPLE_RATE = 48000
GRAIN_SAMPLES = 256


def decode_to_pcm(source_path, sample_rate):
    """Decodes any input audio format to mono, signed 16-bit little-endian PCM at `sample_rate`."""
    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
    cmd = [
        ffmpeg_exe, "-v", "error", "-i", str(source_path),
        "-f", "s16le", "-acodec", "pcm_s16le",
        "-ac", "1", "-ar", str(sample_rate),
        "-",
    ]
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        raise RuntimeError(f"ffmpeg failed: {proc.stderr.decode(errors='replace')}")
    return np.frombuffer(proc.stdout, dtype="<i2")


def round_to_grain(samples, grain_samples=GRAIN_SAMPLES):
    """Pads with zeros or truncates to the nearest whole multiple of grain_samples."""
    n = len(samples)
    num_grains = max(1, round(n / grain_samples))
    target = num_grains * grain_samples
    if target > n:
        samples = np.concatenate([samples, np.zeros(target - n, dtype=np.int16)])
    else:
        samples = samples[:target]
    return samples, num_grains


def pack_words(samples):
    """Packs 2 consecutive int16 samples per 32-bit word: low 16 bits = even sample, high 16 bits = odd."""
    if len(samples) % 2 != 0:
        samples = np.concatenate([samples, np.zeros(1, dtype=np.int16)])
    even = samples[0::2].astype(np.uint32) & 0xFFFF
    odd = samples[1::2].astype(np.uint32) & 0xFFFF
    return (odd << 16) | even


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source", help="Input audio file (mp3, wav, etc)")
    parser.add_argument("-o", "--output", help="Output .hex path (default: alongside source, .hex extension)")
    parser.add_argument("--sample-rate", type=int, default=SAMPLE_RATE, help=f"default {SAMPLE_RATE}")
    args = parser.parse_args()

    source_path = Path(args.source)
    output_path = Path(args.output) if args.output else source_path.with_suffix(".hex")

    samples = decode_to_pcm(source_path, args.sample_rate)
    original_duration_s = len(samples) / args.sample_rate

    samples, num_grains = round_to_grain(samples)
    words = pack_words(samples)

    with open(output_path, "w") as f:
        for w in words:
            f.write(f"{w:08x}\n")

    rounded_duration_s = len(samples) / args.sample_rate
    print(f"[+] {source_path.name}: {original_duration_s:.3f}s decoded -> "
          f"{rounded_duration_s:.3f}s ({num_grains} grains x {GRAIN_SAMPLES} samples) "
          f"-> {len(words)} words written to {output_path}")


if __name__ == "__main__":
    main()
