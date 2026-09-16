@ $C000 start
@ $C000 org
b $C000 Bank 7: world 7
D $C000 Copied whole to the world area at $7660 by #R$B8C3 when world 7 starts. Holds the one bit (at +$341B) in which the snapshot differs from the original tape; see docs/provenance.md.
B $C000,16384,16
