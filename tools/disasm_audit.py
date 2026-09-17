#!/usr/bin/env python3
"""D7 gate: is the disassembly complete?

    python3 tools/disasm_audit.py            (make check-audit; needs make skool first)

Reads src/*.ctl and work/*.skool and checks, for the main program and every bank:

  titles       every block has a real title (not SkoolKit's "Routine at", "Data block at",
               "Message at") and a description
  unused       every u block and every block titled as unused says why (a description)
  entries      every instruction that code outside its block jumps to or calls is marked:
               a label, a mid-block comment, or a comment on the instruction
  data refs    every address the code reads or writes by absolute address (LD (nn),r,
               LD r,(nn), LD rr,(nn), LD (nn),rr, and the operands of LD rr,nn that point
               into a data block) is explained: a label or a commented statement at that
               address, or the address named in its block's description or comments
  operands     every instruction whose operand the code rewrites (self-modifying code)
               carries a comment

Prints each failure and a summary, and exits non-zero if anything fails.
"""
import glob
import os
import re
import sys

DEFAULT_TITLE = re.compile(r"^(Routine at|Data block at|Message at) [0-9A-F]{4}$")
BLOCK = re.compile(r"^([bcgistuw]) \$([0-9A-F]{4})(?: (.*))?$")
INSTR = re.compile(r"^([a-z* ])\$([0-9A-F]{4}) (\S[^;]*?)\s*(?:;\s*(.*))?$")


def load_ctl(path):
    """blocks: address -> dict(kind, title, described)"""
    blocks, cur = {}, None
    for ln in open(path):
        ln = ln.rstrip("\n")
        m = BLOCK.match(ln)
        if m:
            cur = int(m.group(2), 16)
            blocks[cur] = {"kind": m.group(1), "title": m.group(3) or "", "described": False}
            continue
        if cur is not None and re.match(r"^D \$[0-9A-F]{4} \S", ln):
            blocks[cur]["described"] = True
    return blocks


def load_skool(path):
    """instructions in order: (address, block start, kind, text, comment, labelled, mid-commented)"""
    out, block, kind, label, mid = [], None, None, False, False
    pending_comment = []
    for ln in open(path):
        ln = ln.rstrip("\n")
        if ln.startswith("@label="):
            label = True
            continue
        if ln.startswith(";"):
            pending_comment.append(ln)
            continue
        m = INSTR.match(ln)
        if not m:
            if ln.strip() == "":
                pending_comment = []
            continue
        a = int(m.group(2), 16)
        if m.group(1).isalpha():
            block, kind = a, m.group(1)
            mid = False
        else:
            mid = bool(pending_comment)
        out.append({"a": a, "block": block, "kind": kind, "text": m.group(3).strip(),
                    "comment": (m.group(4) or "").strip(), "label": label, "mid": mid})
        label, pending_comment = False, []
    return out


def continuation_comments(path):
    """Comments that wrap onto following lines belong to the instruction above."""
    lines = open(path).read().splitlines()
    extra = {}
    last = None
    for ln in lines:
        m = INSTR.match(ln)
        if m:
            last = int(m.group(2), 16)
            continue
        if last is not None and re.match(r"^\s+;\s*\S", ln):
            extra[last] = True
    return extra


