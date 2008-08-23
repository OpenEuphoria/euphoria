
#ifndef __RBT__H
#define __RBT__H
#define ASSERTING 1	/* <<<< REMOVE if you don't want asserts */


#define RED_NODE   (1)
#define BLACK_NODE (0)

typedef struct rbt_kv
{
	void* key;
	void* value;
} rbt_kv;

typedef struct rbt_node 
{
	struct rbt_node* parent;
	struct rbt_node* left;
	struct rbt_node* right;
	int              type; /* Either RED_NODE or BLACK_NODE */
	rbt_kv           data;
} rbt_node;

typedef struct rbt_tree 
{
	rbt_node*    root;	// Points to node whose left node points to the root node.
	rbt_node*    end;	// This is the sentinel node
	unsigned int count;	// The number of keys in the tree.
	
	int  (*compare)   (const void* keyA, const void* keyB); 
	void (*free_item) (const rbt_kv* data);
	int  (*walk_func) (const struct rbt_tree* tree, const int state, const rbt_kv* node_data, void* walk_data);

} rbt_tree;

rbt_tree*  RBT_Create ( int  (*compare)  (const void*, const void*),
						void (*free_item)(const rbt_kv*), 
						int  (*walk_func)(const rbt_tree*, const int, const rbt_kv*, void*)
					  );
/* 
  	compare(keyA, keyB) : Called when two keys need to be compared.
  		receives pointers to two keys, and must return ...
		-1 : keyA <  keyB
		 0 : keyA == keyB
		 1 : keyA >  keyB
		
  	free_item(key, value) : Called when a node is being removed from the tree.
  		receives a pointer to a key and a pointer to a value,
        it must free any resources used by these as they are
        about to be removed from the tree.
                        
	walk_func(tree, state, key, value, walk_data) : Called by RBT_Walk to process
	                                          each key/value pair in order.
		receives ...
			** the tree that is being walked
			** a state flag ...
			-1 when the tree is about to be walked. In this case the key and
				value parameters are null.
			 0 when the tree is being walked. In this case the key and
				value parameters are valid.
			 1 when the tree is finished being walked. In this case the key and
				value parameters are null.
			** a pointer to a key and a pointer its value (when state == 0),
			** whatever data was passed to the RBT_Walk function.

*/


void*      RBT_Destroy   (rbt_tree* tree);

int        RBT_Insert    (rbt_tree* tree, rbt_kv* data);

void       RBT_Delete    (rbt_tree* tree, rbt_kv* data);

int        RBT_Find      (rbt_tree* tree, rbt_kv* data);

int        RBT_Find_First(rbt_tree* tree, rbt_kv* data);

int        RBT_Find_Last (rbt_tree* tree, rbt_kv* data);

int        RBT_Find_Next (rbt_tree* tree, rbt_kv* data);

int        RBT_Find_Prev (rbt_tree* tree, rbt_kv* data);

int        RBT_Length    (rbt_tree* tree);

int        RBT_Walk      (rbt_tree* tree, void *walk_data);

#endif
