module CoefficientAdaptation
#(DATA_BUS_SIZE = 11, TAPS = 3, NORMALIZATION_CONST = 3)
(
    input logic clock,
    input logic reset,
    input logic sigEnable,
    
    input logic signed[DATA_BUS_SIZE-1:0] currentCoefficient_I[TAPS],
    input logic signed[DATA_BUS_SIZE-1:0] currentCoefficient_Q[TAPS],
    
    input logic signed[DATA_BUS_SIZE-1:0] signal_I,
    input logic signed[DATA_BUS_SIZE-1:0] signal_Q,
    
    input logic signed[DATA_BUS_SIZE-1:0] error_I,
    input logic signed[DATA_BUS_SIZE-1:0] error_Q,

    output logic signed[DATA_BUS_SIZE-1:0] newCoefficient_I[TAPS],
    output logic signed[DATA_BUS_SIZE-1:0] newCoefficient_Q[TAPS]
);

    const logic signed[DATA_BUS_SIZE-1:0] normalizationConst = DATA_BUS_SIZE'(NORMALIZATION_CONST);
    
    logic signed[DATA_BUS_SIZE-1:0] delay_I[TAPS];
    logic signed[DATA_BUS_SIZE-1:0] delay_Q[TAPS];
    
    genvar i;
    generate for(i = TAPS; i > 0; --i)
    begin : DelayLine
        always_ff @(posedge clock or posedge reset)
            if(reset)
            begin
                delay_I[i-1] <= '0;
                delay_Q[i-1] <= '0;
            end
            else if(sigEnable)
            begin
                delay_I[i-1] <= (i == TAPS) ? signal_I : delay_I[i];
                delay_Q[i-1] <= (i == TAPS) ? signal_Q : delay_Q[i];
            end
    end
    endgenerate

    logic signed[DATA_BUS_SIZE-1:0] renormedError_I;
    logic signed[DATA_BUS_SIZE-1:0] renormedError_Q;
    // fixed point Qnf10
    assign renormedError_I = DATA_BUS_SIZE'(normalizationConst * error_I / 2**10);
    assign renormedError_Q = DATA_BUS_SIZE'(normalizationConst * error_Q / 2**10);
    
    logic signed[DATA_BUS_SIZE-1:0] increment_I[TAPS];
    logic signed[DATA_BUS_SIZE-1:0] increment_Q[TAPS];
    
    generate for(i = 0; i < TAPS; ++i)
    begin : AdaptMults
        ComplexMultiplyer #(.B_CONJUGATE(1), .DATA_BUS_SIZE(DATA_BUS_SIZE)) coeffmul_inst
        (
            .re_A(delay_I[i]),
            .im_A(delay_Q[i]),

            .re_B(renormedError_I),
            .im_B(renormedError_Q),

            .re_R(increment_I[i]),
            .im_R(increment_Q[i])
        );
    end
    endgenerate

    generate for(i = 0; i < TAPS; ++i)
    begin : NewCoeff
        always_ff @(posedge clock or posedge reset)
            if(reset)
            begin
                newCoefficient_I[i] <= '0;
                newCoefficient_Q[i] <= '0;
            end
            else 
            if(sigEnable)
            begin
                newCoefficient_I[i] <= currentCoefficient_I[i] + increment_I[i];
                newCoefficient_Q[i] <= currentCoefficient_Q[i] + increment_Q[i];
            end
    end
    endgenerate

endmodule