// *****************************************************************************
// Filename    : registerInterface.v
// Create on   : 2020/3/17 14:52
// Revise on   : 2020/3/17 14:52
// Version     : 1.0
// Author      : CCB
// Email       : 
// Description : ÓÃ»§¿ÉÒÔ×Ô¶¨Òå¶ÁÐ´¼Ä´æÆ÷£¬ÕâÀïÖ»ÅäÖÃÁËÏîÄ¿ÐèÇóµÄ¼Ä´æÆ÷
//                 
// Editor      : sublime text 3, tab size 4
// *****************************************************************************

`include "i2cSlave_define.v"


module registerInterface (
    clk,
    addr,
    dataIn,
    writeEn,
    dataOut,
    freq_set,
    gain_set,
    int_set,
    temp,
    myReg0,
    txlen_flag
);

input               clk;
input   [7:0]       addr;
input   [7:0]       dataIn;
input               writeEn;
input   [15:0]      temp;
input   [7:0]       myReg0;

output reg  [15:0]  dataOut;
output reg  [7:0]   freq_set;
output reg  [7:0]   gain_set;
output reg  [15:0]  int_set;

output reg          txlen_flag;


// --- I2C Write
always @(posedge clk) begin
    if (writeEn == 1'b1) begin
    case (addr)
        8'h15: freq_set <= dataIn;  //Ö¡Æµ
        8'h17: gain_set <= dataIn;  //ÔöÒæ
        8'h10: int_set  <= {int_set[7:0],dataIn};//»ý·ÖÊ±¼ä£¬ÏÈ½ÓÊÕ¸ß×Ö½Ú
    endcase
    end
    else begin
        freq_set <= freq_set;
        gain_set <= gain_set;
        int_set  <= int_set;
    end
end

// --- I2C Read
always @(posedge clk) begin
    case (addr)
        8'h14: begin dataOut <= temp; txlen_flag <= 1'b1; end
        8'h11: begin dataOut <= {8'b0, myReg0}; txlen_flag <= 1'b0; end 
    default: 
        dataOut <= 16'h00;
    endcase
end

endmodule


 
