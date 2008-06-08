-- Author: Christian Cuvier <oedoc@free.fr>
-- Intro: The sets.e module defines a type for sets and provides basic tools for handling them.
-- Other modules may be built upon them, for instance graph handling or simplicial topology, finite groups etc...
-- Platform: GEN
-- Notes:
--   A set is an ordered sequence in ascending order, not more, not less
--   A map from s1 to s2 is a sequence the length of s1 whose elements are indexes into s2,
--    followed by {length(s1),length(s2)}.
--   An operation of ExF to G is a two dimensional sequence of elements of G, indexed ny
--    ExF, and the triple {card(E),card(F),card(G)}.

include machine.e

procedure report_error(sequence s)
-- Description: Prints an error message on stderr and abort(1)s.
-- Takes: {routine name,error message}; both are strings.
    crash("Error in routine %s in module %s: %s",{s[1],"sets.e",s[2]})
end procedure

global type set(sequence s)
    object x,y

    if length(s)<2 then
        return 1
    end if
    x=s[1]
    for i=2 to length(s) do
        y=s[i]
        if compare(y,x)<1 then
            return 0
        end if
        x=y
    end for
    return 1
end type

function bfind_(object x,sequence s,integer startpoint,integer endpoint)
    integer r,c

    if endpoint>length(s) then
        endpoint=length(s)
    end if
    if startpoint<1 then
        startpoint=1
    end if
    c=compare(x,s[startpoint])
    if c=1 then
        c=compare(x,s[endpoint])
        if c=-1 then
            while endpoint-startpoint>1 do
                r=floor((endpoint+startpoint)/2)
                c=compare(x,s[r])
                if c=-1 then
                    endpoint=r
                elsif c=0 then
                    return r
                else
                    startpoint=r
                end if
            end while
            return -endpoint
        elsif c=0 then
            return endpoint
        else
            return -1-endpoint
        end if
    elsif c=0 then
        return startpoint
    else
        return -startpoint
    end if
end function

global function bfind(object x,set s,object bounds)
    integer startpoint,endpoint

    -- extract search bounds
    bounds=floor(bounds)
    if sequence(bounds) then
        if not integer(bounds[1]) or not integer(bounds[2]) then
            report_error({"bfind","Start and end points were specified, but both must be atoms."})
        end if
        startpoint=bounds[1]
        endpoint=bounds[2]
    else
        startpoint=bounds
        endpoint=length(s)
    end if
    if endpoint<=0 or endpoint<startpoint then
        return 0
    end if
    return bfind_(x,s,startpoint,endpoint)
end function

include sort.e
include sequence.e

global function sequence_to_set(sequence s)
    sequence result
    integer k,ls

    ls=length(s)
    if ls<2 then
        return s
    end if
    result=sort(s)
    k=0
    for i=1 to ls-1 do
        if compare(result[i],result[i+1])=0 then
            k=i
            exit
        end if
    end for
    if k=0 then
        return result
    end if
    for i=k+2 to ls do
        if compare(result[i],result[k])=1 then
            k+=1
            result[k]=result[i]
        end if
    end for
    return result[1..k]
end function

global function cardinal(set s)
    return length(s)
end function

global function belongs_to(object x,set s)
    return bfind_(x,s,1,length(s))>0
end function

function add_to_(object x,sequence s)
    integer p

    if not length(s) then
        return {x}
    end if
    p=bfind_(x,s,1,length(s))
    if p<0 then
        return insert(s,x,-p)
    end if
    return s
end function

global function add_to(object x,set s)
    return add_to_(x,s)
end function

function remove_from_(object x,sequence s)
    integer p

    p=bfind_(x,s,1,length(s))
    if p>0 then
        return remove(s,p)
    else
        return s
    end if
end function

global function remove_from(object x,set s)
    return remove_from_(x,s)
end function

function iota(integer count)
-- Returns: {1,2,...,count}, or "" if count is not greater than 0.
    sequence result
    if count<=0 then
        return ""
    end if
    result=repeat(1,count)
    for i=2 to count do
        result[i]=i
    end for
    return result
end function

