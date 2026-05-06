
`timescale 1 ns / 1 ps

	module RV32I_AXI_Bridge_master_lite_v1_0_M_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// The master will start generating data from the C_M_START_DATA_VALUE value
		parameter  C_M_START_DATA_VALUE	= 32'hAA000000,
		// The master requires a target slave base address.
    // The master will initiate read and write transactions on the slave with base address specified here as a parameter.
		parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
		// Width of M_AXI address bus. 
    // The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		// Width of M_AXI data bus. 
    // The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
		parameter integer C_M_AXI_DATA_WIDTH	= 32,
		// Transaction number is the number of write 
    // and read transactions the master will perform as a part of this example memory test.
		parameter integer C_M_TRANSACTIONS_NUM	= 4
	)
	(
		// Users to add ports here
        input wire [31:0] cpu_addr,
        input wire [31:0] cpu_wdata,
        input wire cpu_mem_en,
        input wire [3:0]  cpu_mem_wea,
        output wire [31:0] cpu_rdata,
        output wire cpu_stall,
		// User ports ends
		// Do not modify the ports beyond this line

		// Initiate AXI transactions
		input wire  INIT_AXI_TXN,
		// Asserts when ERROR is detected
		output reg  ERROR,
		// Asserts when AXI transactions is complete
		output wire  TXN_DONE,
		// AXI clock signal
		input wire  M_AXI_ACLK,
		// AXI active low reset signal
		input wire  M_AXI_ARESETN,
		// Master Interface Write Address Channel ports. Write address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Write channel Protection type.
    // This signal indicates the privilege and security level of the transaction,
    // and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Write address valid. 
    // This signal indicates that the master signaling valid write address and control information.
		output wire  M_AXI_AWVALID,
		// Write address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data Channel ports. Write data (issued by master)
		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. 
    // This signal indicates which byte lanes hold valid data.
    // There is one write strobe bit for each eight bits of the write data bus.
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write valid. This signal indicates that valid write data and strobes are available.
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave can accept the write data.
		input wire  M_AXI_WREADY,
		// Master Interface Write Response Channel ports. 
    // This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Write response valid. 
    // This signal indicates that the channel is signaling a valid write response
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master can accept a write response.
		output wire  M_AXI_BREADY,
		// Master Interface Read Address Channel ports. Read address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Protection type. 
    // This signal indicates the privilege and security level of the transaction, 
    // and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_ARPROT,
		// Read address valid. 
    // This signal indicates that the channel is signaling valid read address and control information.
		output wire  M_AXI_ARVALID,
		// Read address ready. 
    // This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_ARREADY,
		// Master Interface Read Data Channel ports. Read data (issued by slave)
		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer.
		input wire [1 : 0] M_AXI_RRESP,
		// Read valid. This signal indicates that the channel is signaling the required read data.
		input wire  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can accept the read data and response information.
		output wire  M_AXI_RREADY
	);

	// function called clogb2 that returns an integer which has the
	// value of the ceiling of the log base 2

	 function integer clogb2 (input integer bit_depth);
		 begin
		 for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			 bit_depth = bit_depth >> 1;
		 end
	 endfunction

	// TRANS_NUM_BITS is the width of the index counter for 
	// number of write or read transaction.
	 localparam integer TRANS_NUM_BITS = clogb2(C_M_TRANSACTIONS_NUM-1);

	// Example State machine to initialize counter, initialize write transactions, 
	// initialize read transactions and comparison of read data with the 
	// written data words.
	localparam [1:0] IDLE = 2'b00, // This state initiates AXI4Lite transaction 
			// after the state machine changes state to INIT_WRITE   
			// when there is 0 to 1 transition on INIT_AXI_TXN
		INIT_WRITE   = 2'b01, // This state initializes write transaction,
			// once writes are done, the state machine 
			// changes state to INIT_READ 
		INIT_READ = 2'b10, // This state initializes read transaction
			// once reads are done, the state machine 
			// changes state to INIT_COMPARE 
		INIT_COMPARE = 2'b11, // This state issues the status of comparison 
			// of the written data with the read data	
	  	WADDR = 2'b10, // This state initializes write address transaction 
	                      // once it is are done, the state machine 
	                    // changes state to WDATA 
	        WDATA = 2'b11, // This state issues the write data to slave 
	                   // once the write data is transferred to slave, state 
	                   // changes state to WADDR
	        RADDR = 2'b10, // This state initializes read address transaction
	                     // once it is are done, the state machine 
	                        // changes state to RDATA 
	        RDATA = 2'b11; // This state receives the read data from slave 
	                     // once the read data is transferred from slave, state 
	                    // changes state to WADDR 

	 reg [1:0] mst_exec_state;

	 reg [1:0] state_write;

	 reg [1:0] state_read;

	// AXI4LITE signals
	//write address valid
	reg  	axi_awvalid;
	//write data valid
	reg  	axi_wvalid;
	//read address valid
	reg  	axi_arvalid;
	//read data acceptance
	reg  	axi_rready;
	//write response acceptance
	reg  	axi_bready;
	//write address
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	//write data
	reg [C_M_AXI_DATA_WIDTH-1 : 0] 	axi_wdata;
	//read addresss
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	//Asserts when there is a write response error
	wire  	write_resp_error;
	//Asserts when there is a read response error
	wire  	read_resp_error;
	//flag that marks the completion of write trasactions. The number of write transaction is user selected by the parameter C_M_TRANSACTIONS_NUM.
	reg  	writes_done;
	//flag that marks the completion of read trasactions. The number of read transaction is user selected by the parameter C_M_TRANSACTIONS_NUM
	reg  	reads_done;
	//The error register is asserted when any of the write response error, read response error or the data mismatch flags are asserted.
	reg  	error_reg;
	//index counter to track the number of write transaction issued
	reg [TRANS_NUM_BITS : 0] 	write_index;
	//index counter to track the number of read transaction issued
	reg [TRANS_NUM_BITS : 0] 	read_index;
	//Expected read data used to compare with the read data.
	reg [C_M_AXI_DATA_WIDTH-1 : 0] 	expected_rdata;
	//Flag marks the completion of comparison of the read data with the expected read data
	reg  	compare_done;
	//This flag is asserted when there is a mismatch of the read data with the expected read data.
	reg  	read_mismatch;
	//Flag is asserted when the write index reaches the last write transction number
	reg  	last_write;
	//Flag is asserted when the read index reaches the last read transction number
	reg  	last_read;
	reg  	init_txn_ff;
	reg  	init_txn_ff2;
	reg  	init_txn_edge;
	wire  	init_txn_pulse;
                                                                               
	// Add user logic here

    // Direct mapping of address and data from CPU to data bus
    assign M_AXI_AWADDR  = cpu_addr;
    assign M_AXI_WDATA   = cpu_wdata;
    assign M_AXI_WSTRB   = cpu_mem_wea; 
    assign M_AXI_AWPROT  = 3'b000;      //Base privilege level
    
    assign M_AXI_ARADDR  = cpu_addr;
    assign M_AXI_ARPROT  = 3'b000;
    
    //map readed data to CPU
    assign cpu_rdata     = M_AXI_RDATA;


    // State machine for stall
    //Intern registers for VALID and READY
    reg axi_awvalid_reg;
    reg axi_wvalid_reg;
    reg axi_arvalid_reg;
    reg axi_bready_reg;
    reg axi_rready_reg;
    
    //Assign register to exit port of AXI
    assign M_AXI_AWVALID = axi_awvalid_reg;
    assign M_AXI_WVALID  = axi_wvalid_reg;
    assign M_AXI_ARVALID = axi_arvalid_reg;
    assign M_AXI_BREADY  = axi_bready_reg;
    assign M_AXI_RREADY  = axi_rready_reg;

    //look if is a store
    wire is_write = (cpu_mem_wea != 4'b0000); 

    //stall CPU
    reg txn_done;
    assign cpu_stall = cpu_mem_en & ~txn_done;

    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 1'b0) begin
            axi_awvalid_reg <= 1'b0;
            axi_wvalid_reg  <= 1'b0;
            axi_arvalid_reg <= 1'b0;
            axi_bready_reg  <= 1'b0;
            axi_rready_reg  <= 1'b0;
            txn_done        <= 1'b0;
        end else begin
            //Default value: transaction not end while not recive a response
            txn_done <= 1'b0;

            if (cpu_mem_en == 1'b1) begin
                if (is_write) begin
                    // STORE
                    // VALID Up
                    if (!axi_awvalid_reg && !axi_wvalid_reg && !axi_bready_reg && !txn_done) begin
                        axi_awvalid_reg <= 1'b1;
                        axi_wvalid_reg  <= 1'b1;
                        axi_bready_reg  <= 1'b1; // BVALID, ready to recive confirm
                    end
                    
                    // Put down VALID when slave is READY
                    if (M_AXI_AWREADY && axi_awvalid_reg) axi_awvalid_reg <= 1'b0;
                    if (M_AXI_WREADY  && axi_wvalid_reg)  axi_wvalid_reg  <= 1'b0;
                    
                    // 3. BVALID, arrive the response
                    if (M_AXI_BVALID && axi_bready_reg) begin
                        axi_bready_reg <= 1'b0;
                        txn_done       <= 1'b1; // CPU stall end
                    end
                end else begin
                    // LOAD
                    //VALID up
                    if (!axi_arvalid_reg && !axi_rready_reg && !txn_done) begin
                        axi_arvalid_reg <= 1'b1;
                        axi_rready_reg  <= 1'b1; //RVALID, ready to read
                    end
                    
                    //Address VALID down when slave take it
                    if (M_AXI_ARREADY && axi_arvalid_reg) axi_arvalid_reg <= 1'b0;
                    
                    //RVALID, data arrived
                    if (M_AXI_RVALID && axi_rready_reg) begin
                        axi_rready_reg <= 1'b0;
                        txn_done       <= 1'b1; //CPU stall end
                    end
                end
            end else begin
                // reset all
                axi_awvalid_reg <= 1'b0;
                axi_wvalid_reg  <= 1'b0;
                axi_arvalid_reg <= 1'b0;
                axi_bready_reg  <= 1'b0;
                axi_rready_reg  <= 1'b0;
                txn_done        <= 1'b0;
            end
        end
    end

	// User logic ends

	endmodule
