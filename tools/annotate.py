#!/usr/bin/env python3
"""Apply a chunk's annotations (build/dN/annotations.json) to the disassembly.

    python3 tools/annotate.py ctl   build/d1/annotations.json   # step 1, on src/athena.ctl
                                                (add --bank N for src/bankN.ctl and work/bankN.skool)
    make skool                                                     # regenerate work/athena.skool
    python3 tools/annotate.py skool build/d1/annotations.json   # step 2, on work/athena.skool
    make ctl && make check-ctl && make check-reasm                 # canonical ctl, gates

The JSON is the merged, reviewed output of a chunk's analysis:
  {"text_corrections": [{"old", "new"}],                                     step 1
   "ctl_blocks": [{"address", "kind", "end"?, "subs"?}],                     step 1
   "variables": [{"address", "length", "label", "meaning", "sub"?}],         steps 1 and 2
   "blocks": [{"address", "kind", "label", "title", "description",           step 2
               "registers": [...], "comments": [{"address", "text"}],
               "mid_comments": [...], "entry_labels": [{"address", "name"}]}]}
(a block without a title keeps its header and only gets its comments and labels)

ctl_blocks make a block start at "address" with type "kind" (or, with "insert", add one
sub-block line such as "B $D4F8,1" inside the block holding "address", and drop any
lines listed in "remove"); "end" removes every
block start after it and before "end" (joining them into this block); "subs" replaces
the block's sub-block lines (B, C, S, T, W) with the ones given.

A variable inside a data block becomes a sub-block of its own with a label and a
comment ("sub" overrides the sub-block line, e.g. "B $BAA6,12,2"); the rest of that
block's bytes are laid out 8 to a line. A variable inside a code block is an
instruction's operand (self-modifying code): step 2 gives that instruction the
variable's meaning as its comment unless the block annotations comment it already.

Step 1 edits the control file because block boundaries and data sub-blocks decide
how SkoolKit lays the disassembly out; step 2 edits the skool file because that is
where titles, comments and labels live in their final form. `make ctl` then writes
the control file back in skool2ctl's canonical form, which make check-ctl requires.
"""

import json
import re
import sys

ADDR = re.compile(r"\$([0-9A-Fa-f]{4})")
INSTR = re.compile(r"^([a-z* ])\$([0-9A-F]{4}) ")
BLOCK = re.compile(r"^([bcgistuw]) \$([0-9A-F]{4})(.*)$")
SUB = re.compile(r"^[BCSTW] \$")
DATA_SUB = re.compile(r"^[BSTW] \$")
LINE = re.compile(r"^[A-Za-z@] \$([0-9A-F]{4})")


def addr(text):
    return int(ADDR.search(text).group(1), 16)


def block_starts(lines):
    return [(i, m.group(1), int(m.group(2), 16)) for i, ln in enumerate(lines) if (m := BLOCK.match(ln))]


def find_block(lines, a):
    """(line index, kind, start, end) of the block containing address a."""
    starts = block_starts(lines)
    for k, (i, kind, start) in enumerate(starts):
        end = starts[k + 1][2] if k + 1 < len(starts) else 0x10000
        if start <= a < end:
            return i, kind, start, end
    return None


def block_body(lines, i):
    """Index range of the lines that belong to the block whose start line is i."""
    j = i + 1
    while j < len(lines) and not BLOCK.match(lines[j]):
        j += 1
    return i + 1, j


