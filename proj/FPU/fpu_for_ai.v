`timescale 1ns/10ps

// Operation group definitions
typedef enum logic [1:0] {
    OPGRP_MEMORY = 2'd0,  // FLW, FSW
    OPGRP_ARITH  = 2'd1,  // FADD, FMUL, FDIV
    OPGRP_COUNT  = 2'd2
} opgroup_e;

typedef enum logic [2:0] {
    OP_FLW  = 3'd0,
    OP_FSW  = 3'd1,
    OP_FADD = 3'd2,
    OP_FMUL = 3'd3,
    OP_FDIV = 3'd4
} operation_e;

// Output data structure
typedef struct packed {
    logic [31:0] freg_data;
    logic [4:0]  freg_addr;
    logic        freg_wb_enable;
    logic [31:0] reg_data;
    logic [4:0]  reg_addr;
    logic        reg_wb_enable;
} output_t;

module fpu_top (
    input  logic        clk,
    input  logic        rst_n,
    
    // Input interface
    input  operation_e  op_i,
    input  logic [31:0] reg_rs1,
    input  logic [31:0] reg_rs2,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] freg_rs1,
    input  logic [31:0] freg_rs2,
    input  logic [4:0]  frd_addr,
    input  logic [31:0] imm,
    
    // Input handshake
    input  logic        in_valid_i,
    output logic        in_ready_o,
    
    // Memory interface
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    input  logic [31:0] mem_rdata,
    output logic        mem_we,
    output logic        mem_re,
    input  logic        mem_ready,
    
    // Output interface
    output logic        freg_wb_enable,
    output logic [4:0]  freg_wb_addr,
    output logic [31:0] freg_wb_data,
    output logic        reg_wb_enable,
    output logic [4:0]  reg_wb_addr,
    output logic [31:0] reg_wb_data,
    
    // Output handshake
    output logic        out_valid_o,
    input  logic        out_ready_i,
    
    // Status
    output logic        busy_o
);

    localparam int unsigned NUM_OPGROUPS = 2;
    
    // Internal signals
    logic [NUM_OPGROUPS-1:0] opgrp_in_ready, opgrp_out_valid, opgrp_out_ready, opgrp_busy;
    output_t [NUM_OPGROUPS-1:0] opgrp_outputs;
    
    // Input routing logic
    function automatic opgroup_e get_opgroup(operation_e op);
        case (op)
            OP_FLW, OP_FSW: return OPGRP_MEMORY;
            OP_FADD, OP_FMUL, OP_FDIV: return OPGRP_ARITH;
            default: return OPGRP_MEMORY;
        endcase
    endfunction
    
    // Input ready generation
    assign in_ready_o = in_valid_i & opgrp_in_ready[get_opgroup(op_i)];
    
    // Generate operation blocks
    genvar opgrp;
    generate
        for (opgrp = 0; opgrp < NUM_OPGROUPS; opgrp++) begin : gen_operation_groups
            logic in_valid;
            assign in_valid = in_valid_i & (get_opgroup(op_i) == opgroup_e'(opgrp));
            
            if (opgrp == OPGRP_MEMORY) begin : memory_block
                fpu_memory_block i_memory_block (
                    .clk(clk),
                    .rst_n(rst_n),
                    
                    // Input
                    .op_i(op_i),
                    .reg_rs1(reg_rs1),
                    .reg_rs2(reg_rs2),
                    .rd_addr(rd_addr),
                    .freg_rs1(freg_rs1),
                    .freg_rs2(freg_rs2),
                    .frd_addr(frd_addr),
                    .imm(imm),
                    
                    // Input handshake
                    .in_valid_i(in_valid),
                    .in_ready_o(opgrp_in_ready[opgrp]),
                    
                    // Memory interface
                    .mem_addr(mem_addr),
                    .mem_wdata(mem_wdata),
                    .mem_rdata(mem_rdata),
                    .mem_we(mem_we),
                    .mem_re(mem_re),
                    .mem_ready(mem_ready),
                    
                    // Output
                    .output_o(opgrp_outputs[opgrp]),
                    
                    // Output handshake
                    .out_valid_o(opgrp_out_valid[opgrp]),
                    .out_ready_i(opgrp_out_ready[opgrp]),
                    
                    .busy_o(opgrp_busy[opgrp])
                );
            end else if (opgrp == OPGRP_ARITH) begin : arith_block
                fpu_arith_block i_arith_block (
                    .clk(clk),
                    .rst_n(rst_n),
                    
                    // Input
                    .op_i(op_i),
                    .freg_rs1(freg_rs1),
                    .freg_rs2(freg_rs2),
                    .frd_addr(frd_addr),
                    
                    // Input handshake
                    .in_valid_i(in_valid),
                    .in_ready_o(opgrp_in_ready[opgrp]),
                    
                    // Output
                    .output_o(opgrp_outputs[opgrp]),
                    
                    // Output handshake
                    .out_valid_o(opgrp_out_valid[opgrp]),
                    .out_ready_i(opgrp_out_ready[opgrp]),
                    
                    .busy_o(opgrp_busy[opgrp])
                );
            end
        end
    endgenerate
    
    // Output arbiter
    output_t arbiter_output;
    
    fpu_output_arbiter #(
        .NUM_INPUTS(NUM_OPGROUPS)
    ) i_arbiter (
        .clk(clk),
        .rst_n(rst_n),
        
        .req_i(opgrp_out_valid),
        .gnt_o(opgrp_out_ready),
        .data_i(opgrp_outputs),
        
        .gnt_i(out_ready_i),
        .req_o(out_valid_o),
        .data_o(arbiter_output)
    );
    
    // Output assignment
    assign freg_wb_enable = arbiter_output.freg_wb_enable;
    assign freg_wb_addr   = arbiter_output.freg_addr;
    assign freg_wb_data   = arbiter_output.freg_data;
    assign reg_wb_enable  = arbiter_output.reg_wb_enable;
    assign reg_wb_addr    = arbiter_output.reg_addr;
    assign reg_wb_data    = arbiter_output.reg_data;
    
    assign busy_o = |opgrp_busy;

endmodule

// Memory operation block
module fpu_memory_block (
    input  logic        clk,
    input  logic        rst_n,
    
    // Input
    input  operation_e  op_i,
    input  logic [31:0] reg_rs1,
    input  logic [31:0] reg_rs2,
    input  logic [4:0]  rd_addr,
    input  logic [31:0] freg_rs1,
    input  logic [31:0] freg_rs2,
    input  logic [4:0]  frd_addr,
    input  logic [31:0] imm,
    
    // Input handshake
    input  logic        in_valid_i,
    output logic        in_ready_o,
    
    // Memory interface
    output logic [31:0] mem_addr,
    output logic [31:0] mem_wdata,
    input  logic [31:0] mem_rdata,
    output logic        mem_we,
    output logic        mem_re,
    input  logic        mem_ready,
    
    // Output
    output output_t     output_o,
    
    // Output handshake
    output logic        out_valid_o,
    input  logic        out_ready_i,
    
    output logic        busy_o
);

    typedef enum logic [3:0] {
        IDLE             = 4'd0,
        FLW_MEM_ACCESS   = 4'd1,
        FLW_WAIT_READY   = 4'd2,
        FLW_WAIT_DATA    = 4'd3,
        FLW_STABILIZE    = 4'd4,
        FLW_SAMPLE       = 4'd5,
        FSW_MEM_ACCESS   = 4'd6,
        FSW_WAIT_READY   = 4'd7,
        OUTPUT_VALID     = 4'd8
    } state_e;
    
    state_e state, next_state;
    
    // Temporary registers
    logic [4:0]  target_frd;
    logic [31:0] temp_mem_addr;
    logic [31:0] temp_mem_wdata;
    logic        is_flw_op, is_fsw_op;
    
    assign is_flw_op = (op_i == OP_FLW);
    assign is_fsw_op = (op_i == OP_FSW);
    
    // Input ready logic
    assign in_ready_o = (state == IDLE);
    
    // Busy signal
    assign busy_o = (state != IDLE);
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (in_valid_i) begin
                    if (is_flw_op) begin
                        next_state = FLW_MEM_ACCESS;
                    end else if (is_fsw_op) begin
                        next_state = FSW_MEM_ACCESS;
                    end
                end
            end
            
            // FLW states
            FLW_MEM_ACCESS:   next_state = FLW_WAIT_READY;
            FLW_WAIT_READY: begin
                if (mem_ready) begin
                    next_state = FLW_WAIT_DATA;
                end
            end
            FLW_WAIT_DATA:    next_state = FLW_STABILIZE;
            FLW_STABILIZE:    next_state = FLW_SAMPLE;
            FLW_SAMPLE:       next_state = OUTPUT_VALID;
            
            // FSW states
            FSW_MEM_ACCESS:   next_state = FSW_WAIT_READY;
            FSW_WAIT_READY: begin
                if (mem_ready) begin
                    next_state = OUTPUT_VALID;
                end
            end
            
            OUTPUT_VALID: begin
                if (out_ready_i) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Control logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_addr           <= 32'd0;
            mem_wdata          <= 32'd0;
            mem_we             <= 1'b0;
            mem_re             <= 1'b0;
            target_frd         <= 5'd0;
            temp_mem_addr      <= 32'd0;
            temp_mem_wdata     <= 32'd0;
            output_o           <= '0;
            out_valid_o        <= 1'b0;
        end else begin
            mem_we      <= 1'b0;
            mem_re      <= 1'b0;
            out_valid_o <= 1'b0;
            output_o    <= '0;
            
            case (next_state)
                FLW_MEM_ACCESS: begin
                    temp_mem_addr <= reg_rs1 + imm;
                    target_frd    <= frd_addr;
                end
                FSW_MEM_ACCESS: begin
                    temp_mem_addr  <= reg_rs1 + imm;
                    temp_mem_wdata <= freg_rs2;
                end
            endcase
            
            case (state)
                FLW_MEM_ACCESS: begin
                    mem_re   <= 1'b1;
                    mem_addr <= temp_mem_addr;
                end
                FLW_SAMPLE: begin
                    output_o.freg_addr      <= target_frd;
                    output_o.freg_data      <= mem_rdata;
                    output_o.freg_wb_enable <= 1'b1;
                end
                FSW_MEM_ACCESS: begin
                    mem_we    <= 1'b1;
                    mem_addr  <= temp_mem_addr;
                    mem_wdata <= temp_mem_wdata;
                end
                OUTPUT_VALID: begin
                    out_valid_o <= 1'b1;
                end
            endcase
        end
    end

endmodule

// Arithmetic operation block  
module fpu_arith_block (
    input  logic        clk,
    input  logic        rst_n,
    
    // Input
    input  operation_e  op_i,
    input  logic [31:0] freg_rs1,
    input  logic [31:0] freg_rs2,
    input  logic [4:0]  frd_addr,
    
    // Input handshake
    input  logic        in_valid_i,
    output logic        in_ready_o,
    
    // Output
    output output_t     output_o,
    
    // Output handshake
    output logic        out_valid_o,
    input  logic        out_ready_i,
    
    output logic        busy_o
);

    typedef enum logic [2:0] {
        IDLE         = 3'd0,
        FADD_START   = 3'd1,
        FADD_WAIT    = 3'd2,
        OUTPUT_VALID = 3'd3
    } state_e;
    
    state_e state, next_state;
    
    // Temporary registers
    logic [4:0]  target_frd;
    logic [31:0] temp_freg_rs1, temp_freg_rs2;
    logic        is_fadd_op;
    
    assign is_fadd_op = (op_i == OP_FADD);
    
    // FADD unit instantiation
    logic         fadd_start;
    wire          fadd_enable_out;
    wire [31:0]   fadd_result;
    wire          fadd_ovf;

    fadd_s uut_fadd(
        .x1         (temp_freg_rs1),
        .x2         (temp_freg_rs2),
        .clk        (clk),
        .rst_n      (rst_n),
        .enable_in  (fadd_start),
        .enable_out (fadd_enable_out),
        .y          (fadd_result),
        .ovf        (fadd_ovf)
    );
    
    // Input ready logic
    assign in_ready_o = (state == IDLE);
    
    // Busy signal
    assign busy_o = (state != IDLE);
    
    // Next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (in_valid_i && is_fadd_op) begin
                    next_state = FADD_START;
                end
            end
            
            FADD_START:  next_state = FADD_WAIT;
            FADD_WAIT: begin
                if (fadd_enable_out) begin
                    next_state = OUTPUT_VALID;
                end
            end
            
            OUTPUT_VALID: begin
                if (out_ready_i) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // State register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Control logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            target_frd      <= 5'd0;
            temp_freg_rs1   <= 32'd0;
            temp_freg_rs2   <= 32'd0;
            fadd_start      <= 1'b0;
            output_o        <= '0;
            out_valid_o     <= 1'b0;
        end else begin
            fadd_start  <= 1'b0;
            out_valid_o <= 1'b0;
            output_o    <= '0;
            
            case (next_state)
                FADD_START: begin
                    temp_freg_rs1 <= freg_rs1;
                    temp_freg_rs2 <= freg_rs2;
                    target_frd    <= frd_addr;
                end
            endcase
            
            case (state)
                FADD_START: begin
                    fadd_start <= 1'b1;
                end
                FADD_WAIT: begin
                    if (fadd_enable_out) begin
                        output_o.freg_addr      <= target_frd;
                        output_o.freg_data      <= fadd_result;
                        output_o.freg_wb_enable <= 1'b1;
                    end
                end
                OUTPUT_VALID: begin
                    out_valid_o <= 1'b1;
                end
            endcase
        end
    end

endmodule

// Output arbiter
module fpu_output_arbiter #(
    parameter int unsigned NUM_INPUTS = 2
) (
    input  logic        clk,
    input  logic        rst_n,
    
    input  logic [NUM_INPUTS-1:0] req_i,
    output logic [NUM_INPUTS-1:0] gnt_o,
    input  output_t [NUM_INPUTS-1:0] data_i,
    
    input  logic        gnt_i,
    output logic        req_o,
    output output_t     data_o
);

    logic [NUM_INPUTS-1:0] grant;
    logic [$clog2(NUM_INPUTS)-1:0] grant_idx;
    
    // Priority encoder for round-robin arbitration
    logic [NUM_INPUTS-1:0] mask, masked_req;
    logic [$clog2(NUM_INPUTS)-1:0] rr_pointer;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_pointer <= '0;
        end else if (req_o && gnt_i) begin
            rr_pointer <= (grant_idx + 1) % NUM_INPUTS;
        end
    end
    
    // Generate mask for round-robin
    always_comb begin
        mask = '0;
        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (i >= rr_pointer) mask[i] = 1'b1;
        end
    end
    
    assign masked_req = req_i & mask;
    
    // Priority encoder
    always_comb begin
        grant = '0;
        grant_idx = '0;
        
        // First try masked requests
        if (|masked_req) begin
            for (int i = 0; i < NUM_INPUTS; i++) begin
                if (masked_req[i]) begin
                    grant[i] = 1'b1;
                    grant_idx = i;
                    break;
                end
            end
        end else if (|req_i) begin
            // If no masked requests, try all requests
            for (int i = 0; i < NUM_INPUTS; i++) begin
                if (req_i[i]) begin
                    grant[i] = 1'b1;
                    grant_idx = i;
                    break;
                end
            end
        end
    end
    
    assign gnt_o = grant & {NUM_INPUTS{gnt_i}};
    assign req_o = |req_i;
    assign data_o = data_i[grant_idx];

endmodule