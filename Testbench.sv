module pipe_test;
  reg [3:0] rs1, rs2, rd, func;
  reg [7:0] addr;
  reg clk, reset;
  wire [15:0] Z;
  integer k;
  
  // Instantiate the updated pipe_ALU with a single clock and reset
  pipe_ALU MYPIPE (Z, rs1, rs2, rd, func, addr, clk, reset);
  
  initial
    begin
      $dumpfile("pipe_ALU.vcd"); // Generate waveform file
      $dumpvars(0, pipe_test);   // Record variable changes in the simulation
    end

  // Clock generation: Single clock for the ring counter
  initial
    begin
      clk = 0;
      repeat(40)  // 40 clock cycles
        #5 clk = ~clk;  // Toggle clock every 5 time units (10 ns cycle)
    end
  
  // Initialize the register bank
  initial 
    begin
      for(k = 0; k < 16; k = k + 1)  
        MYPIPE.regbank[k] = k;  // Initialize regbank with values [0, 15]
    end
  
  // Reset signal to initialize the ring counter
  initial
    begin
      reset = 1;      // Activate reset
      #10 reset = 0;  // Deactivate reset after 10 time units
    end

  // Provide inputs to the pipeline and check memory results
  initial 
    begin
      #15 rs1 = 3; rs2 = 5; rd = 10; func = 0; addr = 125; // ADD operation
      #40 rs1 = 3; rs2 = 8; rd = 12; func = 2; addr = 126; // MUL operation
      #40 rs1 = 10; rs2 = 5; rd = 14; func = 1; addr = 128; // SUB operation
      #40 rs1 = 7; rs2 = 3; rd = 13; func = 11; addr = 127; // SLA operation
      #40 rs1 = 10; rs2 = 5; rd = 15; func = 1; addr = 129; // SUB operation
      #40 rs1 = 12; rs2 = 13; rd = 16; func = 0; addr = 130; // ADD operation
      
      #100 for(k = 125; k < 131; k = k + 1)
        $display("mem[%3d]= %2d", k, MYPIPE.mem[k]);  // Display memory contents
    end
  
  // Monitor Zout value during the simulation
  initial
    begin
      $monitor("Time = %2d, Zout = %2d", $time, Z);  // Monitor Zout at every time step
      #500 $finish;  // End the simulation after 500 time units
    end
endmodule
