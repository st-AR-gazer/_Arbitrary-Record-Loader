import os
import ctypes
from ctypes import c_char_p, c_int64, CFUNCTYPE

def get_file_creation_time(filename: str) -> int:
    if not os.path.exists(filename):
        return -1

    creation_time = os.path.getctime(filename)
    return int(creation_time * 1e7)

prototype = CFUNCTYPE(c_int64, c_char_p)

c_get_file_creation_time = prototype(get_file_creation_time)

@prototype
def GetFileCreationTime(filename):
    return c_get_file_creation_time(filename)
