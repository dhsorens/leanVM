"""Keep each extraction's Assumptions/*External.lean in step with the templates hax regenerates.

hax seeds Assumptions/<stem>.lean once from Extraction/<stem>_Template.lean and never touches it
again. After every extraction this keeps the declarations already there (which may have been
fixed by hand), adds the ones the template gained, and drops the ones it lost, in template order.

A new declaration gets one rewrite: Aeneas gives `fmt` a `Formatter` write-back that the hax Lean
library's `Debug` and `Display` do not have, so it is dropped.
"""

import pathlib
import re
import sys

STEMS = ("TypesExternal", "FunsExternal")
DECLARATION = re.compile(r"\n(?:axiom|opaque|def|structure|inductive|abbrev)\s+(\S+)")
FORMATTER_WRITE_BACK = re.compile(r"\s*×\s*\(core\.fmt\.Formatter\s*→\s*core\.fmt\.Formatter\)\)")


def split(text):
    """The header, then each declaration's block (its doc comment and body) by name."""
    start = text.find("\n/-- ")
    if start < 0:
        return text, {}
    blocks = {}
    for block in re.split(r"(?=\n/-- )", text[start:]):
        match = DECLARATION.search(block)
        if match:
            blocks[match.group(1)] = block
    return text[:start], blocks


def seed(block):
    if ".Insts.CoreFmtDebug.fmt" in block or ".Insts.CoreFmtDisplay.fmt" in block:
        return FORMATTER_WRITE_BACK.sub(")", block)
    return block


def sync(package):
    for stem in STEMS:
        template = next(package.glob(f"*/Extraction/{stem}_Template.lean"), None)
        if template is None:
            continue
        assumption = template.parent.parent / "Assumptions" / f"{stem}.lean"
        _, wanted = split(template.read_text())
        header, present = split(assumption.read_text())
        text = header + "".join(present.get(name) or seed(block) for name, block in wanted.items())
        assumption.write_text(text if text.endswith("\n") else text + "\n")
        for name in wanted.keys() - present.keys():
            print(f"{assumption}: added {name}")
        for name in present.keys() - wanted.keys():
            print(f"{assumption}: dropped {name}")


if __name__ == "__main__":
    for path in sys.argv[1:]:
        sync(pathlib.Path(path))
