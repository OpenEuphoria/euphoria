include std/unittest.e
include std/math.e

include std/base64.e

sequence result, this
object bad_result

result = encode("a")
test_equal("1 char encode", result, "YQ==")
result = decode(result)
test_equal("1 char decode", result, "a")

result = encode("12")
test_equal("2 char encode", result, "MTI=")
result = decode(result)
test_equal("2 char decode", result, "12")

result = encode("XYZ")
test_equal("3 char encode", result, "WFla")
result = decode(result)
test_equal("3 char decode", result, "XYZ")

constant encode_table = {
    "AA==", --# 0
    "AQ==", --# 1
    "AgI=", --# 2
    "AwMD", --# 3
    "BAQEBA==", --# 4
    "BQUFBQU=", --# 5
    "BgYGBgYG", --# 6
    "BwcHBwcHBw==", --# 7
    "CAgICAgICAg=", --# 8
    "CQkJCQkJCQkJ", --# 9
    "CgoKCgoKCgoKCg==", --# 10
    "CwsLCwsLCwsLCws=", --# 11
    "DAwMDAwMDAwMDAwM", --# 12
    "DQ0NDQ0NDQ0NDQ0NDQ==", --# 13
    "Dg4ODg4ODg4ODg4ODg4=", --# 14
    "Dw8PDw8PDw8PDw8PDw8P", --# 15
    "EBAQEBAQEBAQEBAQEBAQEA==", --# 16
    "ERERERERERERERERERERERE=", --# 17
    "EhISEhISEhISEhISEhISEhIS", --# 18
    "ExMTExMTExMTExMTExMTExMTEw==", --# 19
    "FBQUFBQUFBQUFBQUFBQUFBQUFBQ=", --# 20
    "FRUVFRUVFRUVFRUVFRUVFRUVFRUV", --# 21
    "FhYWFhYWFhYWFhYWFhYWFhYWFhYWFg==", --# 22
    "FxcXFxcXFxcXFxcXFxcXFxcXFxcXFxc=", --# 23
    "GBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgY", --# 24
    "GRkZGRkZGRkZGRkZGRkZGRkZGRkZGRkZGQ==", --# 25
    "GhoaGhoaGhoaGhoaGhoaGhoaGhoaGhoaGho=", --# 26
    "GxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsbGxsb", --# 27
    "HBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHA==", --# 28
    "HR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0dHR0=", --# 29
    "Hh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4e", --# 30
    "Hx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHx8fHw==", --# 31
    "ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICA=", --# 32
    "ISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEh", --# 33
    "IiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIiIg==", --# 34
    "IyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyM=", --# 35
    "JCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQk", --# 36
    "JSUlJSUlJSUlJSUlJSUlJSUlJSUlJSUlJSUlJSUlJSUlJSUlJQ==", --# 37
    "JiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiY=", --# 38
    "JycnJycnJycnJycnJycnJycnJycnJycnJycnJycnJycnJycnJycn", --# 39
    "KCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKA==", --# 40
    "KSkpKSkpKSkpKSkpKSkpKSkpKSkpKSkpKSkpKSkpKSkpKSkpKSkpKSk=", --# 41
    "KioqKioqKioqKioqKioqKioqKioqKioqKioqKioqKioqKioqKioqKioq", --# 42
    "KysrKysrKysrKysrKysrKysrKysrKysrKysrKysrKysrKysrKysrKysrKw==", --# 43
    "LCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCwsLCw=", --# 44
    "LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t", --# 45
    "Li4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLi4uLg==", --# 46
    "Ly8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8vLy8=", --# 47
    "MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAw", --# 48
    "MTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMTExMQ==", --# 49
    "MjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjI=", --# 50
    "MzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMzMz", --# 51
    "NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NDQ0NA==", --# 52
    "NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU1NTU=", --# 53
    "NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2", --# 54
    "Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nw==", --# 55
    "ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg4ODg=", --# 56
    "OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5OTk5"  --# 57
}

for i = 0 to 57 do
    this = repeat(i, max({1, i}))
    result = encode(this)
    test_equal(sprintf("%d byte encode", { i }), result, encode_table[i + 1])
    result = decode(result)
    test_equal(sprintf("%d byte conversion", { i }), result, this)
end for
    
sequence msg = "OpenEuphoria is a great\r\nprogramming language that\r\nis open source."
sequence encoded = "T3BlbkV1cGhvcmlhIGlzIGEgZ3JlYXQNCnByb2dyYW1taW5nIGxhbmd1YWdlIHRoYXQNCmlzIG9wZW4gc291cmNlLg=="

test_equal("open euph msg encode", encoded, encode(msg))
test_equal("open euph msg decode", msg, decode(encoded))

msg = 
	"Man is distinguished, not only by his reason, but by this singular " &
	"passion from other animals, which is a lust of the mind, that by a perseverance " &
	"of delight in the continued and indefatigable generation of knowledge, exceeds " &
	"the short vehemence of any carnal pleasure."

encoded = 
	"TWFuIGlzIGRpc3Rpbmd1aXNoZWQsIG5vdCBvbmx5IGJ5IGhpcyByZWFzb24sIGJ1dCBieSB0aGlz\r\n" &
	"IHNpbmd1bGFyIHBhc3Npb24gZnJvbSBvdGhlciBhbmltYWxzLCB3aGljaCBpcyBhIGx1c3Qgb2Yg\r\n" &
	"dGhlIG1pbmQsIHRoYXQgYnkgYSBwZXJzZXZlcmFuY2Ugb2YgZGVsaWdodCBpbiB0aGUgY29udGlu\r\n" &
	"dWVkIGFuZCBpbmRlZmF0aWdhYmxlIGdlbmVyYXRpb24gb2Yga25vd2xlZGdlLCBleGNlZWRzIHRo\r\n" &
	"ZSBzaG9ydCB2ZWhlbWVuY2Ugb2YgYW55IGNhcm5hbCBwbGVhc3VyZS4="

test_equal("Thomas Hobbes' Leviathan encode", encoded, encode(msg, 76))
test_equal("Thomas Hobbes' Leviathan decode", msg, decode(encoded))

bad_result = decode("aA=")
test_equal("Length not a multiple of 4", bad_result, -1)

bad_result = decode("a===")
test_equal("Too many pad characters", bad_result, -1)

bad_result = decode("YX!q")
test_equal("Invalid base64 character", bad_result, -1)

bad_result = decode("YX\0q")
test_equal("Null base64 character", bad_result, -1)

test_report()

