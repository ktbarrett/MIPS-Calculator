from itertools import product
from math import ceil

# first index is first value
validityMatrix = [
    #   END     NUM     VAR     ADD     SUB     MUL     DIV     ASSIGN  NEG     L PAREN R PAREN
    [   0,      0,      0,      0,      0,      0,      0,      0,      0,      0,      0], # END
    [   1,      0,      0,      1,      1,      1,      1,      0,      0,      0,      1], # NUM
    [   1,      0,      0,      1,      1,      1,      1,      1,      0,      0,      1], # VAR
    [   0,      1,      1,      1,      1,      0,      0,      0,      1,      1,      0], # ADD
    [   0,      1,      1,      1,      1,      0,      0,      0,      1,      1,      0], # SUB
    [   0,      1,      1,      1,      1,      0,      0,      0,      1,      1,      0], # MUL
    [   0,      1,      1,      1,      1,      0,      0,      0,      1,      1,      0], # DIV
    [   0,      1,      1,      1,      1,      0,      0,      0,      1,      1,      0], # ASSIGN
    [   0,      1,      1,      0,      0,      0,      0,      0,      0,      1,      0], # NEG
    [   0,      1,      1,      1,      1,      0,      0,      0,      1,      1,      0], # L PAREN
    [   1,      0,      0,      1,      1,      1,      1,      0,      0,      0,      1], # R PAREN
]
validityMatrix = list(map(bool, validityrow) for validityrow in validityMatrix)

### Print usable validity bit matrix ###
# flatten list
flattened = sum(validityMatrix, [])
# round up to next byte
bitarray = flattened+([False]*(int(ceil(len(flattened)/8.0)*8) - len(flattened)))
# chunk into bytes
bytes = [bitarray[8*i:8+8*i] for i in range(len(bitarray)//8)]
# turn into byte array
bytearray = [sum([2**i for i, x in enumerate(n8) if x]) for n8 in bytes]
# print label
print("_validity_matrix: .byte " + " ".join(hex(x) for x in bytearray))

names = ["\\0", "1", "a", "+", "-", "*", "/", "=", "-", "(", ")"]
good = []
for i in filter(lambda x: validityMatrix[x[0]][x[1]] and validityMatrix[x[1]][x[2]] and not 8 in x, product(range(len(validityMatrix)), repeat=3)):
    good.append(" ".join(map(lambda x: names[x], i)))
print(len(good))
print("\n".join(good))
