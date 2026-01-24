`timescale 1ns/1ps

module tb_iir_orde1_core;

    // ============================================================
    // Parameter
    // ============================================================
    localparam CLK_PERIOD = 20833; // ~48 kHz (1 / 48kHz = 20.833 us)

    reg clk;
    reg rst;
    reg en;
    reg clear_state;

    reg  signed [15:0] x_in;
    wire signed [15:0] y_out;

    // Koef IIR (Q1.15)
    reg signed [15:0] a0;
    reg signed [15:0] a1;
    reg signed [15:0] b1;

    // ============================================================
    // DUT
    // ============================================================
    iir_orde1_core dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .clear_state(clear_state),
        .x_in(x_in),
        .y_out(y_out),
        .a0(a0),
        .a1(a1),
        .b1(b1)
    );

    // ============================================================
    // Clock
    // ============================================================
    always #(CLK_PERIOD/2) clk = ~clk;

    // ============================================================
    // Test Sequence
    // ============================================================
    integer i;
    real phase;
    real sine;
    integer fd_step;
    integer fd_sine;

    initial begin
        $display("=== TB IIR ORDE-1 START ===");
        fd_step = 0;
        fd_sine = 0;
        i = 0;
        clk = 0;
        rst = 1;
        en  = 0;
        clear_state = 0;
        x_in = 0;
        fd_step = $fopen("step_response.txt", "w");
        fd_sine = $fopen("sine_response.txt", "w");


        // --------------------------------------------------------
        // LPF Orde-1 contoh (fc ~100 Hz @ 48 kHz)
        // alpha ≈ 0.013
        // y[n] = alpha*x[n] + (1-alpha)*y[n-1]
        // --------------------------------------------------------
        a0 = 16'sd426;      // 0.013 * 32768
        a1 = 16'sd0;
        b1 = 16'sd32342;   // (1 - 0.013) * 32768

        # (10*CLK_PERIOD);

        rst = 0;
        en  = 1;

        // --------------------------------------------------------
        // Clear State
        // --------------------------------------------------------
        clear_state = 1;
        #CLK_PERIOD;
        clear_state = 0;

        // ========================================================
        // TEST 1: Step Response
        // ========================================================
        $display("=== STEP RESPONSE ===");
        
        // Pastikan input awal nol
        x_in = 0;
        repeat (50) @(posedge clk);
        
        // Apply step sinkron dengan clock
        @(posedge clk);
        x_in = 16'sd16000;
        
        // Tunggu pipeline & feedback settle
        repeat (5) @(posedge clk);
        
        // Baru mulai logging
        repeat (200) begin
            @(posedge clk);
            $display("STEP | x=%d | y=%d", x_in, y_out);
            $fwrite(fd_step, "%0d\n", y_out);
        end
        
        // --------------------------------------------------------
        // Clear State
        // --------------------------------------------------------
        clear_state = 1;
        #CLK_PERIOD;
        clear_state = 0;

        // ========================================================
        // TEST 2: Sine 100 Hz
        // ========================================================
        $display("=== SINE 100 Hz ===");
        phase = 0.0;

        for (i = 0; i < 400; i = i + 1) begin
            sine  = $sin(phase);
            x_in  = $rtoi(sine * 16000);
            phase = phase + 2.0 * 3.141592 * 100.0 / 48000.0;

            @(posedge clk);
            $display("SINE | x=%d | y=%d", x_in, y_out);
            $fwrite(fd_sine, "%0d %0d\n", x_in, y_out);
        end

        // ========================================================
        // END
        // ========================================================
        $display("=== TB DONE ===");
        
        $fclose(fd_step);
        $fclose(fd_sine);
        $finish;
    end

endmodule
