module ComplexFIR
#(DATA_BUS_SIZE = 11, TAPS = 3)
(
    input logic clock,
    input logic reset,
    input logic sigEnable,
    
    input logic signed[DATA_BUS_SIZE-1:0] firCoefficient_I[TAPS],
    input logic signed[DATA_BUS_SIZE-1:0] firCoefficient_Q[TAPS],
    
    input logic signed[DATA_BUS_SIZE-1:0] signal_I,
    input logic signed[DATA_BUS_SIZE-1:0] signal_Q,

    output logic signed[DATA_BUS_SIZE-1:0] filtered_I,
    output logic signed[DATA_BUS_SIZE-1:0] filtered_Q
);
   
    logic signed[DATA_BUS_SIZE-1:0] filterTap_I[TAPS];
    logic signed[DATA_BUS_SIZE-1:0] filterTap_Q[TAPS];
    
    logic signed[DATA_BUS_SIZE-1:0] mul_re[TAPS];
    logic signed[DATA_BUS_SIZE-1:0] mul_im[TAPS];
    
    genvar i;
    generate for(i = 0; i < TAPS; ++i)
    begin : FirMults
        ComplexMultiplyer #(.B_CONJUGATE(1), .DATA_BUS_SIZE(DATA_BUS_SIZE)) cmult_inst
        (
            .re_A(signal_I),
            .im_A(signal_Q),

            .re_B(firCoefficient_I[i]),
            .im_B(firCoefficient_Q[i]),

            .re_R(mul_re[i]),
            .im_R(mul_im[i])
        );
    end
    endgenerate
    
    generate for(i = 0; i < TAPS; ++i)
    begin : DelayLine
        always_ff @(posedge clock or posedge reset)
            if(reset)
            begin
                filterTap_I[i] <= '0;
                filterTap_Q[i] <= '0;
            end
            else if(sigEnable)
            begin
                filterTap_I[i] <= (i ? filterTap_I[i-1] : signed'('0)) + mul_re[i];
                filterTap_Q[i] <= (i ? filterTap_Q[i-1] : signed'('0)) + mul_im[i];
            end
    end
    endgenerate

    assign filtered_I = filterTap_I[TAPS-1];
    assign filtered_Q = filterTap_Q[TAPS-1];

endmodule