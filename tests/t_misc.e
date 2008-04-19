include misc.e
include unittest.e

setTestModuleName("misc.e")

-- TODO: many more functions to test

testEqual("sprint() integer", "10", sprint(10))
testEqual("sprint() float", "5.5", sprint(5.5))
testEqual("sprint() sequence", "{1,2,3}", sprint({1,2,3}))
testEqual("sprintf() integer", "i=1", sprintf("i=%d", {1}))
testEqual("sprintf() float", "i=5.5", sprintf("i=%.1f", {5.5}))
testEqual("sprintf() percent", "%", sprintf("%%", {}))