function is_inside_(sequence s1,sequence s2,integer mode)
    integer p,q,ls1
    sequence result

    q=length(s2)
    ls1=length(s1)
    if q>ls1 then
        if ls1>1 then
            result=repeat(0,ls1)
            p=1
            for i=1 to ls1/2 do
                p=bfind_(s1[i],s2,p,q)
                if p<0 then
                    return 0
                end if
                result[i]=p
                p+=1
                q=bfind_(s1[$+1-i],s2,p,q)
                if q<0 then
                    return 0
                end if
                result[$+1-i]=q
                q-=1
            end for
            if and_bits(ls1,1) then
                p=bfind_(s1[(ls1+1)/2],s2,p,q)
                if p<=0 then
                    return 0
                end if
                result[(ls1+1)/2]=p
            end if
            if mode then
                return result
            else
                return 1
            end if
        elsif ls1=1 then
            p=find(s1[1],s2)
            if p=0 then
                return 0
            elsif mode then
                return {p}
            else
                return 1
            end if
        else
            if mode then
                return {}
            else
                return 1
            end if
        end if
    elsif q<ls1 then
        return 0
    else
        if mode then
            return iota(ls1)
        else
            return not compare(s1,s2)
        end if
    end if
end function

global function is_inside(set s1,set s2)
    return is_inside_(s1,s2,0)
end function

global function embedding(set s1,set s2)
    return is_inside_(s1,s2,1)
end function

function abs(integer p)
-- Description: Returns the absolute value of p.
    if p>0 then
        return p
    else
        return -p
    end if
end function

function embed_union_(sequence s1,sequence s2)
-- Description: Wrapped by embed_union so as to avoid some type checks.
    integer p,q,q_1,ls1
    sequence result,temp

    q=length(s2)
    if q>1 then
        ls1=length(s1)
        if ls1>1 then
            if compare(s1[$],s2[1])=-1 then
                return iota(length(s1))
            elsif compare(s2[$],s1[1])=-1 then
                return iota(length(s1))+q
            end if
            temp=s1
            p=1
            for i=1 to length(s1)/2 do
                p=bfind_(s1[i],s2,p,q)
                temp[i]=p
                if p>0 then
                    p+=1
                else
                    p=-p-1
                end if
                q=bfind_(s1[$+1-i],s2,p,q)
                temp[$+1-i]=q
                if q>0 then
                    q-=1
                else
                    q=-q
                end if
            end for
            if and_bits(ls1,1) then
                temp[(ls1/2)+1]=bfind_(s1[(ls1/2)+1],s2,p,q)
            end if
            result=temp
            if result[1]<0 then
                result[1]*=-1
            end if
            q_1=temp[1]
            for i=2 to length(result) do
                q=temp[i]
                result[i]=abs(q)-abs(q_1)+result[i-1]+(q_1<0)
                q_1=q
            end for
            return result
        elsif length(s1)=1 then
            q=find(s1[1],s2)
            if q>0 then
                return {q}
            else
                return {-q}
            end if
        else
            return ""
        end if
    elsif q=0 then
        return iota(length(s1))
    else
        q=find(s2[1],s1)
        if q>0 then
            return iota(length(s1))
        else
            result=iota(length(s1))
            result[-q..$]+=1
            return result
        end if
    end if
end function

global function embed_union(set s1,set s2)
    return embed_union_(s1,s2)
end function

global function subsets(set s)
    integer p,k,L
    sequence result,s1,s2,x

    L=length(s)
    if L<=3 then
        if L=0 then
            return {{}}
        elsif L=1 then
            return {{},s}
        elsif L=2 then
            return {{},{s[1]},{s[2]},s}
        else
            return {{},{s[1]},{s[2]},{s[3]},s[1..2],{s[1],s[3]},s[2..3],s}
        end if
    else
        result=repeat(0,power(2,L))
        p=floor(L/2)
        s1=subsets(s[1..p])
        s2=subsets(s[p+1..$])
        k=1
        for i=1 to length(s1) do
            x=s1[i]
            for j=1 to length(s2) do
                result[k]=x&s2[j]
                k+=1
            end for
        end for
        return result
    end if
end function

-- Basic set-theoretic operations.

