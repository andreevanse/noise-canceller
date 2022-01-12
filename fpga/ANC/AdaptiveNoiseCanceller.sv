module AdaptiveNoiseCanceller
#(DATA_BUS_SIZE = 12)
(
    input logic clock,
    input logic reset,
    input logic sigEnable,
    
    input logic signed[DATA_BUS_SIZE-1:0] signalChannel_I,
    input logic signed[DATA_BUS_SIZE-1:0] signalChannel_Q,

    input logic signed[DATA_BUS_SIZE-1:0] noiseChannel_I,
    input logic signed[DATA_BUS_SIZE-1:0] noiseChannel_Q,

    output logic signed[DATA_BUS_SIZE-1:0] result_I,
    output logic signed[DATA_BUS_SIZE-1:0] result_Q
);

    localparam TAPS = 3;
    localparam SIGNAL_CHANNEL_DELAY = 2;
    // For correct signal-noise alignment
    logic signed[DATA_BUS_SIZE-1:0] signalChannel_I_delay[SIGNAL_CHANNEL_DELAY], signalChannel_Q_delay[SIGNAL_CHANNEL_DELAY];
    always_ff @(posedge clock or posedge reset)
        if(reset)
        begin
            for(int i = 0; i < SIGNAL_CHANNEL_DELAY; ++i)
            begin
                signalChannel_I_delay[i] <= '0;
                signalChannel_Q_delay[i] <= '0;
            end
        end
        else if(sigEnable)
        begin
            for(int i = 0; i < SIGNAL_CHANNEL_DELAY; ++i)
            begin
                signalChannel_I_delay[i] <= i ? signalChannel_I_delay[i-1] : signalChannel_I;
                signalChannel_Q_delay[i] <= i ? signalChannel_Q_delay[i-1] : signalChannel_Q;
            end
        end

    
    logic signed[DATA_BUS_SIZE-1:0] newCoefficient_I[TAPS];
    logic signed[DATA_BUS_SIZE-1:0] newCoefficient_Q[TAPS];
    logic signed[DATA_BUS_SIZE-1:0] currentCoefficient_I[TAPS];
    logic signed[DATA_BUS_SIZE-1:0] currentCoefficient_Q[TAPS];
    
    genvar i;
    generate for(i = 0; i < TAPS; ++i)
    begin : RecycleCoeffs
        assign currentCoefficient_I[i] = newCoefficient_I[i];
        assign currentCoefficient_Q[i] = newCoefficient_Q[i];
    end
    endgenerate

    logic signed[DATA_BUS_SIZE-1:0] filtered_I, filtered_Q;
    ComplexFIR #(.DATA_BUS_SIZE(DATA_BUS_SIZE), .TAPS(TAPS)) fir_inst
    (
        .clock(clock),
        .reset(reset),
        .sigEnable(sigEnable),
        
        .firCoefficient_I(currentCoefficient_I),
        .firCoefficient_Q(currentCoefficient_Q),
        
        .signal_I(noiseChannel_I),
        .signal_Q(noiseChannel_Q),

        .filtered_I(filtered_I),
        .filtered_Q(filtered_Q)
    );

    logic signed[DATA_BUS_SIZE-1:0] error_I, error_Q;
    assign error_I = signalChannel_I_delay[SIGNAL_CHANNEL_DELAY-1] - filtered_I;
    assign error_Q = signalChannel_Q_delay[SIGNAL_CHANNEL_DELAY-1] - filtered_Q;

    CoefficientAdaptation #(.DATA_BUS_SIZE(DATA_BUS_SIZE), .TAPS(TAPS), .NORMALIZATION_CONST(32)) adapter_inst
    (
        .clock(clock),
        .reset(reset),
        .sigEnable(sigEnable),
        
        .currentCoefficient_I(currentCoefficient_I),
        .currentCoefficient_Q(currentCoefficient_Q),
        
        .signal_I(noiseChannel_I),
        .signal_Q(noiseChannel_Q),
        
        .error_I(error_I),
        .error_Q(error_Q),

        .newCoefficient_I(newCoefficient_I),
        .newCoefficient_Q(newCoefficient_Q)
    );

    always_ff @(posedge clock or posedge reset)
        if(reset)
        begin
            result_I <= '0;
            result_Q <= '0;
        end
        else if(sigEnable)
        begin
            result_I <= error_I;
            result_Q <= error_Q;
        end


endmodule