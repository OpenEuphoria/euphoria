#include <stdlib.h>
#include "rbt.h"


// =============================================================================
//
//  Internal Routines 
//
// =============================================================================

/*------------------------------------------------------------------------------
Procedure: promote_right 
  
Arguments:
	focus_node = The node to change. 
	end        = The sentinal node.

Description:
	Rearranges the relationships of the focus_node such that its
	right node becomes its parent node.
------------------------------------------------------------------------------*/
static void promote_right(rbt_node* focus_node, rbt_node* end)
{
	rbt_node* new_parent;
	rbt_node* old_parent;

	/* Capture the parents in question. */
	new_parent         = focus_node->right;
	old_parent         = focus_node->parent;
	
	/* Exchange parentage. */
	new_parent->parent = old_parent;   
	focus_node->parent = new_parent;
	
	/* Adjust the left and right pointers accordingly. */	
	focus_node->right  = new_parent->left;
	
	if (new_parent->left != end) 
		new_parent->left->parent = focus_node;
	new_parent->left   = focus_node;
	
	if ( old_parent->left == focus_node )
		old_parent->left  = new_parent;
	else
		old_parent->right = new_parent;	
	
}

/*-----------------------------------------------------------------------------
Procedure: promote_left
  
Arguments:
	focus_node = The node to change. 
	end        = The sentinal node.

Description:
	Rearranges the relationships of the focus_node such that its
	left node becomes its parent node.
-----------------------------------------------------------------------------*/
static void promote_left(rbt_node* focus_node, rbt_node* end)
{
	rbt_node* new_parent;
	rbt_node* old_parent;

	/* Capture the parents in question. */
	new_parent         = focus_node->left;
	old_parent         = focus_node->parent;
	
	/* Exchange parentage. */
	new_parent->parent = old_parent;   
	focus_node->parent = new_parent;
	
	/* Adjust the left and right pointers accordingly. */	
	focus_node->left   = new_parent->right;
	
	if (new_parent->right != end) 
		new_parent->right->parent = focus_node;
	new_parent->right   = focus_node;
	
	if ( old_parent->right == focus_node )
		old_parent->right  = new_parent;
	else
		old_parent->left = new_parent;	
	
}

/*------------------------------------------------------------------------------
Function: next_key  

Arguments:
	tree = The tree
	current_node = The node to find the next key of.
	
Returns: A pointer to the node that contains the next key, or if there is
         no larger key this returns a pointer to the sentinal node.
------------------------------------------------------------------------------*/
static rbt_node* next_key(rbt_tree* tree, rbt_node* current_node)
{ 
	rbt_node* next_node;
	rbt_node* end;
	
	end  = tree->end;
	
	if (current_node->right != end) 
	{
		// The next key must be down this branch somewhere,
		// so keep going down until there is nothing smaller
		// than the next node.
		next_node = current_node->right;
		while (next_node->left != end)
		{
			next_node = next_node->left;
		}
	}
	else
	{	// Need to go up the tree until I find I'm no longer
	    // on the right of my parent.
		next_node = current_node->parent;
		while (next_node->right == current_node)
		{
			current_node = next_node;
			next_node    = next_node->parent;
		}
		// Special test to see if I hit the top of the tree.
		if (next_node == tree->root)
			next_node = end;	// There is no larger key.
	}
	return(next_node);
}

/*------------------------------------------------------------------------------
Function: prev_key  

Arguments:
	tree = The tree
	current_node = The node to find the previous key of.
	
Returns: A pointer to the node that contains the previous key, or if there is
         no smaller key this returns a pointer to the sentinal node.
------------------------------------------------------------------------------*/
static rbt_node* prev_key(rbt_tree* tree, rbt_node* current_node)
{ 
	rbt_node* prev_node;
	rbt_node* end;
	
	end  = tree->end;
	
	if (current_node->left != end) 
	{
		// The previous key must be down this branch somewhere,
		// so keep going down until there is nothing larger
		// than the previous node.
		prev_node = current_node->left;
		while (prev_node->right != end)
		{
			prev_node = prev_node->right;
		}
	}
	else
	{	// Need to go up the tree until I find I'm no longer
	    // on the left of my parent.
		prev_node = current_node->parent;
		while (prev_node->left == current_node)
		{
			current_node = prev_node;
			prev_node    = prev_node->parent;
		}
		// Special test to see if I hit the top of the tree.
		if (prev_node == tree->root)
			prev_node = end;	// There is no smaller key.
	}
	return(prev_node);
}