def step_ctl(ann, path="src/athena.ctl"):
    lines = open(path).read().splitlines()
    n_blocks = n_vars = 0
    # Corrections to text an earlier chunk published: each old text must occur exactly once.
    for tc in ann.get("text_corrections", []):
        hits = [i for i, ln in enumerate(lines) if tc["old"] in ln]
        if len(hits) != 1:
            sys.exit(f"text correction matches {len(hits)} lines, not 1: {tc['old'][:70]!r}")
        lines[hits[0]] = lines[hits[0]].replace(tc["old"], tc["new"])
    for cb in ann.get("ctl_blocks", []):
        a = addr(cb["address"])
        if "insert" in cb:
            # one sub-block line inside the block that holds this address (e.g. an inline
            # parameter byte after a CALL), in address order; "remove" drops stale lines
            lo, hi = block_body(lines, find_block(lines, a)[0])
            body = [ln for ln in lines[lo:hi] if ln not in cb.get("remove", [])]
            pos = next((k for k, ln in enumerate(body) if SUB.match(ln) and addr(ln) > a), len(body))
            body.insert(pos, cb["insert"])
            lines[lo:hi] = body
            n_blocks += 1
            continue
        kind = cb["kind"]
        if "end" in cb:
            end = addr(cb["end"])
            lines = [ln for ln in lines
                     if not ((m := BLOCK.match(ln)) and a < int(m.group(2), 16) < end)]
        at = [i for i, _, s in block_starts(lines) if s == a]
        if at:
            m = BLOCK.match(lines[at[0]])
            lines[at[0]] = f"{kind} ${a:04X}{m.group(3)}"
            i = at[0]
        else:
            # In address order among ALL lines, so the old block's later sub-blocks
            # (e.g. T $F10B inside a new code block at $F0C0) move into the new block.
            i = next((k for k, ln in enumerate(lines) if (m := LINE.match(ln)) and int(m.group(1), 16) > a), len(lines))
            lines.insert(i, f"{kind} ${a:04X}")
        if "subs" in cb:
            # replace the layout; in a code block, C lines are comments and stay
            lo, hi = block_body(lines, i)
            keep = [ln for ln in lines[lo:hi]
                    if not (DATA_SUB.match(ln) or (kind != "c" and ln.startswith("C $")))]
            lines[lo:hi] = keep + cb["subs"]
        n_blocks += 1

    # Variables in data blocks: rebuild each such block's sub-blocks around them.
    by_block = {}
    for v in ann.get("variables", []):
        a = addr(v["address"])
        found = find_block(lines, a)
        if found and found[1] == "b":
            by_block.setdefault(found[2], []).append(v)
    for start, vs in sorted(by_block.items()):
        i, kind, start, end = find_block(lines, start)
        # Sub-blocks already published with a comment (and their labels) stay as they are: treat
        # them as variables too, unless a new variable covers the same bytes.
        lo, hi = block_body(lines, i)
        body = lines[lo:hi]
        taken = [(addr(v["address"]), addr(v["address"]) + int(v["length"])) for v in vs]
        for ln in body:
            m = re.match(r"^([BTWS]) \$([0-9A-F]{4}),(\d+)(?:,\S+)? (\S.*)$", ln)
            if not m:
                continue
            a0, n0 = int(m.group(2), 16), int(m.group(3))
            if any(a0 < e and s0 < a0 + n0 for s0, e in taken):
                continue
            lab = next((l.split("label=", 1)[1] for l in body if l.startswith(f"@ ${a0:04X} label=")), None)
            vs = vs + [{"address": f"${a0:04X}", "length": n0, "label": lab, "meaning": m.group(4), "sub": ln[:ln.index(m.group(4))].rstrip()}]
            taken.append((a0, a0 + n0))
        subs, pos = [], start
        for v in sorted(vs, key=lambda v: addr(v["address"])):
            a, n = addr(v["address"]), int(v["length"])
            if a < pos:
                sys.exit(f"variable {v['label']} at ${a:04X} overlaps the one before it")
            if a > pos:
                subs.append(f"B ${pos:04X},{a - pos},8")
            sub = v.get("sub") or (f"W ${a:04X},2" if n == 2 else f"B ${a:04X},{n},{min(n, 16 if n >= 64 else 8)}")
            if v.get("label"):
                subs.append(f"@ ${a:04X} label={v['label']}")
            subs.append(f"{sub} {' '.join(v['meaning'].split())}")
            pos = a + n
            n_vars += 1
        if pos < end:
            subs.append(f"B ${pos:04X},{end - pos},8")
        lo, hi = block_body(lines, i)
        keep = [ln for ln in lines[lo:hi] if not SUB.match(ln) and not ln.startswith("@ ")]
        lines[lo:hi] = keep + subs
    open(path, "w").write("\n".join(lines) + "\n")
    print(f"{path}: {len(ann.get('text_corrections', []))} text corrections, {n_blocks} block changes, {n_vars} variables laid out")


def header(block):
    out = [f"; {block['title']}", ";"]
    desc = block.get("description", "").strip() or "."
    paras = [" ".join(p.split()) for p in desc.split("\n\n") if p.strip()]
    for k, para in enumerate(paras):
        if k:
            out.append("; .")           # SkoolKit's paragraph separator within a section
        out.append("; " + para)
    out.append(";")
    regs = [r for r in block.get("registers", []) if r.strip()]
    if regs:
        for r in regs:
            out.append("; " + " ".join(r.split()))
    else:
        out.pop()                       # no trailing ';' separator without registers
    return out


