include std/unittest.e

include std/expat.e

sequence the_start_name, the_end_name, the_data, the_comment

procedure start_element_handler(sequence name, sequence attrs)
    the_start_name = name
end procedure

procedure end_element_handler(sequence name)
    the_end_name = name
end procedure

procedure data_handler(sequence data)
    the_data = data
end procedure

procedure comment_handler(sequence comment)
    the_comment = comment
end procedure

sequence test_xml = `<?xml version="1.0"?><!-- a person --><person>John Doe</person>`

object p = expat:create("US-ASCII")
expat:set_start_element_callback(p, routine_id("start_element_handler"))
expat:set_end_element_callback(p, routine_id("end_element_handler"))
expat:set_char_data_callback(p, routine_id("data_handler"))
expat:set_comment_callback(p, routine_id("comment_handler"))

integer result = expat:parse(p, test_xml)

test_equal("start element callback", "person", the_start_name)
test_equal("end element callback", "person", the_end_name)
test_equal("data callback", "John Doe", the_data)
test_equal("comment callback", " a person ", the_comment)

test_report()