/*------------------------------------------------------------------------------
Function:  walk_tree 

Arguments:  
	tree_p = The tree being walked
	node_p = The top of the branch being walked.
	walk_data_p = Whatever data was passed to RBT_Walk()

Returns: 0 if walk should continue, !0 if walk should stop. It can only be !0
         if that is what is returned by the user supplied node processing routine.

Description: This is called by RBT_Walk and it recursively walks the left branch,
             then calls the user supplied routine with the current node, then
             walks the right branch. The net effect is that each key/value is
             passed to the user supplied routine in order.
------------------------------------------------------------------------------*/
static int walk_tree(rbt_tree* tree_p, rbt_node* node_p, void *walk_data_p)
{
	rbt_node *end_l;
	rbt_node *next_node_l;
	int res_l;
	rbt_kv data_copy_l;
	
	end_l = tree_p->end;
	
	if (node_p != end_l)
	{
		/* Do everything to the left first. */
		if ( (next_node_l = node_p->left) != end_l) 
			if ( (res_l = walk_tree(tree_p, next_node_l, walk_data_p)) != 0)
				return res_l;
		
		/* Now process this node. */
		data_copy_l = node_p->data;	// Pass a copy of the data so user can't
		                            // change the node's data.
		if ( (res_l = tree_p->walk_func(tree_p, 0, &data_copy_l, walk_data_p)) != 0)
			return res_l;
		
		/* Finally, do everything to the right. */
		if ( (next_node_l = node_p->right) != end_l)
			if ((res_l = walk_tree(tree_p, next_node_l, walk_data_p)) != 0)
				return res_l;
	}
	return 0;
}

/*------------------------------------------------------------------------------
Function:  walk_tree 

Arguments:  
	tree_p = The tree being walked
	node_p = The top of the branch being walked.
	walk_data_p = Whatever data was passed to RBT_Walk()

Returns: 0 if walk should continue, !0 if walk should stop. It can only be !0
         if that is what is returned by the user supplied node processing routine.

Description: This is called by RBT_Walk and it recursively walks the left branch,
             then calls the user supplied routine with the current node, then
             walks the right branch. The net effect is that each key/value is
             passed to the user supplied routine in order.
------------------------------------------------------------------------------*/
#include <stdio.h>
static void debug_tree(rbt_tree* tree_p, rbt_node* node_p)
{
	rbt_node *end_l;
	rbt_node *next_node_l;
	
	end_l = tree_p->end;
	
	if (node_p != end_l)
	{
		/* Do everything to the left first. */
		if ( (next_node_l = node_p->left) != end_l) 
			debug_tree(tree_p, next_node_l);
		
		printf("n=%08x ", node_p);
		printf("p=%08x ", node_p->parent);
		printf("l=%08x ", node_p->left);
		printf("r=%08x ", node_p->right);
		printf("k=%08x ", node_p->data.key);
		printf("v=%08x ", node_p->data.value);
		printf("t=%d ",   node_p->type);
		printf("\n");
		
		/* Finally, do everything to the right. */
		if ( (next_node_l = node_p->right) != end_l)
			debug_tree(tree_p, next_node_l);
	}
	return;
}

/*------------------------------------------------------------------------------
Procedure: destroy_branch 

Arguments:  
	tree_p = The tree that the node resides in.
	node_p = The node to delete.
	
Description:
	First it destroys everying on the left then right, then is destroys the
	supplied node. If the tree was created with a 'free_item' routine, it is
	called for each node so that the user program can release any resources
	that might be attached to the node's key or value.
------------------------------------------------------------------------------*/
static void destroy_branch(rbt_tree* tree_p, rbt_node* node_p) 
{
	if (node_p->left != tree_p->end)
		destroy_branch(tree_p, node_p->left);
			
	if (node_p->right != tree_p->end)
		destroy_branch(tree_p, node_p->right);
		
	if (tree_p->free_item != 0)
		// Allow user to release any resources associated with either the key or value.
		tree_p->free_item( &(node_p->data) ); // Don't care if user changes node.
	
	free(node_p);

}