function intersection_(sequence s1,sequence s2)
-- Description: Wrapped by intersection() so as to avoid some type checks.
    integer k1,k2,k,c,ls1,ls2
    sequence result

    ls2=length(s2)
    result=s1
    if ls2=0 then
        return ""
    elsif ls2=1 then
        if belongs_to(s2[1],s1) then
            return s2
        else
            return ""
        end if
    end if
    ls1=length(s1)
    k1=1
    k2=1
    k=1
    c=compare(s1[1],s2[1])
    while k1<=ls1 and k2<=ls2 do
        if c=0 then
            result[k]=s1[k1]
            k+=1
            k1+=1
            k2+=1
            if k1>ls1 or k2>ls2 then
                return result[1..k-1]
            else
                c=compare(s1[k1],s2[k2])
            end if
        elsif c=1 then
            k2=bfind_(s1[k1],s2,k2,length(s2))
            if k2>=0 then
                c=0
            else
                k2=-k2
                c=-1
            end if
        else
            k1=bfind_(s2[k2],s1,k1,length(s1))
            if k1>=0 then
                c=0
            else
                k1=-k1
                c=1
            end if
        end if
    end while
    return result[1..k-1]
end function

global function intersection(set s1,set s2)
    return intersection_(s1,s2)
end function

function union_(sequence s1,sequence s2,integer ls1,integer ls2,integer mode)
-- Description: Wrapped by union() and delta() to avoid type checking.
-- mode=1 for union and 0 for delta (union=intersection+delta)
    integer k1,k2,k,c,k0
    sequence result

    result=s1&s2
    k1=1
    k2=1
    k=1
    c=compare(s1[1],s2[1])
    while k1<=ls1 and k2<=ls2 do
        if c=0 then
            if mode then
                result[k]=s1[k1]
                k+=1
            end if
            k1+=1
            k2+=1
            if k1>ls1 or k2>ls2 then
                exit
            else
                c=compare(s1[k1],s2[k2])
            end if
        elsif c=1 then
            k0=bfind_(s1[k1],s2,k2,length(s2))
            if k0>=0 then
                c=0
            else
                k0=-k0
                c=-1
            end if
            result[k..k-k2+k0-1]=s2[k2..k0-1]
            k+=(k0-k2)
            k2=k0
        else
            k0=bfind_(s2[k2],s1,k1,length(s1))
            if k0>=0 then
                c=0
            else
                k0=-k0
                c=1
            end if
            result[k..k-k1+k0-1]=s1[k1..k0-1]
            k+=(k0-k1)
            k1=k0
        end if
    end while
    result=result[1..k-1]
    if k1<=ls1 then
        return result & s1[k1..$]
    elsif k2<=ls2 then
        return result & s2[k2..$]
    else
        return result
    end if
end function

function union1(sequence s1,sequence s2)
    integer ls1,ls2

    ls1=length(s1)
    ls2=length(s2)
    if ls2=0 then
        return s1
    elsif ls1=0 then
        return s2
    elsif ls1=1 then
        return add_to_(s1[1],s2)
    elsif ls2=1 then
        return add_to_(s2[1],s1)
    end if
    return union_(s1,s2,ls1,ls2,1)
end function

global function union(set s1,set s2)
    return union1(s1,s2)
end function

global function delta(set s1,set s2)
    integer ls1,ls2

    ls1=length(s1)
    ls2=length(s2)
    if ls2=0 then
        return s1
    elsif ls1=0 then
        return s2
    elsif ls1=1 then
        return remove_from_(s1[1],s2)
    elsif ls2=1 then
        return remove_from_(s2[1],s1)
    end if
    return union_(s1,s2,ls1,ls2,0)
end function

