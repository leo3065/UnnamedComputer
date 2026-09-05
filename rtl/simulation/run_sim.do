vlib work

vlog -lint ../utils/*.sv
vlog -lint ../peripheral/uart/*.sv

noview library
vsim -voptargs=+acc work.uart_rx_test
add wave -r /*
run -all
wave zoom full
