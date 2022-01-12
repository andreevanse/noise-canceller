set TEST_NAME  "StartNoiseCancellerVerification"

set TMP_DIR "$SIM_DIR/$TEST_NAME"

quit -sim
file mkdir $TMP_DIR
cd $TMP_DIR

# #############################################################################################################################
# компилируем исходники
# #############################################################################################################################
    vlib noisecancverif_tb

    # тестбенч
    vlog  "$TEST_DIR/NoiseCancellerTB.sv" -work noisecancverif_tb
    
    # исходный код
    vlog  "$SOURCE_DIR/ANC/ComplexMultiplyer.sv" -work noisecancverif_tb
    vlog  "$SOURCE_DIR/ANC/ComplexFIR.sv" -work noisecancverif_tb
    vlog  "$SOURCE_DIR/ANC/CoefficientAdaptation.sv" -work noisecancverif_tb
    vlog  "$SOURCE_DIR/ANC/AdaptiveNoiseCanceller.sv" -work noisecancverif_tb    
    vlog  "$SOURCE_DIR/AGC/AutomaticGainControl.sv" -work noisecancverif_tb    
    vlog  "$SOURCE_DIR/AGC/Fifo.sv" -work noisecancverif_tb    

# #############################################################################################################################
vsim -voptargs="+acc" noisecancverif_tb.NoiseCancellerTB ;#-debugDB

add wave -divider "TOP"
add wave -radix hex NoiseCancellerTB/*
add wave -radix dec -format analog -min -1024 -max 1024 -height 150 NoiseCancellerTB/result_I
add wave -radix dec -format analog -min -1024 -max 1024 -height 150 NoiseCancellerTB/result_Q
add wave -divider "ANC"
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 NoiseCancellerTB/anc_inst/signalChannel_I
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 NoiseCancellerTB/anc_inst/signalChannel_Q
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 NoiseCancellerTB/anc_inst/noiseChannel_I
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 NoiseCancellerTB/anc_inst/noiseChannel_Q
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 NoiseCancellerTB/anc_inst/error_I
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 NoiseCancellerTB/anc_inst/error_Q
# add wave -radix dec -format analog -min -1024 -max 1024 -height 100 NoiseCancellerTB/anc_inst/result_I
# add wave -radix dec -format analog -min -1024 -max 1024 -height 100 NoiseCancellerTB/anc_inst/result_Q
add wave -radix dec -format analog -min -4500 -max 4500 -height 100 {NoiseCancellerTB/anc_inst/newCoefficient_I[0]}
add wave -radix dec -format analog -min -4500 -max 4500 -height 100 {NoiseCancellerTB/anc_inst/newCoefficient_I[1]}
add wave -radix dec -format analog -min -4500 -max 4500 -height 100 {NoiseCancellerTB/anc_inst/newCoefficient_I[2]}
add wave -radix dec -format analog -min -4500 -max 4500 -height 100 {NoiseCancellerTB/anc_inst/newCoefficient_Q[0]}
add wave -radix dec -format analog -min -4500 -max 4500 -height 100 {NoiseCancellerTB/anc_inst/newCoefficient_Q[1]}
add wave -radix dec -format analog -min -4500 -max 4500 -height 100 {NoiseCancellerTB/anc_inst/newCoefficient_Q[2]}
add wave -divider "Adapt"
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 {NoiseCancellerTB/anc_inst/adapter_inst/increment_I[0]}
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 {NoiseCancellerTB/anc_inst/adapter_inst/increment_Q[0]}
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 {NoiseCancellerTB/anc_inst/adapter_inst/increment_I[1]}
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 {NoiseCancellerTB/anc_inst/adapter_inst/increment_Q[1]}
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 {NoiseCancellerTB/anc_inst/adapter_inst/increment_I[2]}
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 {NoiseCancellerTB/anc_inst/adapter_inst/increment_Q[2]}
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 {NoiseCancellerTB/anc_inst/adapter_inst/renormedError_I}
add wave -radix dec -format analog -min -1024 -max 1024 -height 100 {NoiseCancellerTB/anc_inst/adapter_inst/renormedError_Q}

# add wave -radix hex NoiseCancellerTB/anc_inst/fir_inst/*
# add wave -radix hex {NoiseCancellerTB/anc_inst/fir_inst/mul_re[0]}
# add wave -radix hex {NoiseCancellerTB/anc_inst/fir_inst/mul_im[0]}
# add wave -radix hex {NoiseCancellerTB/anc_inst/fir_inst/firCoefficient_I[0]}
# add wave -radix hex {NoiseCancellerTB/anc_inst/fir_inst/firCoefficient_Q[0]}
# add wave -radix hex {NoiseCancellerTB/anc_inst/fir_inst/firCoefficient_I[1]}
# add wave -radix hex {NoiseCancellerTB/anc_inst/fir_inst/firCoefficient_Q[1]}
# add wave -radix hex {NoiseCancellerTB/anc_inst/fir_inst/firCoefficient_I[2]}
# add wave -radix hex {NoiseCancellerTB/anc_inst/fir_inst/firCoefficient_Q[2]}


run 608us

wave zoom full