/*------------------------------------------------------------------------------
Function: find_eq

Arguments:
	tree_p = The tree to scan.
	key_p = A pointer to the key to match.

Returns: tree->end if the key could not be found, otherwise the node pointer
         of the matching key.
         
Description: Looks for the node that contains a key equal the supplied key.
------------------------------------------------------------------------------*/
static rbt_node* find_eq(rbt_tree* tree_p, void* key_p) 
{
	rbt_node* current_node_l;
	rbt_node* end;
	int compare_result_l;
	
	current_node_l = tree_p->root->left;
	end = tree_p->end;
	
	while(current_node_l != end)
	{
		compare_result_l = tree_p->compare(current_node_l->data.key, key_p);
		if (compare_result_l > 0)
		{
			current_node_l = current_node_l->left;
		} 
		else if (compare_result_l < 0)
		{
			current_node_l = current_node_l->right;
		}
		else
			break;		
	}
	return current_node_l;
}

/*------------------------------------------------------------------------------
Function: find_ge

Arguments:
	tree_p = The tree_p to scan.
	key_p = A pointer to the key to match.

Returns: tree_p->end if the key could not be found, otherwise the node pointer
         of the matching key.
         
Description: Looks for the first node that contains a key equal to or greater than
         the supplied key.
------------------------------------------------------------------------------*/
static rbt_node* find_ge(rbt_tree* tree_p, void* key_p) 
{
	rbt_node* current_node_l;
	rbt_node* end;
	int compare_result_l;
	
	current_node_l = tree_p->root->left;
	end = tree_p->end;
	
	while(current_node_l != end)
	{
		compare_result_l = tree_p->compare(current_node_l->data.key, key_p);
		if (compare_result_l < 0)
		{
			current_node_l = current_node_l->right;
		}
		else
			break;		
	}
	return current_node_l;
}

/*------------------------------------------------------------------------------
Function: find_le

Arguments:
	tree_p = The tree_p to scan.
	key_p = A pointer to the key to match.

Returns: tree_p->end if the key could not be found, otherwise the node pointer
         of the matching key.
         
Description: Looks for the last node that contains a key equal to or less than
         the supplied key.
------------------------------------------------------------------------------*/
static rbt_node* find_le(rbt_tree* tree_p, void* key_p) 
{
	rbt_node* current_node_l;
	rbt_node* end;
	int compare_result_l;
	
	current_node_l = tree_p->root->left;
	end = tree_p->end;
	
	while(current_node_l != end)
	{
		compare_result_l = tree_p->compare(current_node_l->data.key, key_p);
		if (compare_result_l > 0)
		{
			current_node_l = current_node_l->left;
		}
		else
			break;		
	}
	return current_node_l;
}

