#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xscugic.h"
#include "xil_exception.h"

#define MY_IP_BASE      XPAR_MY_EVENT_REPORTER_IP_0_S00_AXI_BASEADDR
#define INTC_DEVICE_ID  XPAR_SCUGIC_0_DEVICE_ID
#define MY_IP_INTR_ID   XPS_FPGA0_INT_ID
XScuGic Intc;

void EventIsr(void *CallBackRef)
{
    u32 valid;
    u32 event;
    u32 count;

    valid = Xil_In32(MY_IP_BASE + 4);

    if(valid & 0x1)
    {
        event = Xil_In32(MY_IP_BASE + 0);

        switch(event)
        {
            case 0x01:
            case 0x02:
            case 0x03:
            case 0x04:
            {
                int btn = (event & 0xF) - 1;
                count = Xil_In32(MY_IP_BASE + 8 + btn*4);

                printf("[EVENT] Button %d Pressed (Total=%d)\n", btn, count);
                break;
            }

            case 0x11:
            case 0x12:
            case 0x13:
            case 0x14:
                printf("[EVENT] Switch %d UP\n",(event&0xF)-1);
                break;

            case 0x21:
            case 0x22:
            case 0x23:
            case 0x24:
                printf("[EVENT] Switch %d DOWN\n",(event&0xF)-1);
                break;
        }

        // interrupt clear
        Xil_Out32(MY_IP_BASE + 4,0);
    }
}

int main()
{
    XScuGic_Config *cfg;
    int status;

    printf("Interrupt mode start\n");

    cfg = XScuGic_LookupConfig(INTC_DEVICE_ID);

    status = XScuGic_CfgInitialize(&Intc,cfg,cfg->CpuBaseAddress);

    Xil_ExceptionInit();

    Xil_ExceptionRegisterHandler(
        XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XScuGic_InterruptHandler,
        &Intc
    );

    XScuGic_Connect(
        &Intc,
        MY_IP_INTR_ID,
        (Xil_ExceptionHandler)EventIsr,
        NULL
    );

    XScuGic_Enable(&Intc,MY_IP_INTR_ID);

    Xil_ExceptionEnable();

    while(1)
    {
        // polling 없음
    }

    return 0;
}