global function difference(set s1,set s2)
    integer k1,k2,k,c,ls1,ls2,k0
    sequence result
    ls1=length(s1)
    ls2=length(s2)
    if ls2=0 then
        return s1
    elsif ls1=0 then
        return ""
    elsif ls2=1 then
        return remove_from_(s2[1],s1)
    elsif ls1=1 then
        if bfind_(s1[1],s2,1,length(s2))>0 then
            return ""
        else
            return s1
        end if
    end if
    result=s1&s2
    k1=1
    k2=1
    k=1
    c=compare(s1[1],s2[1])
    while k1<=ls1 and k2<=ls2 do
        if c=0 then
            k1+=1
            k2+=1
            if k1>ls1 or k2>ls2 then
                exit
            else
                c=compare(s1[k1],s2[k2])
            end if
        elsif c=1 then
            k2=bfind_(s1[k1],s2,k2,length(s2))
            if k2>=0 then
                c=0
            else
                k2=-k2
                c=-1
            end if
        else
            k0=bfind_(s2[k2],s1,k1,length(s1))
            if k0>=0 then
                c=0
            else
                k0=-k0
                c=1
            end if
            result[k..k-k1+k0-1]=s1[k1..k0-1]
            k+=(k0-k1)
            k1=k0
        end if
    end while
    result=result[1..k-1]
    if k1<=ls1 then
        return result & s1[k1..$]
    else
        return result
    end if
end function

function product_(sequence s1,sequence s2)
-- Description: Wrapped by product() to skip type checking
    sequence result
    integer ls1,ls2,k
    object x

    ls1=length(s1)
    ls2=length(s2)
    if not (ls1 and ls2) then
        return ""
    end if
    k=1
    result=repeat(0,ls1*ls2)
    for i=1 to ls1 do
        x={s1[i],0}
        for j=1 to ls2 do
            x[2]=s2[j]
            result[k]=x
            k+=1
        end for
    end for
    return result
end function

global function product(set s1,set s2)
    return product_(s1,s2)
end function

function bounded_integer(object x,integer lbound,integer ubound)
-- Description: Returns 0 for a non integer or an out of bounds integer, else 1.
-- Takes: object to test; lower allowable bound; upper allowable bound.
-- Returns: 1 if x is an integer between lbound and ubound both included, else 0.
-- See also: map, is_left_unit, is_right_unit
    if not integer(x) then
        return 0
    else
        return x>=lbound and x<=ubound
    end if
end function

global type set_map(sequence s)
    object p,q

    q=s[$-1]
    p=s[$]
	if length(s)<=2 or q!=length(s)-2 then
		return 0
    elsif not integer(p) or p<0 then
    	return 0
    else
        for i=1 to q do
            if not bounded_integer(s[i],1,p) then
                return 0
            end if
        end for
    end if
    return 1
end type

global function define_map(sequence mapping,set target)
    sequence result
    integer lt

    lt=length(target)
    result=mapping&length(mapping)&lt
    for i=1 to length(mapping) do
        result[i]=bfind_(mapping[i],target,1,lt)
    end for
    return result
end function

global function sequences_to_map(sequence mapped,sequence mapped_to,integer mode)
    sequence result
    set sorted,sorted_to
    integer ls,lm_to,lm

    lm=length(mapped)
    lm_to=length(mapped_to)
    if lm>lm_to then
        mapped=mapped[1..lm_to]
    end if
    sorted=sequence_to_set(mapped)
    sorted_to=sequence_to_set(mapped_to)
    ls=length(sorted)
    result=repeat(0,ls)&ls&length(sorted_to)
    for i=1 to lm do
        result[find(mapped[i],sorted)]=find(mapped_to[i],sorted_to)
    end for
    if mode then
        return {result,sorted,sorted_to}
    else
        return result
    end if
end function

global function image(set_map f,object x,set s1,set s2)
    integer p
    if f[$]>length(s2) then
        report_error({"image","The set_map range would not fit into the supplied target set."})
    end if
    p=bfind_(x,s1,1,length(s1))
    if p<0 or p>f[$-1] then
        report_error({"image","The set_map is not defined for the supplied argument."})
    else
        return s2[f[p]]
    end if
end function

global function range(set_map f,set s)
    sequence result

    result=sequence_to_set(f[1..$-2])
    for i=1 to length(result) do
        result[i]=s[result[i]]
    end for
    return result
end function

global function direct_map(set_map f,set s1,sequence s0,set s2)
    sequence result
    integer k,p,ls1

    ls1=length(s1)
    if f[$-1]>ls1 or f[$]>length(s2) then
        report_error({"direct_map","The supplied set_map cannot map the source set intio the target set."})
    end if
    k=1
    result=s0
    for i=1 to length(s0) do
        p=bfind_(s0[i],s1,1,ls1)
        if p>0 then
            result[k]=s2[f[p]]
            k+=1
        end if
    end for
    return result[1..k-1]
