SET CLASSLIB TO wwIPSTUFF ADDITIVE

*** Force the server to unload so we don't have to
*** do it manually.
o=CREATE("wwiPSTUFF")
o.HTTPGet("http://localhost/foxisapi/foxisapi.dll/Reset")

wait window "Hang on waiting to unload server..." TIMEOUT 2
BUILD EXE FIRSTSERVER FROM FIRSTSERVER recompile

WAIT CLEAR

RETURN