/*------------------------------------------------------------------------------
Procedure: fix_rb_state 

Arguments:
	tree_p = The tree to reorganize
	focus_node_p = The node whose parent was removed.

Description: Ensures that the tree's Red-Black properties are correct after a
             node is removed.
------------------------------------------------------------------------------*/
static void fix_rb_state(rbt_tree* tree_p, rbt_node* focus_node_p)
{
	rbt_node* opposite_node_l;
	
	while( focus_node_p->type == RED_NODE)
	{
		if (focus_node_p == focus_node_p->parent->left) 
		{
			opposite_node_l  = focus_node_p->parent->right;
			if (opposite_node_l->type == RED_NODE) 
			{
				opposite_node_l->type      = BLACK_NODE;
				focus_node_p->parent->type = RED_NODE;
				promote_right(focus_node_p->parent, tree_p->end);
				opposite_node_l            = focus_node_p->parent->right;
			}
			
			if ( (opposite_node_l->right->type == BLACK_NODE) && 
			     (opposite_node_l->left->type  == BLACK_NODE) )
			{ 
				opposite_node_l->type = RED_NODE;
				focus_node_p          = focus_node_p->parent;
			}
			else
			{
				if (opposite_node_l->right->type == BLACK_NODE)
				{
					opposite_node_l->left->type = BLACK_NODE;
					opposite_node_l->type       = RED_NODE;
					promote_left(opposite_node_l, tree_p->end);
					opposite_node_l             = focus_node_p->parent->right;
				}
				
				opposite_node_l->type        = focus_node_p->parent->type;
				focus_node_p->parent->type   = BLACK_NODE;
				opposite_node_l->right->type = BLACK_NODE;
				promote_right(focus_node_p->parent, tree_p->end);
				
				focus_node_p->type           = BLACK_NODE;
			}
		} 
		else
		{
			opposite_node_l = focus_node_p->parent->left;
			if (opposite_node_l->type == RED_NODE)
			{
				opposite_node_l->type      = BLACK_NODE;
				focus_node_p->parent->type = RED_NODE;
				promote_left(focus_node_p->parent, tree_p->end);
				opposite_node_l            = focus_node_p->parent->left;
			}
			
			if ( (opposite_node_l->right->type == BLACK_NODE) && 
			     (opposite_node_l->left->type  == BLACK_NODE) )
			{ 
				opposite_node_l->type = RED_NODE;
				focus_node_p          = focus_node_p->parent;
			}
			else
			{
				if (opposite_node_l->left->type == BLACK_NODE)
				{
					opposite_node_l->right->type = BLACK_NODE;
					opposite_node_l->type        = RED_NODE;
					promote_right(opposite_node_l, tree_p->end);
					opposite_node_l              = focus_node_p->parent->left;
				}
				
				opposite_node_l->type       = focus_node_p->parent->type;
				focus_node_p->parent->type  = BLACK_NODE;
				opposite_node_l->left->type = BLACK_NODE;
				promote_left(focus_node_p->parent, tree_p->end);
				
				focus_node_p->type          = BLACK_NODE;
			}
		}
	}
}


// =============================================================================
//
//  API Routines 
//
// =============================================================================


/*------------------------------------------------------------------------------
Function: RBT_Create 

Arguments:
	compare   = User supplied function to compare to keys. This is mandatory.
	free_item = User supplied procedure to release any resources
	            associated with a node's key and value. This can be null, if
	            there are no resources to release.
	walk_func = User supplied function to process a node's key and value. This
	            is called for each node in turn when the user calls RBT_Walk.
	            This can be null, in which case RBT_Walk does not 'walk' the
	            tree.

Returns: Address of a tree structure. Null if this fails.
------------------------------------------------------------------------------*/

rbt_tree* RBT_Create( int  (*compare)   (const void*,const void*),
			          void (*free_item) (const rbt_kv*),
			          int  (*walk_func) (const rbt_tree*, const int, const rbt_kv*, void *)
					)
{
	rbt_tree* new_tree_l;
	rbt_node* node_l;
	
	if (compare == 0)
		return 0;	// We must have a comparison function.
		
	/* Create and initialize a Tree struct */
	new_tree_l               = (rbt_tree*) malloc(sizeof(rbt_tree));
	if (new_tree_l == 0)
		return 0;	// No RAM left?
		
	new_tree_l->root         = (rbt_node*) malloc(sizeof(rbt_node));
	if (new_tree_l->root == 0)
		return 0;	// No RAM left?
		
	new_tree_l->end          = (rbt_node*) malloc(sizeof(rbt_node));
	if (new_tree_l->end == 0)
		return 0;	// No RAM left?
		
	new_tree_l->compare      = compare;
	new_tree_l->free_item    = free_item;
	new_tree_l->walk_func    = walk_func;
	
	/* Initialize the sentinel node */
	node_l             = new_tree_l->end;
	node_l->parent     = node_l;
	node_l->left       = node_l;
	node_l->right      = node_l;
	node_l->type       = BLACK_NODE;
	node_l->data.key   = 0;
	node_l->data.value = 0;
	
	/* Initialize the root node */
	node_l             = new_tree_l->root;
	node_l->parent     = new_tree_l->end;
	node_l->left       = new_tree_l->end;
	node_l->right      = new_tree_l->end;
	node_l->type       = BLACK_NODE;
	node_l->data.key   = 0;
	node_l->data.value = 0;
	
	return(new_tree_l);
}


