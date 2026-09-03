vlib work

vlog ../utils/*.sv
vlog ../peripheral/*.sv 
vlog ../peripheral/testbench/*.sv

noview library
vsim -voptargs=+acc work.uart_rx_test
add wave -r /*
run -all
wave zoom full
