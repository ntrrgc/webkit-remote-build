#!/usr/bin/python3
import lzma
import os, sys
from collections import defaultdict, namedtuple

import itertools

import struct
from typing import Tuple

import zlib
from bitarray import bitarray
from heapq import heappush, heappop

#!/bin/python3
import re
import sys
import random

def huffCode(freq):
    """
    Given a dictionary mapping symbols to their frequency,
    return the Huffman code in the form of
    a dictionary mapping the symbols to bitarrays.
    """
    minheap = []
    for s in freq:
        heappush(minheap, PseudoTuple(freq[s], s))

    while len(minheap) > 1:
        childR = heappop(minheap)
        childL = heappop(minheap)
        parent = PseudoTuple(childL[0] + childR[0], childL, childR)
        heappush(minheap, parent)

    # Now minheap[0] is the root node of the Huffman tree

    def traverse(tree, prefix=bitarray()):
        if len(tree) == 2:
            result[tree[1]] = prefix
        else:
            for i in range(2):
                traverse(tree[i+1], prefix + bitarray([i]))

    result = {}
    traverse(minheap[0])
    return result


def decompose_bytes(bytes):
    return " ".join(f"{byte:08b}" for byte in bytes)


uncompressed_word_token = "¡¡!!UNCOMPRESSED¡¡!!".encode()

varint_lengths = [4, 8, 16, 32]
varint_max_number = [2**x - 1 for x in varint_lengths]
varint_prefixes = [bitarray('0'), bitarray('10'), bitarray('110'), bitarray('1110')]

def encode_varint(number: int) -> Tuple[bitarray, bitarray]:
    for length, max_number, prefix_bits in zip(varint_lengths, varint_max_number, varint_prefixes):
        if number <= max_number:
            break
    else:
        raise AssertionError(f"Too big number: {number}")

    number_bits = bitarray(bin(number)[2:].zfill(length))

    return prefix_bits, number_bits


class PseudoTuple:
    def __init__(self, frequency, *rest):
        self.frequency = frequency
        self.rest = rest

    def __lt__(self, other):
        return self.frequency < other.frequency

    def __getitem__(self, item):
        if item == 0:
            return self.frequency
        else:
            return self.rest[item - 1]

    def __len__(self):
        return 1 + len(self.rest)

def check_is_entire_file(words, file):
    file.seek(0)
    pos = 0
    for word in words:
        file_word = file.read(len(word))
        if file_word != word:
            raise AssertionError(f"Error at pos {pos}:\n{file_word}\n{word}")
        pos += len(word)
    if file.read() != b"":
        raise AssertionError("Word array does not extend to the entire file")