/*------------------------------------------------------------------------------
Function: RBT_Insert 

Arguments:
	tree = The tree into which the new key/value is inserted.
	key  = The key of the new node
	value = The value associated with this key.

Returns: Zero if the insertion failed, otherwise the number of keys new stored
         in the tree.

Description: This creates a new node to store the key and value in, then
             adds the node to the tree, while keeping the tree balanced.
------------------------------------------------------------------------------*/
int RBT_Insert(rbt_tree* tree, rbt_kv* data)
{
	rbt_node*  new_node_l;
	rbt_node*  new_parent_l;
	rbt_node** new_link_l;
	rbt_node*  end;
	rbt_node*  grandparent_l;
	
	new_node_l = (rbt_node*)malloc(sizeof(rbt_node));
	if (new_node_l == 0) return 0;
	
	end = tree->end;	// Cache this for a bit of speed
	
	// Initialize the new node's fields.
	new_node_l->data  = *data;
	new_node_l->left  = end;
	new_node_l->right = end;
	new_node_l->type  = RED_NODE;
	
	// Walk the tree, looking for a spot to put the new node.
	new_parent_l = tree->root;
	new_link_l = &(new_parent_l->left);
	while( *new_link_l != end) 
	{
		new_parent_l = *new_link_l;
		new_link_l = (tree->compare( (new_parent_l->data).key, data->key) > 0 ?
						&(new_parent_l->left)
						:
						&(new_parent_l->right)
					);
	}
	// Add the new node, as a leaf, to the tree
	new_node_l->parent = new_parent_l;
	*new_link_l = new_node_l;
	
	// Now let's balance the branch it's on. */
	grandparent_l = new_node_l->parent->parent;
	while (new_node_l->parent->type == RED_NODE) 
	{
		if (new_node_l->parent == grandparent_l->left)
		{	// Parent's key < grandparent's key
			if (grandparent_l->right->type == RED_NODE)
			{
				grandparent_l->right->type = BLACK_NODE;
				new_node_l->parent->type   = BLACK_NODE;
				grandparent_l->type        = RED_NODE;
				new_node_l                 = grandparent_l;
			}
			else
			{
				if (new_node_l == new_node_l->parent->right)
				{
					new_node_l = new_node_l->parent;
					promote_right(new_node_l, end);
				}
				
				new_node_l->parent->type = BLACK_NODE;
				grandparent_l->type      = RED_NODE;
				promote_left(grandparent_l, end);
			} 
		} 
		else
		{   // Parent's key is >= grandparent's key
			if (grandparent_l->left->type == RED_NODE)
			{
				grandparent_l->left->type = BLACK_NODE;
				new_node_l->parent->type  = BLACK_NODE;
				grandparent_l->type       = RED_NODE;
				new_node_l                = grandparent_l;
			}
			else
			{
				if (new_node_l == new_node_l->parent->left)
				{
					new_node_l = new_node_l->parent;
					promote_left(new_node_l, end);
				}
				
				new_node_l->parent->type = BLACK_NODE;
				grandparent_l->type      = RED_NODE;
				promote_right(grandparent_l, end);
			} 
		}
	}
	
	tree->root->left->type = BLACK_NODE;
	tree->count += 1;
	return tree->count;
}

/*------------------------------------------------------------------------------
Procedure: RBT_Destroy 

Arguments:
	tree_p = The tree to destroy.

Description: This removes the entire tree from RAM. However, before doing so,
             it calls the user supplied free_item procedure for each node
             so that the calling application can release any resources held
             by any node.
------------------------------------------------------------------------------*/
void* RBT_Destroy(rbt_tree* tree_p) 
{
	if (tree_p->root->left != tree_p->end)
		destroy_branch(tree_p, tree_p->root->left);
		
	free(tree_p->root);
	free(tree_p->end);
	free(tree_p);
	
	return 0;
}


/*------------------------------------------------------------------------------
Function: RBT_Walk 

Arguments:
	tree_p = The tree being walked.
	walk_data_p = The data to be passed to each call of the user-supplied
	              walk_func, given when the tree was created.

Returns: 0 when the entire tree has been walked, non-zero when the walk was 
         prematurely stopped. This would happen when a call to walk_func had
         returned as non-zero value. That non-zero value is returned by this
         function to the original caller.

Description: Each key/value pair is presented to the user supplied walk_func in
        ascending key order.
------------------------------------------------------------------------------*/
int RBT_Walk(rbt_tree* tree_p, void *walk_data_p)
{
	int res_l;
	rbt_kv null_data_l;
	
	// Do nothing if there is no user supplied 'walk' processor.
	if (tree_p->walk_func == 0)
		return 0;
	
	// Signal that we are about to start the tree walk.
	res_l = tree_p->walk_func(tree_p, -1, &null_data_l, walk_data_p);
	
	// If the user didn't stop it, start walking the tree.
	if ( res_l == 0)
		res_l = walk_tree(tree_p, tree_p->root->left, walk_data_p);

	// Signal that the walking has completed.		
	if ( res_l == 0)
		res_l = tree_p->walk_func( tree_p, 1, &null_data_l, walk_data_p);	
		
	return res_l;
}

