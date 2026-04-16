`ifndef clkcnt
    `define clkcnt 15'd27000
`endif
`ifndef debounce_width
    `define debounce_width 8
`endif

module debouncer #(
    parameter WIDTH = 8
)
(
    input clk,          // clk input
    input rst_n,        // reset input
    input btn,          // button input
    output btn_pulse   // debounced button output
);

reg [14:0] timer_count;
reg [WIDTH-1:0] btn_history;
reg sample_tick;

wire is_stable;
reg is_stable_delay;

assign is_stable = (btn_history == {WIDTH{1'b1}});
assign btn_pulse = ~is_stable_delay & is_stable;

always @(posedge clk) begin
    if (!rst_n) begin
        timer_count <= 0;
        btn_history <= {WIDTH{1'b1}};
        is_stable_delay <= 1;
    end else begin
        if (timer_count < `clkcnt) begin
            timer_count <= timer_count + 1;
            sample_tick <= 0;
        end else begin
            timer_count <= 0;
            sample_tick <= 1;
        end
        
        if (sample_tick) begin
            btn_history <= {btn_history[WIDTH-2:0], btn};
        end

        is_stable_delay <= is_stable;
    end
end

endmodule

module divider
(
    input clk,          // clk input
    input rst_n,        // reset input
    output tick_out
);

    reg [14:0] counter;
    assign tick_out = (counter == 15'd0) ? 1'b1 : 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 15'd0;
        else if (counter < `clkcnt) // 1ms delay
            counter <= counter + 1'b1;
        else
            counter <= 15'd0;
    end

endmodule

// https://en.wikipedia.org/wiki/Linear-feedback_shift_register
module lfsr16 (
    input clk,
    input rst_n,
    output reg [15:0] random_out
);

    wire feedback = random_out[15] ^ random_out[13] ^ random_out[12] ^ random_out[10];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            random_out <= 16'hACE1;
        else
            random_out <= {random_out[14:0], feedback}; 
    end

endmodule

module fsm
(
    input clk,          // clk input
    input rst_n,        // reset input
    input btn_pulse,                // button input (debounced)
    input tick_1ms,             // 1ms tick from divider
    input [15:0] random_num_source,     // random number from LFSR
    output reg [5:0] leds
);

localparam IDLE = 2'd0,
           WAIT = 2'd1,
           TEST = 2'd2,
           SCORE = 2'd3;

reg [1:0] state;
reg [15:0] delay_counter;
reg [15:0] random_num;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        delay_counter <= 16'd0;
    end else begin
        
        case (state)
            IDLE: begin
                if (btn_pulse == 1'b1) begin
                    state <= WAIT;
                    random_num <= random_num_source & 16'h1FFF;
                end
            end
            
            WAIT: begin
                if (tick_1ms) begin
                    if (delay_counter < random_num) begin
                        delay_counter <= delay_counter + 1'b1;
                    end else if (delay_counter == random_num) begin
                        state <= TEST;
                        delay_counter <= 16'd0;
                    end
                end
            end
            TEST: begin
                if (btn_pulse == 1'b1) begin
                    state <= SCORE;
                end else if (tick_1ms) begin
                    delay_counter <= delay_counter + 1'b1;
                end
            end
            SCORE: begin
               if (btn_pulse == 1'b1) begin
                    state <= IDLE;
                    delay_counter <= 16'd0;
                end
            end
            default: state <= IDLE;
        endcase
    end
end

always @(*) begin
    case (state)
        IDLE: leds = 6'b111111; // All LEDs off (active low)
        WAIT: leds = 6'b011110; // LEDs 1-4 on, 0 and 5 off (active low)
        TEST: leds = 6'b000000; // All LEDs on (active low)
        SCORE: leds = ~delay_counter[10:5]; // Score divided by 32
        default: leds = 6'b111111; // Default to all LEDs off
    endcase
end

endmodule

module led
(
    input sys_clk,          // clk input
    input sys_rst_n,        // reset input
    input sys_btn,        // button input
    output [5:0] leds    // 6 LEDS pin
);

wire debounced_btn;
wire tick_1ms;
reg [15:0] random_num;

debouncer #(
    .WIDTH(`debounce_width)
) btn_debouncer (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .btn(sys_btn),
    .btn_pulse(debounced_btn)
);

divider tick_generator (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .tick_out(tick_1ms)
);

lfsr16 lfsr16 (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .random_out(random_num)
);

fsm game_fsm (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .btn_pulse(debounced_btn),
    .tick_1ms(tick_1ms),
    .random_num_source(random_num),
    .leds(leds)
);

endmodule
