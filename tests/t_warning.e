include std/unittest.e

with warning
with warning &= {none}
with warning &={resolution}
with warning &={short_circuit}
with warning &= {override}
with warning &= {builtin_chosen}
with warning &= {not_used}
with warning &= {no_value}
with warning &= {custom}
with warning &= {translator}
with warning &= {cmdline}
with warning &= {not_reached}
with warning &= {mixed_profile}
with warning &= {empty_case}
with warning &= {default_case}
with warning &= {literal_mismatch}
with warning &= {all}

with warning &= {none, resolution, short_circuit, override, builtin_chosen, 
                 not_used,no_value, custom, translator, cmdline, not_reached
                 , mixed_profile, empty_case
                 ,
                 default_case, all}

with warning+= {none}
with warning +={resolution}
with warning+={short_circuit}
with warning += {override}
with warning += {builtin_chosen}
with warning += {not_used}
with warning += {no_value}
with warning += {custom}
with warning += {translator}
with warning += {cmdline}
with warning += {not_reached}
with warning += {mixed_profile}
with warning += {empty_case}
with warning += {default_case}
with warning += {literal_mismatch}
with warning += {all}

without warning
without warning&= {none}
without warning &={resolution}
without warning&={short_circuit}
without warning &= {override}
without warning &= {builtin_chosen}
without warning &= {not_used}
without warning &= {no_value}
without warning &= {custom}
without warning &= {translator}
without warning &= {cmdline}
without warning &= {not_reached}
without warning &= {mixed_profile}
without warning &= {empty_case}
without warning &= {default_case}
without warning &= {all}
without warning &= {none, resolution, short_circuit, override, builtin_chosen, 
                 not_used,no_value, custom, translator, cmdline, not_reached
                 , mixed_profile, empty_case, literal_mismatch
                 ,
                 default_case, all}

without warning+= {none}
without warning +={resolution}
without warning+={short_circuit}
without warning += {override}
without warning += {builtin_chosen}
without warning += {not_used}
without warning += {no_value}
without warning += {custom}
without warning += {translator}
without warning += {cmdline}
without warning += {not_reached}
without warning += {mixed_profile}
without warning += {empty_case}
without warning += {default_case}
without warning += {literal_mismatch}
without warning += {all}

with warning= {none}
with warning ={resolution}
with warning={short_circuit}
with warning = {override}
with warning = {builtin_chosen}
with warning = {not_used}
with warning = {no_value}
with warning = {custom}
with warning = {translator}
with warning = {cmdline}
with warning = {not_reached}
with warning = {mixed_profile}
with warning = {empty_case}
with warning = {literal_mismatch}
with warning = {default_case}
with warning = {all}
with warning = {none, resolution, short_circuit, override, builtin_chosen, 
                 not_used,no_value, custom, translator, cmdline, not_reached
                 , mixed_profile, empty_case
                 ,
                 default_case, all}

without warning= {none}
without warning ={resolution}
without warning={short_circuit}
without warning = {override}
without warning = {builtin_chosen}
without warning = {not_used}
without warning = {no_value}
without warning = {custom}
without warning = {translator}
without warning = {cmdline}
without warning = {not_reached}
without warning = {mixed_profile}
without warning = {empty_case}
without warning = {default_case}
without warning = {literal_mismatch}
without warning = {all}

without warning = {none, resolution, short_circuit, override, builtin_chosen, 
                 not_used,no_value, custom, translator, cmdline, not_reached
                 , mixed_profile, empty_case, literal_mismatch
                 ,
                 default_case, all}
with warning save
with warning restore
with warning strict

without warning save
without warning restore
without warning strict

test_true("Warning syntax", 1)

test_report()
