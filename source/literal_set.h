typedef enum {SEQUENCE_PAIR, INDEX_MAP} access_method;

struct value_name_list {
		double value;
		unsigned char * string;
		struct value_name_list * next;
};

struct literal_set {
	unsigned char * name;
	struct value_name_list * list;
};
	
