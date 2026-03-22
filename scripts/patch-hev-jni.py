#!/usr/bin/env python3
"""
Ensure hev-socks5-tunnel Android.mk has -DANDROID flag.
hev-jni.c is already correct in the repo — no replacement needed.
"""
import os

mk_path = "android/app/src/main/jni/hev-socks5-tunnel/Android.mk"
try:
    mk = open(mk_path).read()
    if "-DANDROID" not in mk:
        mk = mk.replace(
            "LOCAL_CFLAGS += -DFD_SET_DEFINED -DSOCKLEN_T_DEFINED -DENABLE_LIBRARY",
            "LOCAL_CFLAGS += -DFD_SET_DEFINED -DSOCKLEN_T_DEFINED -DENABLE_LIBRARY -DANDROID",
        )
        open(mk_path, "w").write(mk)
        print("Patched Android.mk: added -DANDROID")
    else:
        print("Android.mk: -DANDROID already present")
except FileNotFoundError:
    print(f"WARNING: {mk_path} not found, skipping")

print("patch-hev-jni.py done")
