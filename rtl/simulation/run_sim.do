vlib work

vlog -lint ../utils/*.sv
vlog -lint ../peripheral/uart/*.sv

noview library
vsim -voptargs=+acc work.fifo_test
add wave /*
run -all
wave zoom full
