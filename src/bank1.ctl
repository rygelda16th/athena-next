@ $C000 start
@ $C000 org
b $C000 Bank 1: the ending, the hi-score screen and the world settings
D $C000 Paged by #R$B8C3 for every world load (85 bytes of world settings), by #R$B908 for the ending picture and by #R$B929 for the hi-score screen.
B $C000,16384,16
