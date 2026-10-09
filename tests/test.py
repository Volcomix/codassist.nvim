def sloubi():
    print("sloubi")


testouille = lambda: print("testouille")
sum = lambda a, b: a + b


def pipoup(cb):
    cb()


def test():
    pipoup(lambda: print("mais ouais"))