module debouncer(
    input clk,       // 100MHz
    input rst_n,     // Active Low
    input btn_in,
    output reg btn_out
);

    reg [19:0] count;
    reg btn_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            count   <= 20'd0;
            btn_reg <= 1'b0;
            btn_out <= 1'b0;
        end else begin
            if (btn_in != btn_reg) begin
                btn_reg <= btn_in;
                count   <= 20'd0;
            end else if (count < 20'd1_000_000) begin   // 100MHz 기준 10ms
                count <= count + 1'b1;
            end else begin
                btn_out <= btn_reg;
            end
        end
    end

endmodule




`timescale 1ns / 1ps

module event_detector(
    input clk,
    input rst_n,
    input [3:0] sw,
    input [3:0] btn,
    
    // 버튼 이벤트 (눌렀을 때 딱 1클럭 발생)
    output [3:0] btn_push_evt,
    
    // 스위치 이벤트 (올렸을 때/내렸을 때 각각 1클럭 발생)
    output [3:0] sw_up_evt,
    output [3:0] sw_down_evt
);

    // 1. 디바운싱 된 신호를 담을 와이어
    wire [3:0] btn_clean;
    wire [3:0] sw_clean;

    // 2. 엣지 검출을 위한 이전 상태 저장 레지스터
    reg [3:0] btn_reg;
    reg [3:0] sw_reg;

    // 3. 버튼 디바운서 인스턴스 (4개)
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_btn_db
            debouncer u_btn_db (
                .clk(clk),
                .rst_n(rst_n),
                .btn_in(btn[i]),
                .btn_out(btn_clean[i])
            );
        end
    endgenerate

    // 4. 스위치 디바운서 인스턴스 (4개)
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_sw_db
            debouncer u_sw_db (
                .clk(clk),
                .rst_n(rst_n),
                .btn_in(sw[i]),      // 스위치도 버튼과 동일한 디바운싱 적용
                .btn_out(sw_clean[i])
            );
        end
    endgenerate

    // 5. 엣지 검출 로직 (상태 저장)
    always @(posedge clk) begin
        if (!rst_n) begin
            btn_reg <= 4'b0;
            sw_reg  <= 4'b0;
        end else begin
            btn_reg <= btn_clean;
            sw_reg  <= sw_clean;
        end
    end

    // 6. 최종 이벤트 출력 (Pulse Generation)
    // 버튼: Rising Edge (0 -> 1)
    assign btn_push_evt = btn_clean & ~btn_reg;
    
    // 스위치: Rising Edge (Up: 0 -> 1), Falling Edge (Down: 1 -> 0)
    assign sw_up_evt   = sw_clean & ~sw_reg;
    assign sw_down_evt = ~sw_clean & sw_reg;

endmodule



`timescale 1ns / 1ps

module event_counter(
    input clk,
    input rst_n,
    input [3:0] btn_push_evt, // detector에서 온 1클럭 펄스
    
    // 각 버튼별 누적 카운트 (32비트씩 4개)
    output reg [31:0] btn0_count,
    output reg [31:0] btn1_count,
    output reg [31:0] btn2_count,
    output reg [31:0] btn3_count
);

    // 버튼 0 카운터
    always @(posedge clk) begin
        if (!rst_n) 
            btn0_count <= 32'd0;
        else if (btn_push_evt[0]) 
            btn0_count <= btn0_count + 1'b1;
    end

    // 버튼 1 카운터
    always @(posedge clk) begin
        if (!rst_n) 
            btn1_count <= 32'd0;
        else if (btn_push_evt[1]) 
            btn1_count <= btn1_count + 1'b1;
    end

    // 버튼 2 카운터
    always @(posedge clk) begin
        if (!rst_n) 
            btn2_count <= 32'd0;
        else if (btn_push_evt[2]) 
            btn2_count <= btn2_count + 1'b1;
    end

    // 버튼 3 카운터
    always @(posedge clk) begin
        if (!rst_n) 
            btn3_count <= 32'd0;
        else if (btn_push_evt[3]) 
            btn3_count <= btn3_count + 1'b1;
    end

endmodule



`timescale 1ns / 1ps

module event_packer(
    input clk,
    input rst_n,
    input [3:0] btn_push_evt,
    input [3:0] sw_up_evt,
    input [3:0] sw_down_evt,

    output reg [7:0] event_code,
    output reg event_valid
);

    always @(posedge clk) begin
        if (!rst_n) begin
            event_code  <= 8'h00;
            event_valid <= 1'b0;
        end else begin
            event_code  <= 8'h00;
            event_valid <= 1'b0;

            if      (btn_push_evt[0]) begin event_code <= 8'h01; event_valid <= 1'b1; end
            else if (btn_push_evt[1]) begin event_code <= 8'h02; event_valid <= 1'b1; end
            else if (btn_push_evt[2]) begin event_code <= 8'h03; event_valid <= 1'b1; end
            else if (btn_push_evt[3]) begin event_code <= 8'h04; event_valid <= 1'b1; end

            else if (sw_up_evt[0])    begin event_code <= 8'h11; event_valid <= 1'b1; end
            else if (sw_up_evt[1])    begin event_code <= 8'h12; event_valid <= 1'b1; end
            else if (sw_up_evt[2])    begin event_code <= 8'h13; event_valid <= 1'b1; end
            else if (sw_up_evt[3])    begin event_code <= 8'h14; event_valid <= 1'b1; end

            else if (sw_down_evt[0])  begin event_code <= 8'h21; event_valid <= 1'b1; end
            else if (sw_down_evt[1])  begin event_code <= 8'h22; event_valid <= 1'b1; end
            else if (sw_down_evt[2])  begin event_code <= 8'h23; event_valid <= 1'b1; end
            else if (sw_down_evt[3])  begin event_code <= 8'h24; event_valid <= 1'b1; end
        end
    end

endmodule





`timescale 1 ns / 1 ps

	module My_Event_Reporter_IP_v1_0_S00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
        input wire [3:0] sw,
        input wire [3:0] btn,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, accepted by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    	// privilege and security level of the transaction, and whether
    	// the transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    	// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    	// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, accepted by Slave)
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    	// valid data. There is one write strobe bit for each eight
    	// bits of the write data bus.
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		// Write valid. This signal indicates that valid write
    	// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    	// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    	// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    	// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    	// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, accepted by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    	// and security level of the transaction, and whether the
    	// transaction is a data access or an instruction access.
		input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    	// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    	// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    	// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
		// signaling the required read data.
		output wire  S_AXI_RVALID,
		output wire irq,
		// Read ready. This signal indicates that the master can
		// accept the read data and response information.
		input wire  S_AXI_RREADY
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 2;

	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 8
	reg  [C_S_AXI_DATA_WIDTH-1:0]	slv_reg0;   // event code latch
	reg  [C_S_AXI_DATA_WIDTH-1:0]	slv_reg1;   // event valid flag
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg2;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg3;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg4;
	wire [C_S_AXI_DATA_WIDTH-1:0]	slv_reg5;
	reg  [C_S_AXI_DATA_WIDTH-1:0]	slv_reg6;
	reg  [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;
	reg	 aw_en;

    // User logic internal wires
    wire [C_S_AXI_DATA_WIDTH-1:0] event_raw_data;
    wire event_trigger;

	// I/O Connections assignments
	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY		= axi_wready;
	assign S_AXI_BRESP		= axi_bresp;
	assign S_AXI_BVALID		= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA		= axi_rdata;
	assign S_AXI_RRESP		= axi_rresp;
	assign S_AXI_RVALID		= axi_rvalid;

	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	      aw_en <= 1'b1;
	    end
	  else
	    begin
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          axi_awready <= 1'b1;
	          aw_en <= 1'b0;
	        end
	      else if (S_AXI_BREADY && axi_bvalid)
	        begin
	          aw_en <= 1'b1;
	          axi_awready <= 1'b0;
	        end
	      else
	        begin
	          axi_awready <= 1'b0;
	        end
	    end
	end

	// Implement axi_awaddr latching
	// This process is used to latch the address when both
	// S_AXI_AWVALID and S_AXI_WVALID are valid.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end
	  else
	    begin
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
	        begin
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end
	end

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end
	  else
	    begin
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
	        begin
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end
	end

	// Implement memory mapped register select and write logic generation
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      slv_reg0 <= 0;
	      slv_reg1 <= 0;
	      slv_reg6 <= 0;
	      slv_reg7 <= 0;
	    end
	  else
	    begin
          //--------------------------------------------------
          // 1) HW event latch
          //--------------------------------------------------
          if (event_trigger)
            begin
              slv_reg0 <= event_raw_data;
              slv_reg1 <= 32'h00000001;
            end

          //--------------------------------------------------
          // 2) SW write
          //--------------------------------------------------
	      if (slv_reg_wren)
	        begin
	          case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )

	            3'h0:
                  begin
                    // slv_reg0 is HW-owned event register
                  end

	            3'h1:
                  begin
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                      if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                        slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                      end

                    // software clear: write 0 to reg1
                    if (S_AXI_WDATA == 0)
                      begin
                        slv_reg0 <= 0;
                        slv_reg1 <= 0;
                      end
                  end

	            3'h2:
                  begin
                    // slv_reg2 is HW counter read-only
                  end

	            3'h3:
                  begin
                    // slv_reg3 is HW counter read-only
                  end

	            3'h4:
                  begin
                    // slv_reg4 is HW counter read-only
                  end

	            3'h5:
                  begin
                    // slv_reg5 is HW counter read-only
                  end

	            3'h6:
	              begin
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                    slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                  end
                  end

	            3'h7:
	              begin
                    for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                    slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	                  end
                  end

	            default :
                  begin
	                slv_reg0 <= slv_reg0;
	                slv_reg1 <= slv_reg1;
	                slv_reg6 <= slv_reg6;
	                slv_reg7 <= slv_reg7;
	              end
	          endcase
	        end
	    end
	end

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end
	  else
	    begin
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0;
	        end
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid)
	            begin
	              axi_bvalid <= 1'b0;
	            end
	        end
	    end
	end

	// Implement axi_arready generation
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end
	  else
	    begin
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          axi_arready <= 1'b1;
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end
	end

	// Implement axi_rvalid generation
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end
	  else
	    begin
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0;
	        end
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          axi_rvalid <= 1'b0;
	        end
	    end
	end

	// Implement memory mapped register select and read logic generation
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

	always @(*)
	begin
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        3'h0   : reg_data_out <= slv_reg0;
	        3'h1   : reg_data_out <= slv_reg1;
	        3'h2   : reg_data_out <= slv_reg2;
	        3'h3   : reg_data_out <= slv_reg3;
	        3'h4   : reg_data_out <= slv_reg4;
	        3'h5   : reg_data_out <= slv_reg5;
	        3'h6   : reg_data_out <= slv_reg6;
	        3'h7   : reg_data_out <= slv_reg7;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end
	  else
	    begin
	      if (slv_reg_rden)
	        begin
	          axi_rdata <= reg_data_out;
	        end
	    end
	end

	// Add user logic here
    Zybo_Event_System_Top u_event_system (
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        .sw(sw),
        .btn(btn),

        // HW event output -> internal wires
        .reg_event_raw(event_raw_data),
        .reg_event_valid(event_trigger),

        // counters
        .btn0_count(slv_reg2),
        .btn1_count(slv_reg3),
        .btn2_count(slv_reg4),
        .btn3_count(slv_reg5),

        .led_data()
    );
	// User logic ends
    assign irq = slv_reg1[0];
    
	endmodule




`timescale 1 ns / 1 ps

	module My_Event_Reporter_IP_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
        // Users to add ports here
        input wire [3:0] sw,
        input wire [3:0] btn,
    // User ports ends
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		output wire irq,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
	My_Event_Reporter_IP_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) My_Event_Reporter_IP_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.sw(sw),   // 최상위 sw를 S00_AXI의 sw로 전달
        .btn(btn),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.irq(irq),
		.S_AXI_RREADY(s00_axi_rready)
	);

	// Add user logic here

	// User logic ends

	endmodule
