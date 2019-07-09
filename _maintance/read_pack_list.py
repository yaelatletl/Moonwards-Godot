#!/usr/bin/python
import sys
import struct

fname = sys.argv[1]
print("open %s" % fname)
pack = open(fname, 'rb')
pack.read(0x54) # Skip the empty padding

file_count = struct.unpack('<I', pack.read(4))[0]

name_len = struct.unpack('<I', pack.read(4))[0]

for i in range(file_count):
  name_len = struct.unpack('<I', pack.read(4))[0]
  name = pack.read(name_len)
  pack.read(32)
  print(name)