end function

global function product_map(set_map f1,set_map f2)
    sequence result,s
    integer k ,p
    k=1
    p=f2[$-1]
    result=repeat(0,f1[$-1]*p)&f1[$-1]*p&f1[$]*f2[$]
    s=f2[1..$-2]-p
    for i=1 to f1[$-1] do
        result[k..k+p-1]=s+p*f1[i]
        k+=p
    end for
    return result
end function

global function amalgamated_sum(set s1,set s2,set s0,set_map f01,set_map f02)
    sequence result

    result=s0
    for i=1 to length(s0) do
        result[i]={s1[f01[i]],s2[f02[i]]}
    end for
    return sequence_to_set(result)
end function

function fiber_over_(sequence f,sequence s1,sequence s2)
    sequence fibers,result
    integer p
    if f[$-1]!=length(s1) or f[$]!=length(s2) then
        return ""
    end if
    fibers=sequence_to_set(f[1..$-2])
    result=repeat({},length(fibers))
    for i=1 to length(s1) do
        p=find(f[i],fibers)
        result[p]=append(result[p],s1[i])
    end for
    return {result,fibers}
end function

global function fiber_over(set_map f,set s1,set s2)
    return fiber_over_(f,s1,s2)
end function

global function fiber_product(set s1,set s2,set s0,set_map f10,set_map f20)
    sequence result,x1,x2,x0
    x1=fiber_over_(f10,s1,s0)
    x2=fiber_over_(f20,s2,s0)
    x0=intersection_(x1[2],x2[2])
    result={}
    for i=1 to length(x0) do
        result&=product_(x1[1][find(x0[i],x1[2])],x2[1][find(x0[i],x2[2])])
    end for
    return result
end function

global function reverse_map(set_map f,set s1,sequence s0,set s2)
    sequence x,done,result
    integer p
    x=fiber_over_(f,s1,s2)
    result=""
    done=repeat(0,length(x[2]))
    for i=1 to length(s0) do
        p=find(bfind_(s0[i],s1,1,length(s1)),x[2])
        if p and not done[p] then
            done[p]=1
            result=union1(result,x[1][p])
        end if
    end for
    return result
end function

global function restrict(set_map f,set s1,set s0)
    sequence result
    integer p,k
    result=s0
    p=1
    k=0
    for i=1 to length(s0) do
        p=bfind_(s0[i],s1,p,length(s1))
        if p>0 then
            k+=1
            result[k]=f[p]
        end if
    end for
    return result[1..k]&k&f[$]
end function

function change_target_(sequence f,sequence s1,sequence s2)
-- Description: Wrapped by change_target() to avoid some type checks.
    sequence result,done
    integer p,fi
    result=f
    done=repeat(0,f[$])
    for i=1 to f[$-1] do
        fi=f[i]
        p=done[fi]
        if p then
            result[i]=p
        else
            p=bfind_(s1[fi],s2,1,length(s2))
            if p<0 then
                report_error({"change_target","set_map range not included in new target set."})
            else
                result[i]=p
                done[fi]=p
            end if
        end if
    end for
    result[$]=length(s2)
    return result
end function

global function change_target(set_map f,set s1,set s2)
    return change_target_(f,s1,s2)
end function

global function combine_maps(set_map f1,set s11,set s12,set_map f2,set s21,set s22)
    integer len_result,p
    set s
    sequence result

    s=union1(s12,s22)
    f1=change_target_(f1,s12,s)
    f2=change_target_(f2,s22,s)
    len_result=length(s11)+length(s21)
    result=repeat(0,len_result)
    s=embed_union_(s11,s21)
    for i=1 to length(s) do
        result[s[i]]=f1[i]
    end for
    s=embed_union_(s21,s11)
    for i=1 to length(s) do
        p=s[i]
        if result[p] then
            if result[p]!=f2[i] then
                report_error({"combine_maps",
                  "Maps disagree at some point where they are both definde."})
            else
                len_result-=1
            end if
        else
            result[p]=f2[i]
        end if
    end for
    return result[1..len_result]&len_result&f1[$]
end function

