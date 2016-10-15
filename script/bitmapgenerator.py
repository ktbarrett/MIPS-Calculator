from math import ceil

def generateBitMap(n):
    n = [bool(x) for x in n]
    n.extend([False]*int(8*ceil(len(n)/8.0) - len(n)))
    chunked = (n[8*i:8*(i+1)] for i in range(len(n)//8))
    bytearray = [sum([2**i for i, x in enumerate(n8) if x]) for n8 in chunked]
    return bytearray

print "_isdigit_bm: .byte " + " ".join(hex(x) for x in generateBitMap(map(lambda x: chr(x).isdigit(), range(128))))
print "_isspace_bm: .byte " + " ".join(hex(x) for x in generateBitMap(map(lambda x: chr(x).isspace(), range(128))))
print "_isalpha_bm: .byte " + " ".join(hex(x) for x in generateBitMap(map(lambda x: chr(x).isalpha(), range(128))))
print "_isalnum_bm: .byte " + " ".join(hex(x) for x in generateBitMap(map(lambda x: chr(x).isalnum(), range(128))))

