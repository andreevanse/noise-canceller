//timeunit 1ns;
//timeprecision 1ns;

module NoiseCancellerTB;
    
    const realtime CLOCK_PERIOD = 45ns;
    int f;
    logic clock, reset;
    initial begin
        f = $fopen("../../test/harm_noise_channels.txt","r");
        // f = $fopen("../../test/band_noise_channels.txt","r");

        clock = '0;
        forever #(CLOCK_PERIOD/2) clock = ~clock; 
    end    

    initial begin
        reset <= '1;
        repeat(2) @(posedge clock);
        reset <= '0;        
    end

    localparam MAIN_CHANNEL_DELAY = 1;
    
    real main_I, main_Q, noise_I, noise_Q;
    logic signed[11:0] mainFx_I, mainFx_Q, noiseFx_I, noiseFx_Q;
    logic signed[11:0] mainDelay_I[MAIN_CHANNEL_DELAY] = '{MAIN_CHANNEL_DELAY{0}};
    logic signed[11:0] mainDelay_Q[MAIN_CHANNEL_DELAY] = '{MAIN_CHANNEL_DELAY{0}};

    int res;
    logic enable = '0;
    always_ff @(posedge clock)
    begin
        if(enable == '1)
        begin
            res = $fscanf(f, "%f,%f,%f,%f\n", main_I, main_Q, noise_I, noise_Q);
            enable <= '0;
        end
        else
        begin
            enable <= ~reset;
        end
        // for(int i = 0; i < MAIN_CHANNEL_DELAY; ++i)
        // begin
            // mainDelay_I[i] <= i ? mainDelay_I[i-1] : main_I;
            // mainDelay_Q[i] <= i ? mainDelay_Q[i-1] : main_Q;
        // end
        noiseFx_I <= noise_I;
        noiseFx_Q <= noise_Q;
        mainFx_I <= main_I; //mainDelay_I[MAIN_CHANNEL_DELAY-1];
        mainFx_Q <= main_Q; //mainDelay_Q[MAIN_CHANNEL_DELAY-1];
    end
    
    logic signed[11:0] result_I, result_Q;
    AdaptiveNoiseCanceller #(.DATA_BUS_SIZE(12)) anc_inst
    (
        .clock(clock),
        .reset(reset),
        .sigEnable(enable),
        
        .signalChannel_I(mainFx_I),
        .signalChannel_Q(mainFx_Q),

        .noiseChannel_I(noiseFx_I),
        .noiseChannel_Q(noiseFx_Q),

        .result_I(result_I),
        .result_Q(result_Q)
    );
    
endmodule