function compose_map_(sequence f2,sequence f1)
-- Description: Wrapped by compose_map(), so as to avoid some type checks.
    sequence result
    if find(0,f1[1..$-2]<=f2[$]) then
        report_error({"compose_maps","Range of initial set_map exceeds definition set of final set_map."})
    end if
    result=f1
    for i=1 to f1[$-1] do
        result[i]=f2[f1[i]]
    end for
    result[$]=f2[$]
    return result
end function

global function compose_map(set_map f2,set_map f1)
    return compose_map_(f1,f2)
end function

global function diagram_commutes(sequence f12a,sequence f12b,sequence f2a3,sequence f2b3)
    return not compare(compose_map_(f2a3,f12a),compose_map_(f2b3,f12b))
end function

global function is_injective(set_map f)
    sequence s
    integer p
    object x,y

    if f[$-1]>f[$] then
        return 0
    end if
    p=length(f)-2
    s=sort(f[1..p])
    x=s[1]
    for i=2 to p do
        y=s[i]
        if y=x then
            return 0
        end if
        x=y
    end for
    return 1
end function

function is_surjective_(sequence f)
    if f[$-1]<f[$] then
        return 0
    else
        return equal(sequence_to_set(f[1..$-2]),iota(f[$]))
    end if
end function

global function is_surjective(set_map f)
    return is_surjective_(f)
end function

global function is_bijective(set_map f)
    if f[$]!=f[$-1] then
        return 0
    else
        return is_surjective_(f)
    end if
end function

global function section(set_map f)
    sequence result
    integer k,p
    result=f
    k=0
    p=f[$-1]
    for i=1 to p do
        result[f[i]]=i
    end for
    for i=1 to p do
        if result[i] and k then
           result[k]=result[i]
           k+=1
        elsif result[i]=0 and k=0 then
           k=i
        end if
    end for
    if k then
        result[k]=k-1
        result=result[1..k]&p
    else
        result[$]=p
        result[$-1]=f[$]
    end if
    return result
end function

global type set_operation(sequence s)
    sequence u
    if length(s)!=2 or length(s[2])!=3 or length(s[1])!=s[2][1] then
        return 0
    else
        u=s[2][2..3]
        for i=1 to length(s[1]) do
            if not set_map(s[1][i]&u) then
                return 0
            end if
        end for
        return 1
    end if
end type

global function define_operation(sequence left_actions)
    integer size_left,size_right
    set_map f

    f=left_actions[1]
    size_left=f[$-1]
    size_right=f[$]
    left_actions[1]=f[1..$-2]
    for i=2 to length(left_actions) do
        f=left_actions[i]
        if f[$-1]!=size_left then
            report_error({"define_operation","All specified actions do not map to the same result set."})
        end if
        if f[$]>size_right then
            size_right=f[$]
        end if
        left_actions[i]=f[1..$-2]
    end for
    return {left_actions,{size_left,length(left_actions),size_right}}
end function

global function is_symmetric(set_operation f)
    sequence s
    integer n
    n=f[2][1]
    if n!=f[2][2] then
        return 0
    end if
    s=f[1]
    for i=1 to n-1 do
        for j=i+1 to n do
            if s[i][j]!=s[j][i] then
                return 0
            end if
        end for
    end for
    return 1
end function

global function is_associative(set_operation f)
    sequence s
    integer n
    
    s=f[2]
    n=s[1]
    if s[2]!=n or s[3]!=n then
        return 0
    end if 
    s=f[1]
    for i=1 to n do
        for j=1 to n do
            for k=1 to n do
                if s[s[i][j]][k]!=s[i][s[j][k]] then
                    return 0
                end if
            end for
        end for
    end for
    return 1
end function

global function has_left_unit(set_operation f)
    if f[2][2]!=f[2][3] then
        return 0
    else
        return find(iota(f[2][2]),f[1])
    end if
end function

function all_left_units_(sequence f)
    sequence result,s
    if f[2][2]!=f[2][3] then
        return ""
    else
        result=""
        s=iota(f[2][2])
        for i=1 to f[2][1] do
            if equal(f[1][i],s) then
                result&=i
            end if
        end for
        return result
    end if
end function

global function all_left_units(set_operation f)
    return all_left_units_(f)
end function

