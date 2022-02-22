#!/usr/bin/env python3

import sys

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} BINARY", file=sys.stderr)
    sys.exit(1)

with open(sys.argv[1], 'rb') as fp:
    fw = fp.read()

xs = list(fw)
i = 0
chunks = []

while i < len(xs):
    chunks.append(xs[i:i+4])
    i += 4

# offset of four
for i, chunk in enumerate(chunks):
    PC = i*4
    # entry a1, XX
    if (chunk[0] == 0x36) and ((chunk[1] & 0xf) == 0x1):
        print(f"{hex(PC)} FUNC_{hex(PC)}")
