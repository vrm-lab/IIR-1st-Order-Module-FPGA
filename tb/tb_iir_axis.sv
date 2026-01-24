`timescale 1ns / 1ps

module tb_iir_axis;

    // =========================================================================
    // Parameters & Signals
    // =========================================================================
    parameter integer DATA_WIDTH = 32; // Fixed 32-bit (16L + 16R)
    parameter integer ADDR_WIDTH = 4;
    
    reg aclk;
    reg aresetn;

    // AXI4-Stream Slave (Input)
    reg  [DATA_WIDTH-1:0] s_axis_tdata;
    reg                   s_axis_tvalid;
    wire                  s_axis_tready;
    reg                   s_axis_tlast;

    // AXI4-Stream Master (Output)
    wire [DATA_WIDTH-1:0] m_axis_tdata;
    wire                  m_axis_tvalid;
    reg                   m_axis_tready;
    wire                  m_axis_tlast;

    // AXI4-Lite Slave (Control)
    reg  [ADDR_WIDTH-1:0] s_axi_awaddr;
    reg                   s_axi_awvalid;
    wire                  s_axi_awready;
    
    reg  [31:0]           s_axi_wdata;
    reg  [3:0]            s_axi_wstrb;
    reg                   s_axi_wvalid;
    wire                  s_axi_wready;
    
    wire [1:0]            s_axi_bresp;
    wire                  s_axi_bvalid;
    reg                   s_axi_bready;

    reg  [ADDR_WIDTH-1:0] s_axi_araddr;
    reg                   s_axi_arvalid;
    wire                  s_axi_arready;
    
    wire [31:0]           s_axi_rdata;
    wire [1:0]            s_axi_rresp;
    wire                  s_axi_rvalid;
    reg                   s_axi_rready;

    // Helper Fixed Point Q1.15
    localparam signed [15:0] COEFF_ONE  = 16'd32767; 
    localparam signed [15:0] COEFF_ZERO = 16'd0;
    localparam signed [15:0] COEFF_HALF = 16'd16384;

    // =========================================================================
    // Instantiation (STEREO WRAPPER)
    // =========================================================================
    iir_orde1_axis_wrapper #(
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(4),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),

        // AXI Lite Ports
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready)
    );

    // =========================================================================
    // Clock & Reset
    // =========================================================================
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk; // 100 MHz
    end

    // =========================================================================
    // Tasks
    // =========================================================================

    // Task Write AXI-Lite
    task axi_write(input [3:0] addr, input [31:0] data);
        begin
            @(posedge aclk);
            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1;
            s_axi_wdata   <= data;
            s_axi_wvalid  <= 1;
            s_axi_wstrb   <= 4'hF;
            s_axi_bready  <= 0;

            wait(s_axi_awready && s_axi_wready);
            
            @(posedge aclk);
            s_axi_awvalid <= 0;
            s_axi_wvalid  <= 0;

            s_axi_bready <= 1;
            wait(s_axi_bvalid);
            @(posedge aclk);
            s_axi_bready <= 0;
        end
    endtask

    // Task Kirim Data Stream (STEREO)
    task send_stream_data(input signed [15:0] left_in, input signed [15:0] right_in, input last_flag);
        begin
            wait(s_axis_tready);
            @(posedge aclk);
            // Packing Stereo: [31:16] Left, [15:0] Right
            s_axis_tdata  <= { left_in, right_in }; 
            s_axis_tvalid <= 1;
            s_axis_tlast  <= last_flag;
            
            @(posedge aclk);
            while (!s_axis_tready) @(posedge aclk);
            
            s_axis_tvalid <= 0;
            s_axis_tlast  <= 0;
        end
    endtask

    // =========================================================================
    // Main Stimulus
    // =========================================================================
    integer i;
    integer fd_axis;

    initial begin
        // 1. Inisialisasi Sinyal (Cegah Sinyal Merah/X)
        fd_axis = 0;
        i = 0;
        aclk = 0;
        aresetn = 0;
        
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        s_axis_tdata = 0;
        m_axis_tready = 1; // Downstream selalu siap
        
        // Init AXI Lite Inputs to 0
        s_axi_awaddr = 0; s_axi_awvalid = 0;
        s_axi_wdata = 0;  s_axi_wvalid = 0; s_axi_wstrb = 0;
        s_axi_bready = 0;
        s_axi_araddr = 0; s_axi_arvalid = 0; s_axi_rready = 0;

        // Reset Pulse
        repeat(10) @(posedge aclk);
        aresetn = 1;
        repeat(5) @(posedge aclk);

        $display("---------------------------------------------------");
        $display("TEST CASE 1: Pass Through (Stereo)");
        $display("Set a0=1.0, a1=0, b1=0");
        $display("Input: L=10000, R=-5000");
        $display("---------------------------------------------------");
        fd_axis = $fopen("axis_impulse.txt", "w");

        // Konfigurasi Koefisien (Pass Through)
        axi_write(4'h04, {16'd0, COEFF_ONE});  
        axi_write(4'h08, {16'd0, COEFF_ZERO}); 
        axi_write(4'h0C, {16'd0, COEFF_ZERO}); 

        // Reset Filter State (Clear=1)
        axi_write(4'h00, 32'h0000_0003); 
        // Enable Run (Clear=0, Enable=1) -> PENTING!
        axi_write(4'h00, 32'h0000_0001); 

        repeat(5) @(posedge aclk);
        
        // Kirim 5 Sample Stereo
        // Sample 1: Impulse L, Negatif R
        send_stream_data(16'd10000, -16'd5000, 0); 
        // Sample 2-5: Nol
        for(i=0; i<4; i=i+1) begin
            send_stream_data(16'd0, 16'd0, (i==3));
        end

        repeat(10) @(posedge aclk);

        $display("\n---------------------------------------------------");
        $display("TEST CASE 2: Low Pass Filter (Stereo)");
        $display("Set a0=0.5, b1=0.5");
        $display("Input: L=Impulse, R=Impulse (Harusnya Decay sama)");
        $display("---------------------------------------------------");

        // Update Koefisien LPF
        axi_write(4'h04, {16'd0, COEFF_HALF}); 
        axi_write(4'h08, {16'd0, COEFF_ZERO}); 
        axi_write(4'h0C, {16'd0, COEFF_HALF}); 
        
        // Clear State dulu biar bersih
        axi_write(4'h00, 32'h0000_0003);       
        // Jalankan Filter
        axi_write(4'h00, 32'h0000_0001);       

        repeat(5) @(posedge aclk);

        // Kirim Impulse Stereo (Kiri dan Kanan sama-sama 10000)
        send_stream_data(16'd10000, 16'd10000, 0); 
        for(i=0; i<4; i=i+1) begin
            send_stream_data(16'd0, 16'd0, (i==3));
        end

        repeat(20) @(posedge aclk);
        $display("Simulation Done.");
        $fclose(fd_axis);
        $finish;
    end

    // =========================================================================
    // Monitor Output (Unpack Stereo)
    // =========================================================================
    always @(posedge aclk) begin
        if (m_axis_tvalid && m_axis_tready) begin
            $display("AXIS | L=%d | R=%d",
                      $signed(m_axis_tdata[31:16]),
                      $signed(m_axis_tdata[15:0])
            );
            $fwrite(fd_axis, "%0d %0d\n",
                      $signed(m_axis_tdata[31:16]),
                      $signed(m_axis_tdata[15:0])
            );
        end
    end

endmodule