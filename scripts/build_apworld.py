#!/usr/bin/env python3
"""Build project_zomboid.apworld from tracked sources using the stdlib only.

Python is for contributors/build automation; players do NOT need to install it.
"""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

REPO = Path(__file__).resolve().parents[1]
WORLD = REPO / 'archipelago' / 'project_zomboid'
OUTPUT = REPO / 'archipelago' / 'project_zomboid.apworld'


def build():
    files = sorted(p for p in WORLD.rglob('*') if p.is_file() and p.suffix in {'.py', '.json'})
    assert files and (WORLD / '__init__.py') in files
    with ZipFile(OUTPUT, 'w', ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, path.relative_to(REPO / 'archipelago').as_posix())
    print(f'Built {OUTPUT} from {len(files)} tracked source files')


if __name__ == '__main__':
    build()
