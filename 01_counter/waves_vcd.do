onfinish stop
add wave -r sim:/cnt_tb/*
# alternatively to get all signals from the root use the following line:
# add wave -r /*
# With the next two lines Questa suppresses the VCD generation from the SV system tasks in the testbench
vcd file waveforms_tb.vcd
vcd add sim:/cnt_tb/*
run -all
quit -f