def step_skool(ann, path="work/athena.skool", other="main"):
    lines = open(path).read().splitlines()
    by_block = {addr(b["address"]): b for b in ann.get("blocks", []) if b.get("title")}
    comments, mids, labels = {}, {}, {}
    for b in ann.get("blocks", []):
        for c in b.get("comments", []):
            comments[addr(c["address"])] = " ".join(c["text"].split())
        for c in b.get("mid_comments", []):
            mids.setdefault(addr(c["address"]), []).append(" ".join(c["text"].split()))
        for e in b.get("entry_labels", []):
            labels[addr(e["address"])] = e["name"]
        if b.get("label"):
            labels[addr(b["address"])] = b["label"]

    # Operand variables: the instruction that holds each one, if it is code.
    starts = sorted((int(m.group(2), 16), m.group(1)) for ln in lines if (m := INSTR.match(ln)))
    kinds, kind = {}, None
    for a, k in starts:
        if k.isalpha():
            kind = k
        kinds[a] = kind
    addrs = [a for a, _ in starts]
    operand_notes = 0
    for v in ann.get("variables", []):
        a = addr(v["address"])
        prev = max((s for s in addrs if s <= a), default=None)
        if prev is None or prev == a or kinds.get(prev) != "c":
            continue
        if prev not in comments:
            comments[prev] = " ".join(v["meaning"].split())
            operand_notes += 1

    out = []
    applied = {"headers": 0, "comments": 0, "mids": 0, "labels": 0, "operands": operand_notes}
    for ln in lines:
        m = INSTR.match(ln)
        if not m:
            out.append(ln)
            continue
        a = int(m.group(2), 16)
        is_start = m.group(1).isalpha()
        if is_start and a in by_block:
            # replace the entry's header: the comment and directive lines just before it
            j = len(out)
            while j > 0 and (out[j - 1].startswith(";") or out[j - 1].startswith("@")):
                j -= 1
            # keep the entry's existing label unless the annotation gives one
            directives = [d for d in out[j:] if d.startswith("@") and (not d.startswith("@label=") or not by_block[a].get("label"))]
            del out[j:]
            out.extend(header(by_block[a]))
            out.extend(directives)
            applied["headers"] += 1
        if a in mids and not (is_start and a in by_block):
            j = len(out)
            while j > 0 and out[j - 1].startswith("@"):
                j -= 1
            directives = out[j:]
            del out[j:]
            out.extend("; " + text for text in mids[a])
            out.extend(directives)
            applied["mids"] += 1
        if a in labels:
            j = len(out)
            while j > 0 and out[j - 1].startswith("@"):
                if out[j - 1].startswith("@label="):
                    del out[j - 1]
                j -= 1
            out.append(f"@label={labels[a]}")
            applied["labels"] += 1
        if a in comments:
            code = ln.partition(";")[0]
            ln = f"{code.rstrip():<20} ; {comments[a]}"
            applied["comments"] += 1
        out.append(ln)

    # #R must name the address of an instruction or data statement; unwrap any that don't.
    known = {int(m.group(2), 16) for ln in out if (m := INSTR.match(ln))}
    unwrapped = []

    def fix(m):
        if int(m.group(1), 16) in known:
            return m.group(0)
        unwrapped.append(m.group(1))
        # in a bank file, an address that is not a statement here is the game's code: link to it there
        return f"#R${m.group(1)}@main" if other != "main" else "$" + m.group(1)
    out = [re.sub(r"#R\$([0-9A-Fa-f]{4})(?![@0-9A-Fa-f])", fix, ln) if ln.startswith(";") or ";" in ln else ln
           for ln in out]
    open(path, "w").write("\n".join(out) + "\n")
    print(f"{path}: " + ", ".join(f"{k} {v}" for k, v in applied.items()))
    if unwrapped:
        how = "linked to @main" if other != "main" else "left as plain addresses"
        print(f"  #R not at a statement, {how}: {', '.join(sorted(set(unwrapped)))}")


def main():
    # annotate.py ctl|skool ANNOTATIONS.json [--bank N]   (--bank: src/bankN.ctl / work/bankN.skool)
    args = sys.argv[1:]
    bank = None
    if "--bank" in args:
        k = args.index("--bank")
        bank = int(args[k + 1])
        del args[k:k + 2]
    step, path = args[0], args[1]
    ann = json.load(open(path))
    if step == "ctl":
        step_ctl(ann, f"src/bank{bank}.ctl" if bank is not None else "src/athena.ctl")
    elif step == "skool":
        if bank is not None:
            step_skool(ann, f"work/bank{bank}.skool", other="main-code")
        else:
            step_skool(ann)
    else:
        sys.exit("step must be ctl or skool")


if __name__ == "__main__":
    main()