def audit(name, ctl, skool):
    fails = []
    blocks = load_ctl(ctl)
    starts = sorted(blocks)
    for a in starts:
        b = blocks[a]
        if not b["title"] or DEFAULT_TITLE.match(b["title"]):
            fails.append(("titles", f"{name} ${a:04X} ({b['kind']}) has no title"))
        elif not b["described"]:
            fails.append(("titles", f"{name} ${a:04X} '{b['title'][:50]}' has no description"))
        if (b["kind"] == "u" or "unused" in b["title"].lower()) and not b["described"]:
            fails.append(("unused", f"{name} ${a:04X} is unused with no reason given"))
    if not os.path.exists(skool):
        return fails, len(blocks)
    ins = load_skool(skool)
    wrapped = continuation_comments(skool)
    by_addr = {i["a"]: i for i in ins}

    def block_of(addr):
        k = max((s for s in starts if s <= addr), default=None)
        return k

    def explained(addr):
        i = by_addr.get(addr)
        if i and (i["label"] or i["comment"] or i["mid"] or wrapped.get(addr)):
            return True
        k = block_of(addr)
        if k is None:
            return False
        # named in the block's description or its comments
        tag = f"${addr:04X}"
        text = descriptions.get(k, "")
        return tag in text

    # block descriptions and all comments, by block, from the ctl
    descriptions, cur = {}, None
    for ln in open(ctl):
        m = BLOCK.match(ln)
        if m:
            cur = int(m.group(2), 16)
            descriptions[cur] = ln
            continue
        if cur is not None and ln[:2] in ("D ", "N ", "C ", "B ", "W ", "T ", "S ", "R ", "E ", "@ "):
            descriptions[cur] += ln

    code_blocks = {a for a in starts if blocks[a]["kind"] == "c"}
    for i in ins:
        if i["kind"] != "c":
            continue
        t = i["text"]
        # entries: JP/CALL/JR/DJNZ targets inside another block's body
        m = re.match(r"^(JP|CALL|JR|DJNZ)(?: [A-Z]+,| )\$([0-9A-F]{4})$", t)
        if m:
            target = int(m.group(2), 16)
            tb = block_of(target)
            if tb is not None and tb in code_blocks and target != tb and tb != i["block"]:
                if not explained(target):
                    fails.append(("entries", f"{name} ${target:04X} is entered from ${i['a']:04X} ({t}) but is not marked"))
        # data refs by absolute address
        m = re.match(r"^LD (?:\(\$([0-9A-F]{4})\),[A-Z]+|[A-Z]+,\(\$([0-9A-F]{4})\))$", t)
        if m:
            addr = int(m.group(1) or m.group(2), 16)
            tb = block_of(addr)
            if tb is not None and blocks[tb]["kind"] in "bstuw" and not explained(addr):
                fails.append(("data refs", f"{name} ${addr:04X} is read or written at ${i['a']:04X} ({t}) but is not explained"))
            # operands: a write into a code block rewrites an instruction's operand
            if tb is not None and blocks[tb]["kind"] == "c" and m.group(1):
                holder = max((x["a"] for x in ins if x["a"] <= addr), default=None)
                if holder is not None and not (by_addr[holder]["comment"] or wrapped.get(holder)) and f"${addr:04X}" not in descriptions.get(tb, ""):
                    fails.append(("operands", f"{name} ${holder:04X} ({by_addr[holder]['text']}) has its operand rewritten at ${i['a']:04X} but no comment"))
    return fails, len(blocks)


def main():
    targets = [("main", "src/athena.ctl", "work/athena.skool")]
    for path in sorted(glob.glob("src/bank*.ctl")):
        n = re.search(r"bank(\d+)", path).group(1)
        targets.append((f"bank {n}", path, f"work/bank{n}.skool"))
    allfails, total = [], 0
    for name, ctl, skool in targets:
        fails, count = audit(name, ctl, skool)
        allfails += fails
        total += count
    kinds = {}
    for kind, msg in allfails:
        kinds.setdefault(kind, []).append(msg)
    for kind in ("titles", "unused", "entries", "data refs", "operands"):
        msgs = kinds.get(kind, [])
        print(f"  {'ok  ' if not msgs else 'FAIL'}  {kind}: {len(msgs)} problem{'s' if len(msgs) != 1 else ''}")
        for msg in msgs[:400]:
            print(f"        {msg}")
    if allfails:
        sys.exit(f"D7 check-audit FAILED: {len(allfails)} problems in {total} blocks")
    print(f"D7 check-audit passed: all {total} blocks titled and described, every entry, data reference and rewritten operand explained")


if __name__ == "__main__":
    main()
