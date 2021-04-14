// ----------------------- i2cSlave_define.v --------------------

// stream states
`define STREAM_IDLE 2'b00
`define STREAM_READ 2'b01
`define STREAM_WRITE_ADDR 2'b10
`define STREAM_WRITE_DATA 2'b11

// start stop detection states
`define NULL_DET 2'b00
`define START_DET 2'b01
`define STOP_DET 2'b10

// i2c ack and nak
`define I2C_NAK 1'b1
`define I2C_ACK 1'b0

// ----------------------------------------------------------------
// ------------- modify constants below this line -----------------
// ----------------------------------------------------------------

// i2c device address
`define I2C_ADDRESS 7'h3c

// System clock frequency in MHz
// If you are using a clock frequency below 24MHz, then the macro
// for SDA_DEL_LEN will result in compile errors for i2cSlave.v
// you will need to hand tweak the SDA_DEL_LEN constant definition
//系统时钟频率（MHz）
//如果您使用的时钟频率低于24MHz，则SDA_DEL_LEN宏将导致i2cSlave.v的编译错误
//需要手动调整SDA_DEL_LEN常量定义

`define CLK_FREQ 48

// Debounce SCL and SDA over this many clock ticks
// The rise time of SCL and SDA can be up to 1000nS (in standard mode)
// so it is essential to debounce the inputs.
// The spec requires 0.05V of hysteresis, but in practise
// simply debouncing the inputs is sufficient
// I2C spec requires suppresion of spikes of 
// maximum duration 50nS, so this debounce time should be greater than 50nS
// Also increases data hold time and decreases data setup time
// during an I2C read operation
// SCL和SDA去抖动需要多个时钟，SCL和SDA的上升时间可达1000nS(标准模式下)
// 有必要对输入进行消抖。
// 规范要求0.05V的滞后，但在实际上简单地对输入消抖就足够了

// I2C规范要求抑制尖峰最大持续时间50nS，因此消抖时间应该大于50nS

//在I2C读操作期间，也可以增加数据保持时间和减少数据建立时间

// 10 ticks = 208nS @ 48MHz，在48M下10个ticks共208ns
`define DEB_I2C_LEN (10*`CLK_FREQ)/48 //消抖的长度

// Delay SCL for use as internal sampling clock
// Using delayed version of SCL to ensure that 
// SDA is stable when it is sampled.
// Not entirely citical, as according to I2C spec
// SDA should have a minimum of 100nS of set up time
// with respect to SCL rising edge. But with the very slow edge 
// speeds used in I2C it is better to err on the side of caution.
// This delay also has the effect of adding extra hold time to the data
// with respect to SCL falling edge. I2C spec requires 0nS of data hold time.
// 延迟SCL用作内部采样时钟，使用SCL的延迟版本来确保采样时SDA稳定。
// 并不完全准确的来说，根据I2C规范，在SCL上升沿SDA的建立时间至少应为100ns。 
//但是边缘边沿变化的速度很慢，在I2C中使用的速度最好还是谨慎一点。
//在SCL下降沿此延迟还具有增加数据保持时间的作用，I2C规范要求数据保持时间为0nS。
// 10 ticks = 208nS @ 48MHz

`define SCL_DEL_LEN (10*`CLK_FREQ)/48

// Delay SDA for use in start/stop detection
// Use delayed SDA during start/stop detection to avoid
// incorrect detection at SCL falling edge.
// From I2C spec start/stop setup is 600nS with respect to SCL rising edge
// and start/stop hold is 600nS wrt SCL falling edge.
// So it is relatively easy to discriminate start/stop,
// but data setup time is a minimum of 100nS with respect to SCL rising edge
// and 0nS hold wrt to SCL falling edge.
// So the tricky part is providing robust start/stop detection
// in the presence of regular data transitions.
// This delay time should be less than 100nS
// 延迟SDA以用于检测启动/停止信号，在启动/停止检测期间使用延迟的SDA以避免在SCL下降沿检测不正确。
// 根据I2C规范，相对于SCL上升沿，启动/停止设置为600nS，SCL下降沿是开始/停止保持时间为600nS。
// 因此区分开始/停止相对容易，
// 但相对于SCL上升沿，数据建立时间最少为100nS SCL下降沿保持时间0ns。
// 因此，在常规数据转换时最重要的是提供可靠的启动/停止检测，此延迟时间应小于100nS
// 4 ticks = 83nS @ 48MHz
`define SDA_DEL_LEN (4*`CLK_FREQ)/48

