include unittest.e
include sets.e

set s,s1,s1a
s={-1,3,5,17,"abc","abcd","acb"}
sequence seq
seq={3,"acb",3,"abc"}
s1={-2,17,"abcd"}  s1a={3,17,"abcd"}

test_equal("sequence_to_set()",{3,"abc","acb"},sequence_to_set(seq))
test_equal("cardinal()",7,cardinal(s))

test_equal("belongs_to(): present element",1,belongs_to(5,s))
test_equal("belongs_to(): absent element",0,belongs_to(0,s))

test_equal("add_to(): present element", s,add_to(3,s))
test_equal("add_to(): absent element",{-1,0,3,5,17,"abc","abcd","acb"},add_to(0,s))

test_equal("remove_from(): present element", {-1,3,5,17,"abc","acb"},remove_from("abcd",s))
test_equal("remove_from(): absent element",s,remove_from(1,s))

test_equal("is_inside(): not a subset",0,is_inside(s1,s))
test_equal("is_inside(): subset",1,is_inside(s1a,s))    --???

test_equal("embedding(): success",{2,4,6},embedding(s1a,s)) -- ???
test_equal("embedding(): failure",0,embedding(s1,s))

test_equal("embed_union()", {2,3,4},embed_union({2,5,7},{1,5,7,9}))

test_equal("subsets()",{{},{-2},{17},{"abcd"},{-2,17},{-2,"abcd"},{17,"abcd"},s1},subsets(s1))

test_equal("intersection(): no inclusion",{17,"abcd"},intersection(s,s1))
test_equal("intersection(): inclusion",s1a,intersection(s,s1a))
test_equal("intersection(): disjoint",{},intersection({0,1},{2}))

test_equal("union(): not embedded",{-2,-1,3,5,17,"abc","abcd","acb"},union(s,s1))
test_equal("union(): embedded",s,union(s,s1a))

test_equal("delta(): no inclusion",{-2,-1,3,5,"abc","acb"},delta(s,s1))
test_equal("delta(): with inclusion",{-1,5,"abc","acb"},delta(s,s1a))

test_equal("difference()",{-1,3,5,"abc","acb"},difference(s,s1))

map f
f={2,1,3,3,1,2,1,7,3}

test_equal("product()",{{1,0},{1,1},{1,4},{3,0},{3,1},{3,4}},product({1,3},{0,1,4}))

test_equal("define_map()",f,define_map({17,-2,"abcd","abcd",-2,17,-2},s1))

test_equal("sequences_to_map()",f,
      sequences_to_map({-1,3,17,"abc",5,"abcd","acb"},{17,-2,"abcd",-2,"abcd",17,-2},0))

test_equal("direct_map()",{-2,-2,-2},direct_map(f,s,{3,"abc",3},s1))

test_equal("image()","abcd",image(f,5,s,s1))

test_equal("range()",s1,range(f,s1))

test_equal("product_map()",{9,8,10,10,8,9,8,2,1,3,3,1,2,1,16,15,17
,17,15,16,15,16,15,17,17,15,16,15,2,1,3,3,1,2,1,9,8,10,10,8,9,8,2,1,3,3,1,2,1,49,9}
,product_map(f,f))

test_equal("amalgamated_sum()",{{-2,-2},{17,17},{"abcd","abcd"}},amalgamated_sum(s1,s1,s,f,f))

test_equal("fiber_over()",{{{3,"abc","acb"},{-1,"abcd"},{5,17}},{1,2,3}},fiber_over(f,s,s1))

set S,S0
S={0,1,2,3,4,5,6,7,8,9} S0={0,1,2,3,4}
map r2,r5
r2={1,2,1,2,1,2,1,2,1,2,10,5}
r5={1,2,3,4,5,1,2,3,4,5,10,5}

test_equal("fiber_product()",
{{0,0}, {0,5}, {2,0}, {2,5}, {4,0}, {4,5}, {6,0}, {6,5}, {8,0}, {8,5}, {1,1}, {1,6}, {3,1},
  {3,6},  {5,1},  {5,6},  {7,1},  {7,6},  {9,1},  {9,6}}
,fiber_product(S,S,S0,r2,r5))

test_equal("reverse_map()",{1,3,5,7,9},reverse_map(r2,S,{1},S0) )

map r25
r25=restrict(r2,S,S0)

test_equal("restrict()",{1,2,1,2,1,5,5},restrict(r2,S,S0))

test_equal("change_target()",{2,4,2,4,2,4,2,4,2,4,10,5},change_target(r2,{0,1},{-1.5,0,0.5,1,1.5}))

set s11,s12,s21,s22
s11={2,3,5,7,11,13,17,19} s21={7,13,19,23,29}
s12={-1,0,1,4} s22={-2,0,1,2,6}
map f1,f2
f1={2,1,3,3,2,3,1,2,8,4} f2={3,3,2,4,5,5,5}
f=combine_maps(f1,s11,s12,f2,s21,s22)

test_equal("combine_maps()",{3,2,4,4,3,4,2,3,5,7,10,7},combine_maps(f1,s11,s12,f2,s21,s22))

test_equal("compose_maps()",{1,2,1,2,1,5,5},compose_map(r25,r5))

test_equal("diagram_commutes()",0,diagram_commutes(r2,r5,r5,r25))

test_equal("is_surjective()",0,is_surjective(f))

test_equal("is_surjective()",0,is_injective(f))

test_equal("isèsurjective()",0,is_bijective(f))

test_equal("section()",{3,7,8,6,9,4,10,3,5,7,7,10},section(f))

operation mul5
mul5={{{1,1,1,1,1},{1,2,3,4,5},{1,3,5,2,4},{1,4,2,5,3},{1,5,4,3,2}},{5,5,5}}
sequence s0,s00
s0={0,1,2,3,4}
s00=s0   
for i=1 to 5 do s00[i]=remainder(s0[i]*s0,5)+1 s00[i]&={5,5} end for

test_equal("define_operation()",mul5,define_operation(s00))

test_equal("is_associative()",1,is_associative(mul5))

test_equal("is_symmetric()",1,is_symmetric(mul5))

test_equal("has_left_unit()",2,has_left_unit(mul5))

test_equal("is_left_unit()",0,is_left_unit(3,mul5))

test_equal("all_left_units()",{2},all_left_units(mul5))

operation plus01
plus01={{{1,2},{2,3},{3,4},{4,5},{5,1}},{5,2,5}}

test_equal("has_right_unit()",1,has_right_unit(plus01))

test_equal("is_right_unit()",0,is_right_unit(2,plus01))

test_equal("all_right_units()",{1},all_right_units(plus01))

test_equal("has_unit()",0,has_unit(plus01))

operation sum sum={{{1,2,3},{2,3,1},{3,1,2}},{3,3,3}}
operation product product={{{1,1,1},{1,2,3},{1,3,2}},{3,3,3}}

test_equal("distributes_left()",1,distributes_left(product,sum,0))

test_equal("distributes_right()",1,distributes_right(product,sum,0))

test_equal("distributes_over()",3,distributes_over(product,sum,0))

test_false("belongs_to() empty set", belongs_to( 1, {} ) )

test_report()

