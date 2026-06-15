# add desired signals and zoom full
view wave
add wave vsim:/tb_top/v_clk
add wave vsim:/tb_top/clk
add wave vsim:/tb_top/rst_n
add wave vsim:/tb_top/load
add wave vsim:/tb_top/data_in
add wave vsim:/tb_top/count
add wave vsim:/tb_top/dut/next_count
# show leaf name only (set to 0 for Full or 2 for Local)
configure wave -signalnamewidth 1
# full zoom
wave zoom full
