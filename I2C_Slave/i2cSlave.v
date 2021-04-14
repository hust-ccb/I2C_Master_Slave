// *****************************************************************************
// Filename    : i2cSlave.v
// Create on   : 2020/3/17 15:52
// Revise on   : 2020/3/17 15:52
// Version     : 1.0
// Author      : CCB
// Email       : 
// Description : 顶层文件，产生scl与sda的采样信号，同时例化底层文件
//                 
// Editor      : sublime text 3, tab size 4
// *****************************************************************************

`include "i2cSlave_define.v"

module i2cSlave (
    clk,
    rst, //高电平复位
    sda,
    scl,
    freq_set,
    gain_set,
    int_set,
    temp,
    myReg0
);

input           clk;
input           rst;
inout           sda;
input           scl;
output  [7:0]   freq_set;
output  [7:0]   gain_set;
output  [15:0]  int_set;

input   [15:0]  temp;
input   [7:0]   myReg0;



// local wires and regs
reg sdaDeb;
reg sclDeb;
reg [`DEB_I2C_LEN-1:0]  sdaPipe;
reg [`DEB_I2C_LEN-1:0]  sclPipe;

reg [`SCL_DEL_LEN-1:0]  sclDelayed;
reg [`SDA_DEL_LEN-1:0]  sdaDelayed;
reg [1:0]               startStopDetState;
wire                    clearStartStopDet;
wire                    sdaOut;
wire                    sdaIn;
wire    [7:0]           regAddr;
wire    [7:0]           dataToRegIF;
wire                    writeEn;
//wire [7:0] dataFromRegIF;
wire    [15:0]          dataFromRegIF;
reg [1:0]               rstPipe;
wire                    rstSyncToClk;
reg                     startEdgeDet;

assign sda = (sdaOut == 1'b0) ? 1'b0 : 1'bz;
assign sdaIn = sda;

// sync rst rsing edge to clk
always @(posedge clk) begin
  if (rst == 1'b1)
    rstPipe <= 2'b11;
  else
    rstPipe <= {rstPipe[0], 1'b0};
end

assign rstSyncToClk = rstPipe[1];

// debounce sda and scl
always @(posedge clk) begin
  if (rstSyncToClk == 1'b1) begin
    sdaPipe <= {`DEB_I2C_LEN{1'b1}};
    sdaDeb <= 1'b1;
    sclPipe <= {`DEB_I2C_LEN{1'b1}};
    sclDeb <= 1'b1;
  end
  else begin
    sdaPipe <= {sdaPipe[`DEB_I2C_LEN-2:0], sdaIn};
    sclPipe <= {sclPipe[`DEB_I2C_LEN-2:0], scl};
    if (&sclPipe[`DEB_I2C_LEN-1:1] == 1'b1) //scl全1
      sclDeb <= 1'b1;
    else if (|sclPipe[`DEB_I2C_LEN-1:1] == 1'b0)//scl全1
      sclDeb <= 1'b0;
    if (&sdaPipe[`DEB_I2C_LEN-1:1] == 1'b1)//sda全1
      sdaDeb <= 1'b1;
    else if (|sdaPipe[`DEB_I2C_LEN-1:1] == 1'b0)//sda全0
      sdaDeb <= 1'b0;
  end
end


// delay scl and sda
// sclDelayed is used as a delayed sampling clock
// sdaDelayed is only used for start stop detection
// Because sda hold time from scl falling is 0nS
// sda must be delayed with respect to scl to avoid incorrect
// detection of start/stop at scl falling edge. 
always @(posedge clk) begin
  if (rstSyncToClk == 1'b1) begin
    sclDelayed <= {`SCL_DEL_LEN{1'b1}};
    sdaDelayed <= {`SDA_DEL_LEN{1'b1}};
  end
  else begin
    sclDelayed <= {sclDelayed[`SCL_DEL_LEN-2:0], sclDeb};
    sdaDelayed <= {sdaDelayed[`SDA_DEL_LEN-2:0], sdaDeb};
  end
end

// start stop detection
always @(posedge clk) begin
  if (rstSyncToClk == 1'b1) begin
    startStopDetState <= `NULL_DET;
    startEdgeDet <= 1'b0;
  end
  else begin
    if (sclDeb == 1'b1 && sdaDelayed[`SDA_DEL_LEN-2] == 1'b0 && sdaDelayed[`SDA_DEL_LEN-1] == 1'b1)//SCL的最高位为1，次高位为0
      startEdgeDet        <= 1'b1;//start信号
    else
      startEdgeDet        <= 1'b0;
    if (clearStartStopDet == 1'b1) //1个字节数据写完时为1
      startStopDetState   <= `NULL_DET;
    else if (sclDeb == 1'b1) begin
      if (sdaDelayed[`SDA_DEL_LEN-2] == 1'b1 && sdaDelayed[`SDA_DEL_LEN-1] == 1'b0) 
        startStopDetState <= `STOP_DET;//STOP信号
      else if (sdaDelayed[`SDA_DEL_LEN-2] == 1'b0 && sdaDelayed[`SDA_DEL_LEN-1] == 1'b1)
        startStopDetState <= `START_DET;//RSTART信号
    end
  end
end

// reg [31:0] sl_rx_data;
// wire [31:0] ms_tx_data;
// always @(posedge clk) begin
//     if (rstSyncToClk == 1'b1) begin
//         sl_rx_data <= 32'd0;
//     end
//     else if(startStopDetState == `STOP_DET) begin
//         sl_rx_data <= ms_tx_data;
//     end
//     else 
//         sl_rx_data <= sl_rx_data;
// end

wire txlen_flag;
registerInterface u_registerInterface(
    .clk       (clk),
    .addr      (regAddr),
    .dataIn    (dataToRegIF),
    .writeEn   (writeEn),
    .dataOut   (dataFromRegIF),
    .freq_set  (freq_set),
    .gain_set  (gain_set),
    .int_set   (int_set),
    .temp      (16'h3355),     //temp
    .myReg0    (8'h33),//myReg0
    .txlen_flag(txlen_flag)
);

serialInterface u_serialInterface (
    .clk               (clk), 
    .rst               (rstSyncToClk | startEdgeDet), 
    .dataIn            (dataFromRegIF), 
    .dataOut           (dataToRegIF), 
    .writeEn           (writeEn),
    .regAddr           (regAddr), 
    .scl               (sclDelayed[`SCL_DEL_LEN-1]), 
    .sdaIn             (sdaDeb), 
    .sdaOut            (sdaOut), 
    .startStopDetState (startStopDetState),
    .clearStartStopDet (clearStartStopDet),
    .data_length       (),
    .txlen_flag(txlen_flag)
);


endmodule


 
