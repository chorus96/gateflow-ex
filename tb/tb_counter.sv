// tb_counter.sv — self-checking testbench for the counter reference design.
module tb_counter;
    parameter int WIDTH = 4;
    parameter int CLK_PERIOD = 10;

    logic             clk = 0;
    logic             rst_n = 0;
    logic             enable = 0;
    logic [WIDTH-1:0] count;

    int pass_count = 0;
    int fail_count = 0;

    counter #(.WIDTH(WIDTH)) u_dut (.*);

    always #(CLK_PERIOD/2) clk <= ~clk;

    task automatic check(string name, logic [WIDTH-1:0] expected);
        if (count !== expected) begin
            $display("FAIL: %s - got %0d, expected %0d", name, count, expected);
            fail_count++;
        end else begin
            $display("PASS: %s - count = %0d", name, count);
            pass_count++;
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_counter);

        // Reset
        rst_n = 0; enable = 0;
        repeat (3) @(posedge clk);
        check("Reset holds zero", '0);

        // Release reset
        rst_n = 1;
        @(posedge clk);
        check("After reset release (no enable)", '0);

        // Enable counting
        enable = 1;
        repeat (5) @(posedge clk);
        check("Count to 5", 4'd5);

        // Disable counting
        enable = 0;
        repeat (3) @(posedge clk);
        check("Holds at 5 when disabled", 4'd5);

        // Re-enable and wrap around
        enable = 1;
        repeat (11) @(posedge clk);
        check("Wraps around (5+11=0)", 4'd0);

        // Assert reset during count
        rst_n = 0;
        @(posedge clk);
        check("Reset clears count", '0);

        // Summary
        $display("");
        $display("================================");
        $display("  Results: %0d passed, %0d failed", pass_count, fail_count);
        $display("================================");

        if (fail_count > 0) begin
            $display("SIMULATION FAILED");
            $finish;
        end else begin
            $display("ALL TESTS PASSED");
            $finish;
        end
    end
endmodule
