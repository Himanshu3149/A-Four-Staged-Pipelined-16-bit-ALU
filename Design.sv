module ring_counter_2bit(
  input clk,           // Global clock input
  input reset,         // Reset signal
  output reg [1:0] ring_out // Ring counter output
);
  always @(posedge clk or posedge reset) begin
    if (reset)
      ring_out <= 2'b01;  // Initialize ring counter to 01
    else
      ring_out <= {ring_out[0], ring_out[1]};  // Shift left with wrap-around
  end
endmodule

module pipe_ALU (
  output [15:0] Zout, 
  input [3:0] rs1, rs2, rd, func,
  input [7:0] addr,
  input clk,        // Single clock input
  input reset       // Reset signal for the ring counter
);

reg [15:0] L12_A, L12_B, L23_Z, L34_Z;
reg [3:0] L12_rd, L12_func, L23_rd;
reg [7:0] L12_addr, L23_addr, L34_addr;

reg [15:0] regbank [0:15];  // register bank
reg [15:0] mem [0:255];  // 256 x 16 memory

wire [1:0] ring_out; // Ring counter output for clock control

// Instantiate ring counter
ring_counter_2bit rc (
  .clk(clk),
  .reset(reset),
  .ring_out(ring_out)
);

assign Zout = L34_Z;

// Stage-1 and Stage-3 (using ring_out == 01)
always @(posedge clk) begin
  if (ring_out == 2'b01) begin
    L12_A <= #2 regbank[rs1];
    L12_B <= #2 regbank[rs2];
    L12_rd <= #2 rd;
    L12_func <= #2 func;
    L12_addr <= #2 addr;
  end

  if (ring_out == 2'b01) begin
    regbank[L23_rd] <= #2 L23_Z;
    L34_Z <= #2 L23_Z;
    L34_addr <= #2 L23_addr;
  end
end

// Stage-2 and Stage-4 (using ring_out == 10)
always @(negedge clk) begin
  if (ring_out == 2'b10) begin
    case(func)
      0: L23_Z <= #2 L12_A + L12_B; // ADD
      1: L23_Z <= #2 L12_A - L12_B; // SUB
      2: L23_Z <= #2 L12_A * L12_B; // MUL
      3: L23_Z <= #2 L12_A;         // SELA
      4: L23_Z <= #2 L12_B;         // SELB
      5: L23_Z <= #2 L12_A & L12_B; // AND
      6: L23_Z <= #2 L12_A | L12_B; // OR
      7: L23_Z <= #2 L12_A ^ L12_B; // XOR
      8: L23_Z <= #2 ~L12_A;        // NEGA
      9: L23_Z <= #2 ~L12_B;        // NEGB
      10: L23_Z <= #2 L12_A >> 1;   // SRA
      11: L23_Z <= #2 L12_A << 1;   // SLA
      default: L23_Z <= #2 16'hxxxx;
    endcase
    L23_rd <= #2 L12_rd;
    L23_addr <= #2 L12_addr;
  end

  if (ring_out == 2'b10) begin
    mem[L34_addr] <= #2 L34_Z;
  end
end
endmodule
