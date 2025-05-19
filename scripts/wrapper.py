#!/usr/bin/env python3.11
from __future__ import annotations

import argparse
import functools
import getpass
import os
import shlex
import sys
from pathlib import Path
from typing import Iterable, NoReturn

IMAGE = "genome-studio"
VERSION = "latest"

USERNAME = getpass.getuser()
PROJECT_ROOT = Path("/maps/projects")
PROJECT_FOLDERS = ("apps", "data", "people", "scratch")
DATASET_ROOT = Path("/maps/datasets")
HDIR_ROOT = Path(f"/maps/hdir/{USERNAME}")
NDIR_ROOT = Path(f"/maps/groupdir/{USERNAME}")
SDIR_ROOT = Path(f"/maps/sdir/{USERNAME}")


def eprint(*values: object) -> None:
    print(*values, file=sys.stderr)


def error(*values: object) -> None:
    eprint("ERROR:", *values)


def abort(*values: object) -> NoReturn:
    error(*values)
    sys.exit(1)


def quote(value: str | Path) -> str:
    return shlex.quote(str(value))


def validate_names(values: Iterable[Path], root: Path, name: str) -> Iterable[Path]:
    for value in values:
        value = value.resolve()
        if value.parent not in (Path("."), root):
            abort(f"{name} {quote(value)} contains dir component; use name only")

        yield value


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        formatter_class=functools.partial(
            argparse.ArgumentDefaultsHelpFormatter,
            width=79,
        ),
        allow_abbrev=False,
    )

    parser.add_argument(
        "--project",
        type=Path,
        dest="projects",
        action="append",
        default=[],
        help="Name of project to make available in the container",
    )

    parser.add_argument(
        "--dataset",
        type=Path,
        dest="datasets",
        action="append",
        default=[],
        help="Name of datasets to make available in the container",
    )

    parser.add_argument(
        "--hdir",
        action="store_true",
        default=False,
        help="Make the N-drive folder available in the container",
    )

    parser.add_argument(
        "--ndir",
        type=Path,
        dest="ndirs",
        action="append",
        default=[],
        help="Name of N-drive group folder to make available in the container",
    )

    parser.add_argument(
        "--sdir",
        type=Path,
        dest="sdirs",
        action="append",
        default=[],
        help="Name of S-drive group folder to make available in the container",
    )

    parser.add_argument(
        "--wine-prefix",
        type=Path,
        default=Path(f"/scratch/containers/{USERNAME}/wineprefix"),
        help="Location of wine prefix",
    )

    parser.add_argument("--podman", default="podman", help="podman executable")
    parser.add_argument("--uid", type=int, default=os.getuid(), help="UID for uidmap")
    parser.add_argument("--gid", type=int, default=os.getgid(), help="GID for gidmap")

    parser.add_argument("--port", type=int, default=3389, help="Exposed port for XRDP")

    parser.add_argument(
        "--dry-run",
        default=False,
        action="store_true",
        help="Print podman command to be executed",
    )

    parser.add_argument(
        "--background",
        default=False,
        action="store_true",
        help="Run the container in the background, instead of interactively",
    )

    parser.add_argument(
        "--entry-point",
        default=None,
        help="Override podman container entry-point",
    )

    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    mount_points: list[Path] = [
        Path("/scratch"),
        Path("~").expanduser(),
    ]

    for project in validate_names(args.projects, PROJECT_ROOT, "Project"):
        for subfolder in PROJECT_FOLDERS:
            mount_points.append(PROJECT_ROOT / project.name / subfolder)

    for dataset in validate_names(args.datasets, DATASET_ROOT, "Dataset"):
        mount_points.append(DATASET_ROOT / dataset.name)

    for sdir in validate_names(args.sdirs, SDIR_ROOT, "S-drive group"):
        mount_points.append(SDIR_ROOT / sdir)

    for ndir in validate_names(args.ndirs, NDIR_ROOT, "N-drive group"):
        mount_points.append(NDIR_ROOT / ndir)

    if args.hdir:
        mount_points.append(HDIR_ROOT)

    errors = False
    for path in mount_points:
        eprint("Checking", quote(path))
        if not path.is_dir():
            error(f"Mount-point {quote(path)} does not exist or is not a folder")
            errors = True

    if errors:
        return 1

    command: list[str] = [
        args.podman,
        "run",
        "--rm",
        "-it",
        f"-p{args.port}:3389",
        "--uidmap",
        f"+1000:@{args.uid}:1",
        "--gidmap",
        f"+1000:@{args.gid}:1",
        "-v",
        f"{args.wine_prefix}:/opt/genome-studio/wineprefix:z",
    ]

    for path in mount_points:
        command += ["-v", f"{path}:{path}"]

    if not args.background:
        command += ["--rm", "-it"]

    if args.entry_point is not None:
        command += ["--entrypoint", args.entry_point]

    command += [f"{IMAGE}:{VERSION}"]
    if args.dry_run:
        print(*(shlex.quote(v) for v in command))
        return 0
    else:
        os.execvp(args.podman, command)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