if __name__ == '__main__':
    # all_strings = re.findall(b"\0|[A-Z][a-z]+|[^A-Z]+", open(sys.argv[1], "rb").read())
    input_file = open(sys.argv[1], "rb")
    input_contents = input_file.read()

    all_words = []
    compressed_words = []
    uncompressed_words = []
    previous_match_end = 0

    for match in re.finditer(b"""[A-Za-z0-9.:\-+,_<>*&~/()[\]{}=\s]{4,}\0""", input_contents, re.DOTALL):
        if match.start() != previous_match_end:
            uncompressed_words.append(input_contents[previous_match_end:match.start()])
            all_words.append(input_contents[previous_match_end:match.start()])
        compressed_words.append(input_contents[match.start():match.end()])
        all_words.append(input_contents[match.start():match.end()])
        previous_match_end = match.end()
    if previous_match_end != len(input_contents):
        uncompressed_words.append(input_contents[previous_match_end:])
        all_words.append(input_contents[previous_match_end:])

    print(f"Count of all words: {len(all_words)}")
    print(f"Count of compressed words: {len(compressed_words)}")
    print(f"Size of all words: {sum(len(x) for x in all_words)}")
    print(f"Size of compressed words: {sum(len(x) for x in compressed_words)}")
    print(f"Compressed words sample:\n{random.sample(compressed_words, min(len(all_words), 50))}")
    print(f"Non compressed words sample:\n{random.sample(uncompressed_words, min(len(all_words), 50))}")
    print()

    print(f"Count of uncompressed words: {len(uncompressed_words)}")
    size_compressed_word_references = len(compressed_words) * 2
    print(f"Size of compressed word references: {size_compressed_word_references} ({100 * size_compressed_word_references / len(input_contents):.4}%)")
    print(f"Average size of uncompressed words: {sum(len(x) for x in uncompressed_words)/len(uncompressed_words)}")
    print(f"Total uncompressed length: {sum(len(x) for x in uncompressed_words)}")
    uncompressed_words_in_zlib = lzma.compress(b"".join(uncompressed_words))
    print(f"Total uncompressed length, compressed with zlib: {len(uncompressed_words_in_zlib)} "
          f"({100*len(uncompressed_words_in_zlib)/sum(len(x) for x in uncompressed_words):.3}% of uncompressed"
          f", {100*len(uncompressed_words_in_zlib)/len(input_contents):.3}% of file)")
    print()

    overhead_per_uncompressed_word = 4
    total_overhead = overhead_per_uncompressed_word * len(uncompressed_words)
    total_compressed_size = total_overhead + len(uncompressed_words_in_zlib) + size_compressed_word_references
    print(f"Total overhead uncompressed words: {total_overhead}")
    print(f"Total compressed size: {total_compressed_size}"
          f" ({100*total_compressed_size/len(input_contents):.2f}%)")
    print()

    distinct_uncompressed_words = set(uncompressed_words)
    print(f"Count of distinct uncompressed words: {len(distinct_uncompressed_words)} ({100*len(distinct_uncompressed_words) / len(uncompressed_words):.3}%)")
    print(f"Average size of distinct uncompressed words: {sum(len(x) for x in distinct_uncompressed_words)/len(distinct_uncompressed_words)}")
    print(f"Total distinct uncompressed length: {sum(len(x) for x in distinct_uncompressed_words)}")
    distinct_uncompressed_words_in_zlib = zlib.compress(b"".join(distinct_uncompressed_words), level=9)
    print(f"Total distinct uncompressed length, compressed with zlib: {len(distinct_uncompressed_words_in_zlib)}")
    print()

    check_is_entire_file(all_words, input_file)
    raise SystemExit(0)
    strings_with_count = {}
    compressed_words = set()

    for string in all_words:
        if string in strings_with_count:
            strings_with_count[string] += 1
            if strings_with_count[string] >= 2 and len(string) >= 5 \
                    or strings_with_count[string] >= 4:
                compressed_words.add(string)
        else:
            strings_with_count[string] = 1

    compressed_count = 0
    uncompressed_words = []
    uncompressed_size = 0
    for string in all_words:
        if string in compressed_words:
            compressed_count += 1
        else:
            uncompressed_words.append(string)
            uncompressed_size += len(string)

    huff_code = huffCode(dict(
        itertools.chain((
            (word, strings_with_count[word])
            for word in compressed_words
        ), [(uncompressed_word_token, len(uncompressed_words))])
    ))

    compressed_stream = bitarray(endian="little")

    for string in all_words:
        compressed_word = huff_code.get(string)
        if compressed_word is not None:
            compressed_stream.extend(compressed_word)
        else:
            compressed_stream.extend(huff_code[uncompressed_word_token])
            prefix_bits, length_bits = encode_varint(len(string))
            compressed_stream.extend(prefix_bits)
            compressed_stream.extend(length_bits)
            compressed_stream.frombytes(string)

    output_file = open("/tmp/output", "wb")

    stream_byte_size = compressed_stream.buffer_info()[1]
    stream_padding_bits = compressed_stream.buffer_info()[3]
    output_file.write(struct.pack(">QB", stream_byte_size, stream_padding_bits))
    compressed_stream.tofile(output_file)
    output_file.close()

    print(f"Compressed stream size: {stream_byte_size}")
    print(f"Dictionary entry count: {len(compressed_words)}")
    print(f"Size of dictionary: {sum(len(x) for x in compressed_words)}")
    print(f"Compressed count: {compressed_count}")
    print(f"Uncompressed size: {len(uncompressed_words)}")
    print(f"Compressed sample:\n{random.sample(compressed_words, 50)}")
    print(f"Uncompressed sample:\n{random.sample(uncompressed_words, 50)}")
    print(list(reversed(sorted((occur, len(string)) for (string, occur) in strings_with_count.items()))))