global function is_left_unit(integer x,set_operation f)
    if f[2][2]!=f[2][3] or not bounded_integer(x,1,f[2][1]) then
        return 0
    else
        return equal(f[1][x],iota(f[2][2]))
    end if
end function

global function has_right_unit(set_operation f)
    integer p
    if f[2][3]!=f[2][1] then
        return ""
    else
        for i=1 to f[2][1] do
            p=0
            for j=1 to f[2][2] do
                if f[1][j][i]!=j then
                    p=j
                    exit
                end if
            end for
            if p=0 then
                return i
            end if
        end for
        return 0
    end if
end function

global function all_right_units(set_operation f)
    integer p
    sequence result

    result=""
    if f[2][3]!=f[2][1] then
        return result
    else
        for i=1 to f[2][2] do
            p=0
            for j=1 to f[2][1] do
                if f[1][j][i]!=j then
                    p=j
                    exit
                end if
            end for
            if p=0 then
                result&=i
            end if
        end for
        return result
    end if
end function

function is_right_unit_(integer x,sequence f)
-- Description: Wrapped by is_right_unit() so as to avoid some type checks.
    if f[2][3]!=f[2][1] or not bounded_integer(x,1,f[2][2]) then
        return 0
    else
        for i=1 to f[2][1] do
            if f[1][i][x]!=i then
                return 0
            end if
        end for
        return 1
    end if
end function

global function is_right_unit(integer x,set_operation f)
    return is_right_unit_(x,f)
end function

function has_unit_(sequence f)
    sequence s
    s=all_left_units_(f)
    if length(s)!=1 then
        return 0
    elsif is_right_unit_(s[1],f) then
        return s[1]
    else
        return 0
    end if
end function

global function has_unit(set_operation f)
    return has_unit_(f)
end function

global function has_inverse(integer x,set_operation f)
    return find(has_unit_(f),f[1][x])
end function

function distributes_left_(sequence product,sequence sum,integer transpose)
-- Description: Wrapped by distributes_left(), so as to avoid some type checks.
    integer p,q,p1
    sequence f1,g1
    p=product[2][2]
    if transpose then
        q=3
    else
        q=1
    end if
    p1=product[2][q]
    if p=product[2][4-q] and not find(0,sum[2]=p) then
        f1=product[1]
        g1=sum[1]
        if transpose then
            for i=1 to p1 do
                for j=1 to p do
                    for k=1 to p do
                        if f1[i][g1[k][j]]!=g1[f1[i][k]][f1[i][j]] then
                            return 0
                        end if
                    end for
                end for
            end for
        else
            for i=1 to p do
                for j=1 to p1 do
                    for k=1 to p1 do
                        if f1[i][g1[j][k]]!=g1[f1[i][j]][f1[i][k]] then
                            return 0
                        end if
                    end for
                end for
            end for
        end if
        return 1
    else
        return 0
    end if
end function

global function distributes_left(set_operation product,set_operation sum,integer transpose)
    return distributes_left_(product,sum,transpose)
end function

function distributes_right_(sequence product,sequence sum,integer transpose)
    integer p,q,p1
    sequence f1,g1
    p=product[2][2]
    if transpose then
        q=1
    else
        q=3
    end if
    p1=product[2][q]
    if p=product[2][4-q] and not find(0,sum[2]=p) then
        f1=product[1]
        g1=sum[1]
        if transpose then
            for i=1 to p1 do
                for j=1 to p do
                    for k=1 to p do
                        if f1[i][g1[j][k]]!=g1[f1[i][j]][f1[i][k]] then
                            return 0
                        end if
                    end for
                end for
            end for
        else
            for i=1 to p do
                for j=1 to p1 do
                    for k=1 to p1 do
                        if f1[i][g1[k][j]]!=g1[f1[i][k]][f1[i][j]] then
                            return 0
                        end if
                    end for
                end for
            end for
        end if
        return 1
    else
        return 0
    end if
end function

global function distributes_right(set_operation product,set_operation sum,integer transpose)
    return distributes_right_(product,sum,transpose)
end function

global function distributes_over(set_operation product,set_operation sum,integer transpose)
    return distributes_left_(product,sum,transpose)+2*distributes_right_(product,sum,not transpose)
end function

