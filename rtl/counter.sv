// counter.sv — parameterized up-counter with enable and async active-low reset.
// Reference design for the gateflow-ex example project.
module counter #(
    parameter int WIDTH = 4
) (
    input  logic             clk,
    input  logic             rst_n,   // Active-low asynchronous reset
    input  logic             enable,
    output logic [WIDTH-1:0] count
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= '0;
        else if (enable)
            count <= count + 1'b1;
    end

endmodule