/*------------------------------------------------------------------------------
Function: RBT_Find 

Arguments:
	tree_p = The tree to search.
	result_p = A pointer to the structure that contains the key to search for,
	           and the place to return the value in.
Returns: 0 if not found. 1 if found. If found, then the result_p.value contains
         the pointer to the node's value.
         
Description: This looks for the value associated with the supplied key.
------------------------------------------------------------------------------*/
int RBT_Find(rbt_tree* tree_p, rbt_kv* result_p)
{
	rbt_node* node_l;
  
	node_l = find_eq(tree_p, result_p->key);
	if (node_l == tree_p->end)
		return 0;

	result_p->value = (node_l->data).value;
	return 1;
}

/*------------------------------------------------------------------------------
Function: RBT_Find_Next

Arguments:
	tree_p = The tree to search.
	result_p = A pointer to the structure that contains the key to search for,
	           and the place to return the matching node's data in.
Returns: 0 if not found. 1 if found. If found, then the result_p structure
        will contain the matching node's key and value.
         
Description: This looks for the data associated with the first key that 
             is greater than the supplied key. When found, this function returns
             the nodes key and value in the result_p structure.
------------------------------------------------------------------------------*/
int RBT_Find_Next(rbt_tree* tree_p, rbt_kv* data_p)
{
	rbt_node* current_node_l;
	
	current_node_l = find_ge(tree_p, data_p);
	if (current_node_l == tree_p->end)  	
		return 0;
	
	// If the node found actually equals the key, then get the next node.
	if (tree_p->compare(data_p->key, current_node_l->data.key) == 0)
		current_node_l = next_key(tree_p, current_node_l);
		
	if (current_node_l == tree_p->end)  	
		return 0;
		
	*data_p = current_node_l->data;	
	return 1;
}

/*------------------------------------------------------------------------------
Function: RBT_Find_Prev

Arguments:
	tree_p = The tree to search.
	result_p = A pointer to the structure that contains the key to search for,
	           and the place to return the matching node's data in.
Returns: 0 if not found. 1 if found. If found, then the result_p structure
        will contain the matching node's key and value.
         
Description: This looks for the data associated with the last key that 
             is less than the supplied key. When found, this function returns
             the nodes key and value in the result_p structure.
------------------------------------------------------------------------------*/
int RBT_Find_Prev(rbt_tree* tree_p, rbt_kv* data_p) 
{
	rbt_node* current_node_l;
	
	current_node_l = find_le(tree_p, data_p);
	if (current_node_l == tree_p->end)  	
		return 0;
	
	// If the node found actually equals the key, then get the previous node.
	if (tree_p->compare(data_p->key, current_node_l->data.key) == 0)
		current_node_l = prev_key(tree_p, current_node_l);
		
	if (current_node_l == tree_p->end)  	
		return 0;
		
	*data_p = current_node_l->data;	
	return 1;
}

/*------------------------------------------------------------------------------
Function: RBT_Find_First

Arguments:
	tree_p = The tree to search.
	result_p = A pointer to the structure that will contain the first node's
	           data.
Returns: 0 if not found. 1 if found. If found, then the result_p structure
        will contain the first node's key and value.
         
Description: This looks for the first node in the tree.
------------------------------------------------------------------------------*/
int RBT_Find_First(rbt_tree* tree_p, rbt_kv* data_p) {
	rbt_node* current_node_l;
	rbt_node* end;
	
	current_node_l = tree_p->root->left;
	end = tree_p->end;
	
	if (current_node_l == end)
		return 0;
		
	do
	{
		current_node_l = current_node_l->left;

	} while (current_node_l != end);

	*data_p = current_node_l->data;	
	return 1;
}

