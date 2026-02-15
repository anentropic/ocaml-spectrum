#!/usr/bin/env python3
"""
Generate 1x1 PNG color swatches from hex color codes.
"""

import argparse
import struct
import sys
import zlib
from pathlib import Path
from typing import NamedTuple


class Color(NamedTuple):
    r: int
    g: int
    b: int


def parse_color(hex_color: str) -> Color:
    """
    Parse a hex color code into an RGB Color tuple.
    
    Args:
        hex_color: Color in #RRGGBB or RRGGBB format
        
    Returns:
        Color named tuple with r, g, b values
    """
    hex_color = hex_color.lstrip('#')
    if len(hex_color) != 6:
        raise ValueError(f"Invalid hex color: #{hex_color}")
    
    r = int(hex_color[0:2], 16)
    g = int(hex_color[2:4], 16)
    b = int(hex_color[4:6], 16)
    
    return Color(r, g, b)


def create_png(color: Color) -> bytes:
    """
    Create a 1x1 PNG file from a hex color code.
    
    Args:
        color: Color named tuple with r, g, b values
        
    Returns:
        PNG file data as bytes
    """
    
    # PNG signature
    png_header = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk (image header)
    width = 1
    height = 1
    bit_depth = 8
    color_type = 2  # Truecolor (RGB)
    compression_method = 0
    filter_method = 0
    interlace_method = 0
    
    ihdr_data = struct.pack(
        '>IIBBBBB',
        width, height, bit_depth, color_type,
        compression_method, filter_method, interlace_method
    )
    ihdr_chunk = _make_chunk(b'IHDR', ihdr_data)
    
    # IDAT chunk (image data)
    # For 1x1 RGB: one filter byte (0 = no filter) + 3 bytes (R, G, B)
    raw_data = b'\x00' + struct.pack('BBB', color.r, color.g, color.b)
    compressed_data = zlib.compress(raw_data)
    idat_chunk = _make_chunk(b'IDAT', compressed_data)
    
    # IEND chunk (image end, empty)
    iend_chunk = _make_chunk(b'IEND', b'')
    
    return png_header + ihdr_chunk + idat_chunk + iend_chunk


def _make_chunk(chunk_type: bytes, data: bytes) -> bytes:
    """
    Create a PNG chunk with proper length and CRC.
    
    Args:
        chunk_type: 4-byte chunk type identifier
        data: Chunk data
        
    Returns:
        Complete chunk with length, type, data, and CRC
    """
    chunk_len = struct.pack('>I', len(data))
    chunk_data = chunk_type + data
    crc = zlib.crc32(chunk_data) & 0xffffffff
    chunk_crc = struct.pack('>I', crc)
    return chunk_len + chunk_data + chunk_crc


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate a 1x1 PNG color swatch from a hex color code."
    )
    parser.add_argument(
        "color",
        help="Hex color code (e.g. #ff0000 or ff0000)"
    )
    parser.add_argument(
        "output",
        help="Output PNG filename (e.g. red.png)"
    )
    
    args = parser.parse_args()
    
    try:
        png_data = create_png(parse_color(args.color))
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    
    output_path = Path(__file__).parent / args.output
    output_path.write_bytes(png_data)
    print(f"Generated {output_path.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
