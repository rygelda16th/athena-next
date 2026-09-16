@ $C000 start
@ $C000 org
b $C000 Bank 1: the ending pictures and the world data that did not fit
D $C000 Paged by #R$B8C3@main for every world load (the 85 bytes of world data that run past $B65F), by #R$B908@main for the credits picture and by #R$B929@main for the Combat School advert.
B $C000,16384,16