/*------------------------------------------------------------------------------
Function: RBT_Find_Last

Arguments:
	tree_p = The tree to search.
	result_p = A pointer to the structure that will contain the last node's
	           data.
Returns: 0 if not found. 1 if found. If found, then the result_p structure
        will contain the last node's key and value.
         
Description: This looks for the last node in the tree.
------------------------------------------------------------------------------*/
int RBT_Find_Last(rbt_tree* tree_p, rbt_kv* data_p) {
	rbt_node* current_node_l;
	rbt_node* end;
	
	current_node_l = tree_p->root->left;
	end = tree_p->end;
	
	if (current_node_l == end)
		return 0;
		
	do
	{
		current_node_l = current_node_l->right;

	} while (current_node_l != end);

	*data_p = current_node_l->data;	
	return 1;
}

/*------------------------------------------------------------------------------
Procedure: RBT_Delete 

Argments:
	tree_p = The tree containing the node to delete.
	data_p = Pointer to the structure which contains the key of the node to
	         delete.
Description: If the key's node exists, it is removed from the tree. However, 
             before doing so, the user supplied free_item function is called
             to allow that application to release any resources held by the node.
------------------------------------------------------------------------------*/
void RBT_Delete(rbt_tree* tree, rbt_kv* data)
{
	rbt_node* deleted_node_l;
	rbt_node* current_node_l;
	rbt_node* end;
	rbt_node* root;
	rbt_node* parent;
	rbt_node* fixup_child;
	
	end = tree->end;
	root  = tree->root;
	deleted_node_l = find_eq(tree, data->key);
	if (deleted_node_l == end)
		return;

	parent = deleted_node_l->parent;
	if (deleted_node_l->left == end)
	{		
		if (deleted_node_l->right == end)
		{
			// The node to delete has no children.
			if (parent->left == deleted_node_l)
			{
				parent->left = end;
				fixup_child = parent->right;
			}
			else
			{
				parent->right = end;
				fixup_child = parent->left;
			}
		}
		else
		{	// The node to delete only has right-hand children
			deleted_node_l->right->parent = parent;
			parent->right = deleted_node_l->right;
			fixup_child = parent->right;
		}
	}
	else
	{
		if (deleted_node_l->right == end)
		{	// The node to delete only has left-hand children
			deleted_node_l->left->parent = parent;
			parent->left = deleted_node_l->left;
			fixup_child = parent->left;
		}
		else
		{
			// The node to delete has both right and left children.
			if (parent->left == deleted_node_l)
			{
				deleted_node_l->left->parent = parent;
				parent->left = deleted_node_l->left;
				fixup_child = deleted_node_l->right;
				
				current_node_l = deleted_node_l->left;
				while (current_node_l->right != end)
				{
					current_node_l = current_node_l->right;
			
				};
				current_node_l->right = fixup_child;
			}
			else
			{
				deleted_node_l->right->parent = parent;
				parent->right = deleted_node_l->right;
				fixup_child = deleted_node_l->left;
				current_node_l = deleted_node_l->right;
				while (current_node_l->left != end)
				{
					current_node_l = current_node_l->left;
			
				};
				current_node_l->left = fixup_child;
			}
			
			fixup_child->parent = current_node_l;
		}
		
	}

	// Re-balance the tree.
	fix_rb_state(tree, fixup_child);
	
	// Allow the application to free up resources.
	if (tree->free_item != 0)
		tree->free_item(&(deleted_node_l->data)); // Don't care if user changes node.
	
	// Release the node's RAM.
	free(deleted_node_l); 
	(tree->count)--;
	return;	
}


/*------------------------------------------------------------------------------
Procedure: RBT_Length

Argments:
	tree_p = The tree whose length you need.

Description: Returns the number of nodes in the tree.
------------------------------------------------------------------------------*/
int RBT_Length(rbt_tree* tree)
{
	return tree->count;
}


void RBT_Debug(rbt_tree* tree_p)
{
	printf("\n======== TREE ===========\n");
    printf("t=%08x ", tree_p);
	printf("e=%08x ", tree_p->end);
	printf("r=%08x ", tree_p->root);
	printf("f=%08x ", tree_p->root->left);
	printf("c=%d\n",  tree_p->count);
	debug_tree(tree_p, tree_p->root->left);
}
