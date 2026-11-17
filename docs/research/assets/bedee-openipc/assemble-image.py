#!/usr/bin/env python3
"""Offline reconstruction of the tested Bedee Hi3518EV200 NOR image.

No camera access, downloads, flashing, or subprocesses. Requires the exact
recorded OpenIPC assets and a caller-supplied, private 8 MiB stock backup.
Output contains private stock configuration: do not publish it.
"""

import argparse
import hashlib
import io
import ipaddress
import json
import lzma
from pathlib import Path
import re
import struct
import tarfile
import zlib


PINNED = {
    "firmware": "4cb90cfef7a75468e59bd26b2e9ffeaf50e7eb1da27054890bffe124c060857a",
    "universal": "1eb2b173e1f655fab77ee154886acd5076bd0a2b0df2212659daba73d7b830d3",
    "recovery": "f39203ddd7b92f8a7e74845af7ef85417fd820caa295731eac91fa8e03d99b88",
}
LAYOUT = (
    ("boot", 0, 0x40000),
    ("env", 0x40000, 0x10000),
    ("kernel", 0x50000, 0x200000),
    ("rootfs", 0x250000, 0x500000),
    ("rootfs_data", 0x750000, 0xB0000),
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def fingerprint(data):
    return {
        "bytes": len(data),
        "crc32": f"{zlib.crc32(data) & 0xffffffff:08x}",
        "sha256": hashlib.sha256(data).hexdigest(),
    }


def pinned(path, kind):
    data = Path(path).read_bytes()
    require(hashlib.sha256(data).hexdigest() == PINNED[kind],
            f"{kind}: SHA256 differs from the recorded release asset; stop and revalidate")
    return data


def assemble(stock, firmware, universal, recovery, mac, camera_ip, server_ip):
    """Return validated image and environment bytes without writing any files."""
    require(len(stock) == 0x800000, "stock backup must be exactly 8 MiB")
    require(len(universal) <= 0x40000, "universal bootloader exceeds its slot")
    require(stock[0x40:0x440] == universal[0x40:0x440],
            "stock and universal bootloader DDR initialization tables differ")
    require(re.fullmatch(r"(?:[0-9a-f]{2}:){5}[0-9a-f]{2}", mac) is not None,
            "MAC must be six hexadecimal octets separated by colons")
    require(mac != "00:00:00:00:00:00" and not (int(mac[:2], 16) & 1),
            "use the camera's own nonzero, unicast wired MAC")
    camera_ip = str(ipaddress.IPv4Address(camera_ip))
    server_ip = str(ipaddress.IPv4Address(server_ip))
    boot_payload = lzma.decompress(universal[0x4400:], format=lzma.FORMAT_ALONE)
    recovery_payload = lzma.decompress(recovery[0x2C00:], format=lzma.FORMAT_ALONE)
    require(boot_payload == recovery_payload, "recovery and universal U-Boot payloads differ")

    # Read archive members without extracting paths or executing anything.
    with tarfile.open(fileobj=io.BytesIO(firmware), mode="r:gz") as archive:
        members = {}
        for member in archive:
            if member.isfile():
                name = Path(member.name).name
                require(name not in members, f"duplicate archive member: {name}")
                members[name] = archive.extractfile(member).read()
    for name, data in members.items():
        if not name.endswith(".md5sum"):
            expected = members[name + ".md5sum"].decode("ascii").split()[0]
            require(hashlib.md5(data).hexdigest() == expected, f"component MD5 failed: {name}")
    kernel = members["uImage.hi3518ev200"]
    rootfs = members["rootfs.squashfs.hi3518ev200"]
    require(64 <= len(kernel) <= 0x200000, "kernel does not fit its 2 MiB slot")
    require(len(rootfs) <= 0x500000 and rootfs[:4] == b"hsqs", "invalid or oversized SquashFS")
    require(kernel[:4] == bytes.fromhex("27051956") and kernel[29] == 2,
            "kernel is not an ARM uImage")
    header = bytearray(kernel[:64])
    expected_header_crc = struct.unpack_from(">I", header, 4)[0]
    header[4:8] = b"\0" * 4
    require(zlib.crc32(header) == expected_header_crc, "uImage header CRC mismatch")
    require(len(kernel) == 64 + struct.unpack_from(">I", kernel, 12)[0], "uImage length mismatch")
    require(zlib.crc32(kernel[64:]) == struct.unpack_from(">I", kernel, 24)[0],
            "uImage data CRC mismatch")

    # Preserve the pinned bootloader's default commands and insertion order.
    start = boot_payload.index(b"bootargs=mem=")
    end = boot_payload.index(b"\0\0", start)
    env = dict(item.decode("ascii").split("=", 1)
               for item in boot_payload[start:end].split(b"\0"))
    env.update(
        ethaddr=mac, ipaddr=camera_ip, serverip=server_ip,
        netmask="255.255.255.0", mdio_intf="rmii", phyaddru="0", phyaddrd="1",
        sensor="sc2235", osmem="32M", totalmem="64M", netmode="eth",
        netaddr_fallback=camera_ip, extras="",
    )
    env.pop("gatewayip", None)
    body = b"\0".join(f"{key}={value}".encode("ascii") for key, value in env.items()) + b"\0\0"
    require(len(body) < 0x10000 - 4, "environment is too large")
    body = body.ljust(0x10000 - 4, b"\xff")
    env_bin = struct.pack("<I", zlib.crc32(body)) + body
    image = bytearray(b"\xff" * 0x800000)
    for offset, data in ((0, universal), (0x40000, env_bin),
                         (0x50000, kernel), (0x250000, rootfs)):
        image[offset:offset + len(data)] = data
    require(image[0x750000:] == b"\xff" * 0xB0000, "overlay must initially be erased")
    return bytes(image), "".join(f"{key}={value}\n" for key, value in env.items()), env_bin


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for flag in ("stock", "firmware", "universal", "recovery", "out"):
        parser.add_argument("--" + flag, required=True, type=Path)
    parser.add_argument("--mac", required=True, help="the unit's own wired Ethernet MAC")
    parser.add_argument("--camera-ip", default="192.168.2.113")
    parser.add_argument("--server-ip", default="192.168.2.115")
    args = parser.parse_args()
    try:
        stock = args.stock.read_bytes()
        firmware = pinned(args.firmware, "firmware")
        universal = pinned(args.universal, "universal")
        recovery = pinned(args.recovery, "recovery")
        image, env_text, env_bin = assemble(
            stock, firmware, universal, recovery, args.mac.lower(), args.camera_ip, args.server_ip)
        manifest = {
            "recorded_release_date": "2026-11-17",
            "warning": "Private stock configuration and a board-specific raw NOR image; not a web update package",
            "stock": fingerprint(stock), "candidate": fingerprint(image),
            "stock_nonboot_crc32": fingerprint(stock[0x40000:])["crc32"],
            "candidate_nonboot_crc32": fingerprint(image[0x40000:])["crc32"],
            "layout": [{"name": name, "offset": hex(offset), "length": hex(length)}
                       for name, offset, length in LAYOUT],
            "pinned_source_sha256": PINNED,
        }
        # Refuse an existing directory, so a previous backup is never replaced.
        args.out.mkdir(parents=True, exist_ok=False)
        (args.out / "bedee-stock-8m.bin").write_bytes(stock)
        (args.out / "bedee-openipc-lite-8m-candidate.bin").write_bytes(image)
        (args.out / "u-boot-hi3518ev200-recovery.bin").write_bytes(recovery)
        (args.out / "openipc-env.txt").write_text(env_text, encoding="ascii")
        (args.out / "openipc-env-64k.bin").write_bytes(env_bin)
        (args.out / "image-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    except (OSError, ValueError, KeyError, EOFError, lzma.LZMAError, tarfile.TarError) as exc:
        parser.exit(1, f"ERROR: {exc}\n")
    print(json.dumps(manifest, indent=2))
    print("Prepared local files only. No camera, serial port or network was accessed.")


if __name__ == "__main__":
    main()
