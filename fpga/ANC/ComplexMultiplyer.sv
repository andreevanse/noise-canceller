module ComplexMultiplyer
#(B_CONJUGATE = 0, DATA_BUS_SIZE = 11)
(
    // input logic clock,
    // input logic sigEnable,
    
    input logic signed[DATA_BUS_SIZE-1:0] re_A,
    input logic signed[DATA_BUS_SIZE-1:0] im_A,

    input logic signed[DATA_BUS_SIZE-1:0] re_B,
    input logic signed[DATA_BUS_SIZE-1:0] im_B,

    output logic signed[DATA_BUS_SIZE-1:0] re_R,
    output logic signed[DATA_BUS_SIZE-1:0] im_R
);

    logic signed[2*DATA_BUS_SIZE-1:0] rere_AB, imim_AB, imre_AB, reim_AB;
    logic signed[2*DATA_BUS_SIZE:0] re_tmp, im_tmp;
    
    assign rere_AB = re_A * re_B;
    assign imim_AB = im_A * im_B;
    assign imre_AB = im_A * re_B;
    assign reim_AB = re_A * im_B;

    
    generate if(B_CONJUGATE)
    begin
        assign re_tmp = rere_AB + imim_AB; 
        assign im_tmp = imre_AB - reim_AB;
    end
    else
    begin
        assign re_tmp = rere_AB - imim_AB; 
        assign im_tmp = imre_AB + reim_AB;
    end
    endgenerate
    
    // fixed point Qnf10
    assign re_R = DATA_BUS_SIZE'(re_tmp / 2**10);
    assign im_R = DATA_BUS_SIZE'(im_tmp / 2**10);
    
endmodule