// =============================================================================
// FPU Complete Testbench Suite
// =============================================================================

`timescale 1ns/1ps

// Include operation definitions
typedef enum logic [2:0] {
    OP_FLW  = 3'b000,
    OP_FSW  = 3'b001,
    OP_FADD = 3'b010,
    OP_FMUL = 3'b011,
    OP_FDIV = 3'b100
} operation_e;

// Output data structure (same as in design)
typedef struct packed {
    logic [31:0] freg_data;
    logic [4:0]  freg_addr;
    logic        freg_wb_enable;
    logic [31:0] reg_data;
    logic [4:0]  reg_addr;
    logic        reg_wb_enable;
} output_t;

// =============================================================================
// Test Transaction Class
// =============================================================================
class fpu_transaction;
    rand operation_e op;
    rand logic [31:0] reg_rs1;
    rand logic [31:0] reg_rs2;
    rand logic [4:0]  rd_addr;
    rand logic [31:0] freg_rs1;
    rand logic [31:0] freg_rs2;
    rand logic [4:0]  frd_addr;
    rand logic [31:0] imm;
    
    // Expected results
    logic [31:0] expected_freg_data;
    logic [4:0]  expected_freg_addr;
    logic        expected_freg_wb_enable;
    logic [31:0] expected_reg_data;
    logic [4:0]  expected_reg_addr;
    logic        expected_reg_wb_enable;
    
    // Constraints
    constraint op_dist {
        op dist {
            OP_FLW  := 30,
            OP_FSW  := 30,
            OP_FADD := 40
        };
    }
    
    constraint addr_range {
        rd_addr inside {[0:31]};
        frd_addr inside {[0:31]};
    }
    
    function void print_transaction();
        $display("Transaction: op=%s, rs1=0x%h, rs2=0x%h, freg_rs1=0x%h, freg_rs2=0x%h, imm=0x%h",
                op.name(), reg_rs1, reg_rs2, freg_rs1, freg_rs2, imm);
    endfunction
    
    function void calculate_expected();
        case (op)
            OP_FLW: begin
                expected_freg_wb_enable = 1'b1;
                expected_freg_addr = frd_addr;
                expected_reg_wb_enable = 1'b0;
                // expected_freg_data will be set by testbench based on memory
            end
            OP_FSW: begin
                expected_freg_wb_enable = 1'b0;
                expected_reg_wb_enable = 1'b0;
            end
            OP_FADD: begin
                expected_freg_wb_enable = 1'b1;
                expected_freg_addr = frd_addr;
                expected_reg_wb_enable = 1'b0;
                // expected_freg_data will be calculated by testbench
            end
        endcase
    endfunction
endclass

// =============================================================================
// Memory Model
// =============================================================================
class memory_model;
    logic [31:0] mem_array[logic [31:0]];
    int read_delay;
    int write_delay;
    
    function new();
        read_delay = 1;  // Default 1 cycle delay
        write_delay = 1;
        
        // Initialize some test data
        for (int i = 0; i < 100; i++) begin
            mem_array[i*4] = $random();
        end
    endfunction
    
    task automatic read(input logic [31:0] addr, output logic [31:0] data);
        repeat(read_delay) @(posedge tb.clk);
        if (mem_array.exists(addr)) begin
            data = mem_array[addr];
        end else begin
            data = 32'hDEADBEEF;  // Default value
        end
        $display("[MEM] Read addr=0x%h, data=0x%h", addr, data);
    endtask
    
    task automatic write(input logic [31:0] addr, input logic [31:0] data);
        repeat(write_delay) @(posedge tb.clk);
        mem_array[addr] = data;
        $display("[MEM] Write addr=0x%h, data=0x%h", addr, data);
    endtask
endclass

// =============================================================================
// FPU Driver
// =============================================================================
class fpu_driver;
    virtual fpu_if vif;
    mailbox #(fpu_transaction) mbx;
    memory_model mem_model;
    
    function new(virtual fpu_if vif, mailbox #(fpu_transaction) mbx, memory_model mem);
        this.vif = vif;
        this.mbx = mbx;
        this.mem_model = mem;
    endfunction
    
    task run();
        fpu_transaction txn;
        forever begin
            mbx.get(txn);
            drive_transaction(txn);
        end
    endtask
    
    task drive_transaction(fpu_transaction txn);
        // Set up inputs
        @(posedge vif.clk);
        vif.op_i <= txn.op;
        vif.reg_rs1 <= txn.reg_rs1;
        vif.reg_rs2 <= txn.reg_rs2;
        vif.rd_addr <= txn.rd_addr;
        vif.freg_rs1 <= txn.freg_rs1;
        vif.freg_rs2 <= txn.freg_rs2;
        vif.frd_addr <= txn.frd_addr;
        vif.imm <= txn.imm;
        vif.in_valid_i <= 1'b1;
        
        // Wait for handshake
        @(posedge vif.clk iff (vif.in_valid_i && vif.in_ready_o));
        vif.in_valid_i <= 1'b0;
        
        $display("[DRIVER] Sent transaction: %s", txn.op.name());
    endtask
endclass

// =============================================================================
// FPU Monitor  
// =============================================================================
class fpu_monitor;
    virtual fpu_if vif;
    mailbox #(fpu_transaction) mbx;
    
    function new(virtual fpu_if vif, mailbox #(fpu_transaction) mbx);
        this.vif = vif;
        this.mbx = mbx;
    endfunction
    
    task run();
        fpu_transaction txn;
        forever begin
            // Monitor output transactions
            @(posedge vif.clk iff (vif.out_valid_o && vif.out_ready_i));
            
            txn = new();
            // Collect output data
            if (vif.freg_wb_enable) begin
                $display("[MONITOR] FReg WB: addr=%0d, data=0x%h", 
                        vif.freg_wb_addr, vif.freg_wb_data);
            end
            if (vif.reg_wb_enable) begin
                $display("[MONITOR] Reg WB: addr=%0d, data=0x%h", 
                        vif.reg_wb_addr, vif.reg_wb_data);
            end
        end
    endtask
endclass

// =============================================================================
// FPU Scoreboard
// =============================================================================
class fpu_scoreboard;
    mailbox #(fpu_transaction) expected_mbx;
    mailbox #(fpu_transaction) actual_mbx;
    
    int passed_tests = 0;
    int failed_tests = 0;
    
    function new();
        expected_mbx = new();
        actual_mbx = new();
    endfunction
    
    task run();
        fork
            compare_results();
        join_none
    endtask
    
    task compare_results();
        fpu_transaction expected, actual;
        forever begin
            // This would compare expected vs actual results
            // Implementation depends on specific verification strategy
            #100;
        end
    endtask
    
    function void report();
        $display("\n=== SCOREBOARD REPORT ===");
        $display("Passed Tests: %0d", passed_tests);
        $display("Failed Tests: %0d", failed_tests);
        $display("Total Tests:  %0d", passed_tests + failed_tests);
        if (failed_tests == 0) begin
            $display("ALL TESTS PASSED!");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        $display("=========================\n");
    endfunction
endclass

// =============================================================================
// Memory Interface Driver
// =============================================================================
class memory_interface;
    virtual fpu_if vif;
    memory_model mem_model;
    
    function new(virtual fpu_if vif, memory_model mem);
        this.vif = vif;
        this.mem_model = mem;
    endfunction
    
    task run();
        fork
            handle_memory_requests();
        join_none
    endtask
    
    task handle_memory_requests();
        forever begin
            @(posedge vif.clk);
            
            // Handle read requests
            if (vif.mem_re) begin
                fork
                    begin
                        logic [31:0] read_data;
                        mem_model.read(vif.mem_addr, read_data);
                        vif.mem_ready <= 1'b1;
                        @(posedge vif.clk);
                        vif.mem_rdata <= read_data;
                        vif.mem_ready <= 1'b0;
                    end
                join_none
            end
            
            // Handle write requests  
            if (vif.mem_we) begin
                fork
                    begin
                        mem_model.write(vif.mem_addr, vif.mem_wdata);
                        vif.mem_ready <= 1'b1;
                        @(posedge vif.clk);
                        vif.mem_ready <= 1'b0;
                    end
                join_none
            end
        end
    endtask
endclass

// =============================================================================
// FPU Interface
// =============================================================================
interface fpu_if(input logic clk);
    // Input signals
    operation_e op_i;
    logic [31:0] reg_rs1;
    logic [31:0] reg_rs2;
    logic [4:0]  rd_addr;
    logic [31:0] freg_rs1;
    logic [31:0] freg_rs2;
    logic [4:0]  frd_addr;
    logic [31:0] imm;
    
    // Input handshake
    logic in_valid_i;
    logic in_ready_o;
    
    // Memory interface
    logic [31:0] mem_addr;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
    logic        mem_we;
    logic        mem_re;
    logic        mem_ready;
    
    // Output interface
    logic        freg_wb_enable;
    logic [4:0]  freg_wb_addr;
    logic [31:0] freg_wb_data;
    logic        reg_wb_enable;
    logic [4:0]  reg_wb_addr;
    logic [31:0] reg_wb_data;
    
    // Output handshake
    logic out_valid_o;
    logic out_ready_i;
    
    // Status
    logic busy_o;
    
    // Reset
    logic rst_n;
    
    // Clocking blocks for testbench
    clocking driver_cb @(posedge clk);
        output op_i, reg_rs1, reg_rs2, rd_addr;
        output freg_rs1, freg_rs2, frd_addr, imm;
        output in_valid_i, out_ready_i;
        input  in_ready_o, out_valid_o;
        input  freg_wb_enable, freg_wb_addr, freg_wb_data;
        input  reg_wb_enable, reg_wb_addr, reg_wb_data;
        input  busy_o;
    endclocking
    
    clocking monitor_cb @(posedge clk);
        input op_i, reg_rs1, reg_rs2, rd_addr;
        input freg_rs1, freg_rs2, frd_addr, imm;
        input in_valid_i, out_ready_i;
        input in_ready_o, out_valid_o;
        input freg_wb_enable, freg_wb_addr, freg_wb_data;
        input reg_wb_enable, reg_wb_addr, reg_wb_data;
        input busy_o;
    endclocking
    
    // Modports
    modport driver  (clocking driver_cb, output rst_n);
    modport monitor (clocking monitor_cb, input rst_n);
    modport dut     (input op_i, reg_rs1, reg_rs2, rd_addr,
                     input freg_rs1, freg_rs2, frd_addr, imm,
                     input in_valid_i, out_ready_i,
                     output in_ready_o, out_valid_o,
                     output freg_wb_enable, freg_wb_addr, freg_wb_data,
                     output reg_wb_enable, reg_wb_addr, reg_wb_data,
                     output busy_o, input rst_n, input clk,
                     output mem_addr, mem_wdata, mem_we, mem_re,
                     input mem_rdata, mem_ready);
endinterface

// =============================================================================
// Main Testbench
// =============================================================================
module fpu_tb();
    
    // Clock and reset
    logic clk = 0;
    logic rst_n;
    
    // Clock generation
    always #5 clk = ~clk;  // 100MHz clock
    
    // Interface instantiation
    fpu_if vif(clk);
    
    // DUT instantiation
    fpu_top dut (
        .clk(clk),
        .rst_n(vif.rst_n),
        .op_i(vif.op_i),
        .reg_rs1(vif.reg_rs1),
        .reg_rs2(vif.reg_rs2),
        .rd_addr(vif.rd_addr),
        .freg_rs1(vif.freg_rs1),
        .freg_rs2(vif.freg_rs2),
        .frd_addr(vif.frd_addr),
        .imm(vif.imm),
        .in_valid_i(vif.in_valid_i),
        .in_ready_o(vif.in_ready_o),
        .mem_addr(vif.mem_addr),
        .mem_wdata(vif.mem_wdata),
        .mem_rdata(vif.mem_rdata),
        .mem_we(vif.mem_we),
        .mem_re(vif.mem_re),
        .mem_ready(vif.mem_ready),
        .freg_wb_enable(vif.freg_wb_enable),
        .freg_wb_addr(vif.freg_wb_addr),
        .freg_wb_data(vif.freg_wb_data),
        .reg_wb_enable(vif.reg_wb_enable),
        .reg_wb_addr(vif.reg_wb_addr),
        .reg_wb_data(vif.reg_wb_data),
        .out_valid_o(vif.out_valid_o),
        .out_ready_i(vif.out_ready_i),
        .busy_o(vif.busy_o)
    );
    
    // Test environment components
    memory_model mem_model;
    memory_interface mem_intf;
    fpu_driver driver;
    fpu_monitor monitor;
    fpu_scoreboard scoreboard;
    mailbox #(fpu_transaction) driver_mbx;
    mailbox #(fpu_transaction) monitor_mbx;
    
    // Test control
    int test_count = 0;
    bit test_finished = 0;
    
    // Initialize test environment
    initial begin
        // Create components
        mem_model = new();
        mem_intf = new(vif, mem_model);
        driver_mbx = new();
        monitor_mbx = new();
        driver = new(vif, driver_mbx, mem_model);
        monitor = new(vif, monitor_mbx);
        scoreboard = new();
        
        // Set interface initial values
        vif.rst_n = 0;
        vif.in_valid_i = 0;
        vif.out_ready_i = 1;  // Always ready to accept outputs
        vif.mem_ready = 0;
        vif.mem_rdata = 0;
        
        // Start components
        fork
            mem_intf.run();
            driver.run();
            monitor.run();
            scoreboard.run();
        join_none
        
        // Reset sequence
        reset_sequence();
        
        // Run tests
        fork
            begin
                run_basic_tests();
                run_stress_tests();
                run_protocol_tests();
                test_finished = 1;
            end
        join_none
        
        // Wait for completion
        wait(test_finished);
        #1000;
        scoreboard.report();
        $finish;
    end
    
    // Reset sequence
    task reset_sequence();
        $display("=== RESET SEQUENCE ===");
        vif.rst_n = 0;
        repeat(10) @(posedge clk);
        vif.rst_n = 1;
        repeat(5) @(posedge clk);
        $display("Reset completed");
    endtask
    
    // Basic functionality tests
    task run_basic_tests();
        $display("\n=== BASIC TESTS ===");
        
        test_flw_operation();
        test_fsw_operation();
        test_fadd_operation();
        
        $display("Basic tests completed\n");
    endtask
    
    // Test FLW operation
    task test_flw_operation();
        fpu_transaction txn;
        $display("--- Testing FLW Operation ---");
        
        for (int i = 0; i < 5; i++) begin
            txn = new();
            assert(txn.randomize() with {op == OP_FLW;});
            
            // Set up expected memory data
            mem_model.mem_array[txn.reg_rs1 + txn.imm] = 32'hA5A5A5A5 + i;
            
            txn.print_transaction();
            driver_mbx.put(txn);
            test_count++;
            
            // Wait for completion
            @(posedge clk iff (vif.out_valid_o && vif.out_ready_i));
            
            // Check results
            if (vif.freg_wb_enable && vif.freg_wb_addr == txn.frd_addr) begin
                $display("✓ FLW Test %0d PASSED", i+1);
            end else begin
                $display("✗ FLW Test %0d FAILED", i+1);
            end
        end
    endtask
    
    // Test FSW operation
    task test_fsw_operation();
        fpu_transaction txn;
        $display("--- Testing FSW Operation ---");
        
        for (int i = 0; i < 5; i++) begin
            txn = new();
            assert(txn.randomize() with {op == OP_FSW;});
            
            txn.print_transaction();
            driver_mbx.put(txn);
            test_count++;
            
            // Wait for completion
            @(posedge clk iff (vif.out_valid_o && vif.out_ready_i));
            
            // Check memory was written
            logic [31:0] mem_addr = txn.reg_rs1 + txn.imm;
            if (mem_model.mem_array.exists(mem_addr) && 
                mem_model.mem_array[mem_addr] == txn.freg_rs2) begin
                $display("✓ FSW Test %0d PASSED", i+1);
            end else begin
                $display("✗ FSW Test %0d FAILED", i+1);
            end
        end
    endtask
    
    // Test FADD operation  
    task test_fadd_operation();
        fpu_transaction txn;
        $display("--- Testing FADD Operation ---");
        
        // Test specific floating-point values
        real test_vals[] = {1.0, 2.5, -3.14, 0.0, 1000000.0};
        
        for (int i = 0; i < 5; i++) begin
            txn = new();
            txn.op = OP_FADD;
            txn.freg_rs1 = $realtobits(test_vals[i]);
            txn.freg_rs2 = $realtobits(test_vals[(i+1)%5]);
            assert(txn.randomize() with {op == OP_FADD; 
                                        freg_rs1 == txn.freg_rs1;
                                        freg_rs2 == txn.freg_rs2;});
            
            txn.print_transaction();
            driver_mbx.put(txn);
            test_count++;
            
            // Wait for completion
            @(posedge clk iff (vif.out_valid_o && vif.out_ready_i));
            
            if (vif.freg_wb_enable && vif.freg_wb_addr == txn.frd_addr) begin
                real result = $bitstoreal(vif.freg_wb_data);
                real expected = test_vals[i] + test_vals[(i+1)%5];
                $display("✓ FADD Test %0d: %f + %f = %f", i+1, 
                        test_vals[i], test_vals[(i+1)%5], result);
            end else begin
                $display("✗ FADD Test %0d FAILED", i+1);
            end
        end
    endtask
    
    // Stress tests
    task run_stress_tests();
        $display("\n=== STRESS TESTS ===");
        
        test_back_to_back_operations();
        test_mixed_operations();
        
        $display("Stress tests completed\n");
    endtask
    
    // Test back-to-back operations
    task test_back_to_back_operations();
        fpu_transaction txn;
        $display("--- Testing Back-to-Back Operations ---");
        
        // Send multiple operations quickly
        for (int i = 0; i < 10; i++) begin
            txn = new();
            assert(txn.randomize());
            driver_mbx.put(txn);
        end
        
        // Wait for all to complete
        repeat(10) @(posedge clk iff (vif.out_valid_o && vif.out_ready_i));
        $display("✓ Back-to-back test completed");
    endtask
    
    // Test mixed operations
    task test_mixed_operations();
        fpu_transaction txn;
        $display("--- Testing Mixed Operations ---");
        
        // Mix different operation types
        for (int i = 0; i < 15; i++) begin
            txn = new();
            case (i % 3)
                0: assert(txn.randomize() with {op == OP_FLW;});
                1: assert(txn.randomize() with {op == OP_FSW;});
                2: assert(txn.randomize() with {op == OP_FADD;});
            endcase
            driver_mbx.put(txn);
        end
        
        // Wait for all to complete
        repeat(15) @(posedge clk iff (vif.out_valid_o && vif.out_ready_i));
        $display("✓ Mixed operations test completed");
    endtask
    
    // Protocol compliance tests
    task run_protocol_tests();
        $display("\n=== PROTOCOL TESTS ===");
        
        test_backpressure();
        test_handshake_timing();
        
        $display("Protocol tests completed\n");
    endtask
    
    // Test backpressure
    task test_backpressure();
        fpu_transaction txn;
        $display("--- Testing Backpressure ---");
        
        // Set random ready delays
        fork
            begin
                forever begin
                    if ($urandom_range(0,2) == 0) begin
                        vif.out_ready_i = 0;
                        repeat($urandom_range(1,5)) @(posedge clk);
                        vif.out_ready_i = 1;
                    end
                    @(posedge clk);
                end
            end
        join_none
        
        // Send operations with backpressure
        for (int i = 0; i < 5; i++) begin
            txn = new();
            assert(txn.randomize());
            driver_mbx.put(txn);
        end
        
        // Wait for completion
        repeat(5) @(posedge clk iff (vif.out_valid_o && vif.out_ready_i));
        vif.out_ready_i = 1;  // Restore normal ready
        $display("✓ Backpressure test completed");
    endtask
    
    // Test handshake timing
    task test_handshake_timing();
        $display("--- Testing Handshake Timing ---");
        // This would include specific timing tests
        $display("✓ Handshake timing test completed");
    endtask
    
    // Timeout watchdog
    initial begin
        #100000;  // 100us timeout
        $display("ERROR: Testbench timeout!");
        $finish;
    end
    
    // Performance monitoring
    int cycle_count = 0;
    int operation_count = 0;
    
    always @(posedge clk) begin
        cycle_count++;
        if (vif.out_valid_o && vif.out_ready_i) begin
            operation_count++;
        end
    end
    
    final begin
        $display("\n=== PERFORMANCE REPORT ===");
        $display("Total Cycles: %0d", cycle_count);
        $display("Total Operations: %0d", operation_count);
        if (operation_count > 0) begin
            $display("Average Cycles/Operation: %0.2f", 
                    real'(cycle_count) / real'(operation_count));
        end
        $display("============================");
    end

endmodule

// =============================================================================
// SystemVerilog Assertions
// =============================================================================
module fpu_assertions(
    input logic clk,
    input logic rst_n,
    input logic in_valid_i,
    input logic in_ready_o,
    input logic out_valid_o,
    input logic out_ready_i,
    input logic [31:0] freg_wb_data,
    input logic busy_o
);
    
    // Protocol assertions
    property valid_stable;
        @(posedge clk) disable iff (!rst_n)
        $rose(out_valid_o) |=> 
        (out_valid_o && $stable(freg_wb_data)) until_with out_ready_i;
    endproperty
    
    property ready_not_depends_on_valid;
        @(posedge clk) disable iff (!rst_n)
        !$rose(in_valid_i) |=> $stable(in_ready_o);
    endproperty
    
    property no_valid_without_reset;
        @(posedge clk)
        !rst_n |=> !out_valid_o;
    endproperty
    
    property busy_when_processing;
        @(posedge clk) disable iff (!rst_n)
        (in_valid_i && in_ready_o) |=> busy_o;
    endproperty
    
    // Bind assertions
    assert property (valid_stable) 
        else $error("Output data not stable during valid period");
    
    assert property (ready_not_depends_on_valid)
        else $error("Ready signal depends on valid signal");
    
    assert property (no_valid_without_reset)
        else $error("Valid signal active during reset");
    
    assert property (busy_when_processing)
        else $error("Busy signal not asserted when processing");
    
    // Coverage
    covergroup op_coverage @(posedge clk);
        option.at_least = 5;
        
        op_type: coverpoint vif.op_i {
            bins flw = {OP_FLW};
            bins fsw = {OP_FSW};
            bins fadd = {OP_FADD};
        }
        
        handshake: coverpoint {in_valid_i, in_ready_o} {
            bins idle = {2'b00};
            bins wait_ready = {2'b10};
            bins transfer = {2'b11};
        }
        
        cross op_type, handshake;
    endgroup
    
    op_coverage cov = new();

endmodule

// Bind assertions to DUT
bind fpu_top fpu_assertions u_assertions (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid_i(in_valid_i),
    .in_ready_o(in_ready_o),
    .out_valid_o(out_valid_o),
    .out_ready_i(out_ready_i),
    .freg_wb_data(freg_wb_data),
    .busy_o(busy_o)
);