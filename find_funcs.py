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

func_at = []

# offset of four
for i, chunk in enumerate(chunks):
    PC = i*4
    # entry a1, XX
    if (chunk[0] == 0x36) and ((chunk[1] & 0xf) == 0x1):
        func_at.append(PC)

func_end = func_at[1:] + [ len(xs) ]
max_func_size = list(map(lambda l: l[0] - l[1], zip(func_end, func_at)))

func_sizes = []
for at, max_size in zip(func_at, max_func_size):
    func = xs[at:at+max_size]
    while func[-1] == 0:
        func.pop(-1)
    size = len(func)
    func_sizes.append(size)

for at, size in zip(func_at, func_sizes):
    print(f"{hex(at)} FUNC_{hex(at)} {size}")
