onfinish stop
add wave -r sim:/cnt_tb/*
# alternatively to get all signals from the root use the following: 
# add wave -r /*
# the VCD generation is taken care by the SV system tasks in the testbench
run -all
quit -f
