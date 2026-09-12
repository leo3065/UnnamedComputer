vlib work

vlog -lint ../common_module/*.sv
vlog -lint ../utils/*.sv

vlog -lint ../peripheral/uart/*.sv

noview library
vsim -voptargs=+acc work.uart_rx_test
add wave /*
run -all
wave zoom full
