
//=======================================================
//  This code is generated by Terasic System Builder
//=======================================================

module Amazer(

	          //////////// CLOCK //////////
	          input        CLOCK_125_p,
	          input        CLOCK_50_B5B,
	          input        CLOCK_50_B6A,
	          input        CLOCK_50_B7A,
	          input        CLOCK_50_B8A,

	          //////////// LED //////////
	          output [7:0] LEDG,
	          output [9:0] LEDR,

	          //////////// KEY //////////
	          input        CPU_RESET_n,
	          input [3:0]  KEY,

	          //////////// SW //////////
	          input [9:0]  SW,

	          //////////// SEG7 //////////
	          output [6:0] HEX0,
	          output [6:0] HEX1,
	          output [6:0] HEX2,
	          output [6:0] HEX3
              );

   parameter STATE_CREATE_MAZE = 8'h0;
   parameter STATE_LOOPING = 8'h1;
   parameter STATE_START_GAME = 8'h2;
   parameter STATE_YAY = 8'h3;
   parameter STATE_GETTING_ME = 8'h4;
   parameter STATE_GETTING_N = 8'h5;
   parameter STATE_GETTING_S = 8'h6;
   parameter STATE_GETTING_E = 8'h7;
   parameter STATE_GETTING_W = 8'h8;
   parameter STATE_WAITING = 8'he;
   parameter STATE_SETTING_ME = 8'h9;
   parameter STATE_SETTING_N = 8'ha;
   parameter STATE_SETTING_S = 8'hb;
   parameter STATE_SETTING_E = 8'hc;
   parameter STATE_SETTING_W = 8'hd;
   parameter STATE_UPDATE_STACK_0 = 8'hf;
   parameter STATE_UPDATE_STACK_1 = 8'h10;
   parameter STATE_UPDATE_STACK_2 = 8'h11;
   parameter STATE_UPDATE_STACK_3 = 8'h12;
   parameter STATE_GET_CELL0 = 8'h13;
   parameter STATE_GET_CELL1 = 8'h14;
   parameter STATE_GET_CELL2 = 8'h15;
   parameter STATE_GET_CELL3 = 8'h16;
   parameter STATE_WAITING_AGAIN = 8'h17;

   // Matrix indexing
   //reg [8 * 32 - 1:0]                      cells[31:0];
   reg [7:0]               state;
   reg [7:0]               state_c;
   // The player's position
   reg [7:0]               player_pos_i;
   reg [7:0]               player_pos_j;
   reg [7:0]               player_pos_i_c;
   reg [7:0]               player_pos_j_c;
   
   // The current position we're operating on when creating the maze
   // Updated during stack manipulation
   reg [7:0]               current_pos_i;
   reg [7:0]               current_pos_j;
   reg [7:0]               current_pos_i_c;
   reg [7:0]               current_pos_j_c;
   //reg [7:0]                               stack_i[32 * 32 - 1:0];
   //reg [7:0]                               stack_j[32 * 32 - 1:0];
   // The pointer to the stack
   // Updated during stack manipulation
   reg [9:0]               stack_ptr;
   reg [9:0]               stack_ptr_c;
   // The next position to operate on
   // Updated during main logic
   reg [7:0]               next_pos_i;
   reg [7:0]               next_pos_j;
   reg [7:0]               next_pos_i_c;
   reg [7:0]               next_pos_j_c;

   // used for initialization
   reg [7:0]               i;
   // Used for randomly choosing a neighbor
   reg [31:0]              rand_seed;
   reg [31:0]              rand_num;
   // used to determine if there are any unvisited neighbors at the current cell
   reg [7:0]               any_neighbors;
   reg [7:0]               num_neighbors;

   // Counters how many clock cycles have passed
   reg [31:0]              counter;
   reg [31:0]              counter_c;
   // Display logic for each cell
   reg [15:0]              ss_debug;
   reg [6:0]               cell0;
   reg [6:0]               cell1;
   reg [6:0]               cell2;
   reg [6:0]               cell3;
   wire [6:0]               d0;
   wire [6:0]               d1;
   wire [6:0]               d2;
   wire [6:0]               d3;
   
   reg [5:0]               maze_height;
   reg [5:0]               maze_width;

   reg [9:0]               leds;
   reg [9:0]               leds_c;
   // Passing values between each clock
   reg                     should_reset;
   reg                     move_east;
   reg                     move_west;
   reg                     move_south;
   reg                     move_north;
   reg                     should_reset_clk;
   reg                     move_east_clk;
   reg                     move_west_clk;
   reg                     move_south_clk;
   reg                     move_north_clk;
   reg                     should_reset_clk_c;
   reg                     move_east_clk_c;
   reg                     move_west_clk_c;
   reg                     move_south_clk_c;
   reg                     move_north_clk_c;
   // For fetching each cell from memory
   reg [7:0]               cell_me_reg;
   reg [7:0]               cell_me_c;
   reg [7:0]               cell_north_reg;
   reg [7:0]               cell_east_reg;
   reg [7:0]               cell_south_reg;
   reg [7:0]               cell_west_reg;
   reg [7:0]               cell_north_c;
   reg [7:0]               cell_east_c;
   reg [7:0]               cell_south_c;
   reg [7:0]               cell_west_c;

   // Memory addresses
   wire [7:0]              mem_data;
   wire                    mem_wren;
   wire [11:0]             mem_addr;
   wire [7:0]              mem_out;
   reg [7:0]               mem_data_reg;
   reg                     mem_wren_reg;
   reg [11:0]              mem_addr_reg;

   // Stack update logic
   // Updated during main logic
   reg                     do_push;
   reg                     do_push_c;

   ram mem(.address(mem_addr),
           .clock(CLK),
           .data(mem_data),
           .wren(mem_wren),
           .q(mem_out));

   initial begin
	  rand_seed = 2;
	  maze_height = 10;
	  maze_width = 10;
	  //state = STATE_CREATE_MAZE;
	  // Added to debug, shouldn't need this later
	  state = STATE_LOOPING;
	  player_pos_i = 0;
	  player_pos_j = 0;
	  current_pos_i = 0;
	  current_pos_j = 0;
	  leds = 0;
	  counter = 0;
	  stack_ptr = 1;
   end
   
   always @(*) begin
	  // Latching
	  state_c = state;
	  player_pos_i_c = player_pos_i;
	  player_pos_j_c = player_pos_j;
	  current_pos_i_c = current_pos_i;
	  current_pos_j_c = current_pos_j;
	  stack_ptr_c = stack_ptr;
	  next_pos_i_c = next_pos_i;
	  next_pos_j_c = next_pos_j;
	  counter_c = counter;
	  leds_c = leds;
	  should_reset_clk_c = should_reset_clk;
	  move_east_clk_c = move_east_clk;
	  move_west_clk_c = move_west_clk;
	  move_north_clk_c = move_north_clk;
	  move_south_clk_c = move_south_clk;
	  cell_me_c = cell_me_reg;
	  cell_north_c = cell_north_reg;
	  cell_south_c = cell_south_reg;
	  cell_east_c = cell_east_reg;
	  cell_west_c = cell_west_reg;
      if (state == STATE_GETTING_ME) begin
         mem_wren_reg = 0;
         mem_data_reg = 0;
         mem_addr_reg = {2'h0, current_pos_i[4:0], current_pos_j[4:0]};
         state_c = STATE_GETTING_N;
      end
      else if (state == STATE_GETTING_N) begin
         mem_wren_reg = 0;
         mem_data_reg = 0;
         mem_addr_reg = {2'h0, current_pos_i[4:0] - 5'h1, current_pos_j[4:0]};
         state_c = STATE_GETTING_S;
      end
      else if (state == STATE_GETTING_S) begin
         mem_wren_reg = 0;
         mem_data_reg = 0;
         mem_addr_reg = {2'h0, current_pos_i[4:0] + 5'h1, current_pos_j[4:0]};
         state_c = STATE_GETTING_E;
         cell_me_c = mem_out;
      end
      else if (state == STATE_GETTING_E) begin
         mem_wren_reg = 0;
         mem_data_reg = 0;
         mem_addr_reg = {2'h0, current_pos_i[4:0], current_pos_j[4:0] - 5'h1};
         state_c = STATE_GETTING_W;
         cell_north_c = mem_out;
      end
      else if (state == STATE_GETTING_W) begin
         mem_wren_reg = 0;
         mem_data_reg = 0;
         mem_addr_reg = {2'h0, current_pos_i[4:0], current_pos_j[4:0] + 5'h1};
         state_c = STATE_WAITING;
         cell_south_c = mem_out;
      end
      else if (state == STATE_WAITING) begin
         mem_wren_reg = 0;
         mem_data_reg = 0;
         state_c = STATE_WAITING_AGAIN;
         cell_east_c = mem_out;
      end
      else if (state == STATE_WAITING_AGAIN) begin
         mem_wren_reg = 0;
         state_c = STATE_SETTING_ME;
         cell_west_c = mem_out;
      end
	  else if (state == STATE_SETTING_ME) begin
		 // Mark the current cell as visited
		 cell_me_c = cell_me_reg | 8'h80;
	  end
      else if (state == STATE_SETTING_N) begin
         mem_wren_reg = 1;
         mem_data_reg = cell_north_reg;
         mem_addr_reg = {2'h0, current_pos_i[4:0] - 5'h1, current_pos_j[4:0]};
         state_c = STATE_SETTING_S;
      end
      else if (state == STATE_SETTING_S) begin
         mem_wren_reg = 1;
         mem_data_reg = cell_south_reg;
         mem_addr_reg = {2'h0, current_pos_i[4:0] + 5'h1, current_pos_j[4:0]};
         state_c = STATE_SETTING_E;
      end
      else if (state == STATE_SETTING_E) begin
         mem_wren_reg = 1;
         mem_data_reg = cell_east_reg;
         mem_addr_reg = {2'h0, current_pos_i[4:0], current_pos_j[4:0] - 5'h1};
         state_c = STATE_SETTING_W;
      end
      else if (state == STATE_SETTING_W) begin
         mem_wren_reg = 1;
         mem_data_reg = cell_west_reg;
         mem_addr_reg = {2'h0, current_pos_i[4:0], current_pos_j[4:0] + 5'h1};
         state_c = STATE_UPDATE_STACK_0;
      end
      else if (state == STATE_UPDATE_STACK_0) begin
         state_c = STATE_UPDATE_STACK_1;
         if (do_push) begin
            mem_wren_reg = 1;
            mem_data_reg = current_pos_i;
            mem_addr_reg = {2'h1, stack_ptr};
         end
         else begin
            mem_wren_reg = 0;
            mem_addr_reg = {2'h1, stack_ptr - 10'h1};
         end
      end // if (state == STATE_UPDATE_STACK_0)
      else if (state == STATE_UPDATE_STACK_1) begin
         state_c = STATE_UPDATE_STACK_2;
         if (do_push) begin
            mem_wren_reg = 1;
            mem_data_reg = current_pos_j;
            mem_addr_reg = {2'h2, stack_ptr};
            current_pos_i_c = next_pos_i;
         end
         else begin
            mem_wren_reg = 0;
            mem_addr_reg = {2'h2, stack_ptr - 10'h1};
         end
      end // if (state == STATE_UPDATE_STACK_1)
      else if (state == STATE_UPDATE_STACK_2) begin
         state_c = STATE_UPDATE_STACK_3;
         if (do_push) begin
            stack_ptr_c = stack_ptr + 1;
            current_pos_j_c = next_pos_j;
         end
         else begin
            current_pos_i_c = mem_out;
            stack_ptr_c = stack_ptr - 1;
         end
      end
      else if (state == STATE_UPDATE_STACK_3) begin
         if (!do_push) begin
            current_pos_j_c = mem_out;
         end
         state_c = STATE_LOOPING;
      end
      else if (state == STATE_GET_CELL0) begin
         state_c = STATE_GET_CELL1;
         mem_wren_reg = 0;
         mem_addr_reg = {2'h0, SW[9:0]};
         cell2 = mem_out;
         if (SW[9:5] == player_pos_i && SW[4:0] == player_pos_j) begin
            cell2 = cell2 & 7'h3f;
         end
      end
      else if (state == STATE_GET_CELL1) begin
         state_c = STATE_GET_CELL2;
         mem_wren_reg = 0;
         mem_addr_reg = {2'h0, SW[9:0] + 10'h1};
         cell3 = mem_out;
         if (SW[9:5] == player_pos_i && SW[4:0] == player_pos_j) begin
            cell3 = cell3 & 7'h3f;
         end
      end
      else if (state == STATE_GET_CELL2) begin
         state_c = STATE_GET_CELL3;
         mem_wren_reg = 0;
         mem_addr_reg = {2'h0, SW[9:0] + 10'h2};
         cell0 = mem_out;
         if (SW[9:5] == player_pos_i && SW[4:0] == player_pos_j) begin
            cell0 = cell0 & 7'h3f;
         end
      end
      else if (state == STATE_GET_CELL3) begin
         state_c = STATE_GET_CELL0;
         mem_wren_reg = 0;
         mem_addr_reg = {2'h0, SW[9:0] + 10'h3};
         cell1 = mem_out;
         if (SW[9:5] == player_pos_i && SW[4:0] == player_pos_j) begin
            cell1 = cell1 & 7'h3f;
         end
      end
      
      // Maze display logic
      /*
       cell0 = cells[SW[9:5]][(SW[4:0] << 5)+:7];
       if (SW[9:5] == player_pos_i && (SW[4:0] << 5) == player_pos_j << 3) begin
       cell0 = cell0 & 7'h3f;
      end
       cell1 = cells[SW[9:5]][(SW[4:0] << 5) + 8+:7];
       if (SW[9:5] == player_pos_i && (SW[4:0] << 5) + 8 == player_pos_j << 3) begin
       cell1 = cell1 & 7'h3f;
      end
       cell2 = cells[SW[9:5]][(SW[4:0] << 5) + 16+:7];
       if (SW[9:5] == player_pos_i && (SW[4:0] << 5) + 16 == player_pos_j << 3) begin
       cell2 = cell2 & 7'h3f;
      end
       cell3 = cells[SW[9:5]][(SW[4:0] << 5) + 24+:7];
       if (SW[9:5] == player_pos_i && (SW[4:0] << 5) + 24 == player_pos_j << 3) begin
       cell3 = cell3 & 7'h3f;
      end
       */
	  if (counter >= 32'd50000000) begin
         counter_c = 0;
      end else begin
         counter_c = counter + 1;
      end
	  if (should_reset != should_reset_clk) begin
		 should_reset_clk_c = should_reset;
	  end
      if (state == STATE_CREATE_MAZE) begin
		 player_pos_i_c = 0;
		 player_pos_j_c = 0;
		 current_pos_i_c = 0;
		 current_pos_j_c = 0;
		 stack_ptr_c = 1;
		 leds_c = 0;
		 // Clearing memory
		 if (counter > 4095) begin
			counter_c = 0;
			state_c = STATE_LOOPING;
		 end
		 else begin
			counter_c = counter + 1;
			mem_addr_reg = counter;
			mem_wren_reg = 1;
			mem_data_reg = 0;
		 end
      end else if (state == STATE_LOOPING) begin
         if (stack_ptr == 0) begin
            player_pos_i_c = 0;
            player_pos_j_c = 0;
            state_c = STATE_GET_CELL0;
		 end
         else begin
            state_c = STATE_GETTING_ME;
         end
      end
      else if (state == STATE_SETTING_ME) begin

         // Maze creation logic
         any_neighbors = 0;
         num_neighbors = 0;
         if (current_pos_i + 1 < maze_height && cell_south_reg & 8'h80 == 0) begin
            any_neighbors = any_neighbors | 1;
            num_neighbors = num_neighbors + 1;
         end else if (current_pos_j + 1 < maze_width && cell_west_reg & 8'h80 == 0) begin
            any_neighbors = any_neighbors | 2;
            num_neighbors = num_neighbors + 1;
         end else if (current_pos_i - 1 >= 0 && cell_north_reg & 8'h80 == 0) begin
            any_neighbors = any_neighbors | 4;
            num_neighbors = num_neighbors + 1;
         end else if (current_pos_j - 1 >= 0 && cell_east_reg & 8'h80 == 0) begin
            any_neighbors = any_neighbors | 8;
            num_neighbors = num_neighbors + 1;
         end

         if (num_neighbors > 0) begin
            // Pick a random neighbor among the neighbors that haven't been visited
            rand_num = $rand(rand_seed) % num_neighbors;
            for (i = 0; i < rand_num; i = i + 1) begin
               // Remove a random number of bits
               any_neighbors = any_neighbors & (any_neighbors - 1);
            end
            // Isolate the rightmost bit
            any_neighbors = any_neighbors & (-1 * any_neighbors);
            // Logic to set next_pos_i and next_pos_j
            if (any_neighbors == 1) begin
               next_pos_i_c = current_pos_i + 1;
               next_pos_j_c = current_pos_j;
            end else if (any_neighbors == 2) begin
               next_pos_i_c = current_pos_i;
               next_pos_j_c = current_pos_j + 1;
            end else if (any_neighbors == 4) begin
               next_pos_i_c = current_pos_i - 1;
               next_pos_j_c = current_pos_j;
            end else begin
               next_pos_i_c = current_pos_i;
               next_pos_j_c = current_pos_j - 1;
            end
         end // if (num_neighbors > 0)
         
		 state_c = STATE_SETTING_N;
         if (any_neighbors != 0) begin
            /*
             stack_i[stack_ptr] <= current_pos_i;
             stack_j[stack_ptr] <= current_pos_j;
             stack_ptr <= stack_ptr + 1;
             */
            do_push_c = 1;
            // Remove walls
            if (next_pos_i_c == current_pos_i - 1) begin
               // Remove northern wall of current cell
               // cells[current_pos_i][8 * current_pos_j+:8] <= cells[current_pos_i][8 * current_pos_j+:8] | 8'h1;
               // cells[next_pos_i][8 * next_pos_j+:8] <= cells[next_pos_i][8 * next_pos_j+:8] | 8'h8;
               cell_me_c = cell_me_reg | 8'h1;
               cell_north_c = cell_north_reg | 8'h8;
            end else if (next_pos_i_c == current_pos_i + 1) begin
               // cells[current_pos_i][8 * current_pos_j+:8] <= cells[current_pos_i][8 * current_pos_j+:8] | 8'h8;
               // cells[next_pos_i][8 * next_pos_j+:8] <= cells[next_pos_i][8 * next_pos_j+:8] | 8'h1;
               cell_me_c = cell_me_reg | 8'h8;
               cell_south_c = cell_south_reg | 8'h1;
            end else if (next_pos_j_c == current_pos_j - 1) begin
               //cells[current_pos_i][8 * current_pos_j+:8] <= cells[current_pos_i][8 * current_pos_j+:8] | 8'h30;
               //cells[next_pos_i][8 * next_pos_j+:8] <= cells[next_pos_i][8 * next_pos_j+:8] | 8'h6;
               cell_me_c = cell_me_reg | 8'h30;
               cell_east_c = cell_east_reg | 8'h6;
            end else begin
               //cells[current_pos_i][8 * current_pos_j+:8] <= cells[current_pos_i][8 * current_pos_j+:8] | 8'h6;
               //cells[next_pos_i][8 * next_pos_j+:8] <= cells[next_pos_i][8 * next_pos_j+:8] | 8'h30;
               cell_me_c = cell_me_reg | 8'h6;
               cell_west_c = cell_west_reg | 8'h30;
            end
         end else begin // if (any_neighbors != 0)
            do_push_c = 0;
         end // else: !if(any_neighbors != 0)
         // Write the current cell to memory
         mem_wren_reg = 1;
         mem_data_reg = cell_me_c;
         mem_addr_reg = {2'h0, current_pos_i[4:0], current_pos_j[4:0]};
      end // if (state == STATE_LOOPING)
      else if (state == STATE_GET_CELL0 ||
               state == STATE_GET_CELL1 ||
               state == STATE_GET_CELL2 ||
               state == STATE_GET_CELL3) begin
         if (player_pos_i == maze_height - 1 && player_pos_j == maze_width - 1) begin
            state_c = STATE_YAY;
         end
		 if (move_north != move_north_clk) begin
			move_north_clk_c = move_north;
			player_pos_i_c = player_pos_i - 1;
		 end else if (move_south != move_south_clk) begin
			move_south_clk_c = move_south;
			player_pos_i_c = player_pos_i + 1;
		 end else if (move_east != move_east_clk) begin
			move_east_clk_c = move_east;
			player_pos_j_c = player_pos_j - 1;
		 end else if (move_west != move_west_clk) begin
			move_west_clk_c = move_west;
			player_pos_j_c = player_pos_j + 1;
		 end
      end
      else if (state == STATE_YAY) begin
         if (counter == 31'd25000000) begin
            leds_c = 10'h3ff;
         end
         if (counter == 31'd0) begin
            leds_c = 10'h0;
         end
      end
	  
	  if (should_reset != should_reset_clk) begin
		 state_c = STATE_CREATE_MAZE;
		 counter_c = 0;
	  end
	  
	  // Kill bugs
      if (SW[9]) begin
         ss_debug = {8'h0, state};
      end
	  else if (SW[8]) begin
         ss_debug = {player_pos_i, player_pos_j};
	  end
      else if (SW[7]) begin
         ss_debug = {current_pos_i, current_pos_j};
      end
      else if (SW[6]) begin
         ss_debug = {3'h0, do_push, 2'h0, stack_ptr};
      end
      else if (SW[5]) begin
         ss_debug = {next_pos_i, next_pos_j};
      end
      else if (SW[4]) begin
         ss_debug = {any_neighbors, num_neighbors};
      end
      else if (SW[3]) begin
         ss_debug = {2'h0, maze_height, 2'h0, maze_width};
      end
      else if (SW[2]) begin
         ss_debug = {8'h0, cell_me_reg};
      end
      else if (SW[1]) begin
         ss_debug = {cell_north_reg, cell_south_reg};
      end
      else if (SW[0]) begin
         ss_debug = {cell_east_reg, cell_west_reg};
      end
      cell0 = {3'h0, ss_debug[3:0]};
      cell1 = {3'h0, ss_debug[7:4]};
      cell2 = {3'h0, ss_debug[11:8]};
      cell3 = {3'h0, ss_debug[15:12]};
   end

   // posedge system clock, not buttons
   always @(posedge CLK) begin
	  state <= state_c;
	  player_pos_i <= player_pos_i_c;
	  player_pos_j <= player_pos_j_c;
	  current_pos_i <= current_pos_i_c;
	  current_pos_j <= current_pos_j_c;
	  stack_ptr <= stack_ptr_c;
	  next_pos_i <= next_pos_i_c;
	  next_pos_j <= next_pos_j_c;
	  counter <= counter_c;
	  leds <= leds_c;
	  should_reset_clk <= should_reset_clk_c;
	  move_east_clk <= move_east_clk_c;
	  move_west_clk <= move_west_clk_c;
	  move_north_clk <= move_north_clk_c;
	  move_south_clk <= move_south_clk_c;
	  cell_me_reg <= cell_me_c;
	  cell_north_reg <= cell_north_c;
	  cell_south_reg <= cell_south_c;
	  cell_east_reg <= cell_east_c;
	  cell_west_reg <= cell_west_c;
   end // always @ (posedge clk)

   assign mem_wren = mem_wren_reg;
   assign mem_data = mem_data_reg;
   assign mem_addr = mem_addr_reg;

   // Move north
   always @(posedge KEY[3]) begin
      if (player_pos_i > 0 && state == STATE_START_GAME) begin
		 move_north <= ~move_north;
      end
   end
   always @(posedge KEY[2]) begin
      if (player_pos_i < maze_height && state == STATE_START_GAME) begin
         move_south <= ~move_south;
      end
   end
   always @(posedge KEY[1]) begin
      if (player_pos_j > 0 && state == STATE_START_GAME) begin
         move_west <= ~move_west;
      end
   end
   always @(posedge KEY[0]) begin
      if (player_pos_j < maze_width && state == STATE_START_GAME) begin
         move_east <= ~move_east;
      end
   end
   always @(posedge CPU_RESET_n) begin
      maze_height <= SW[9:5] + 1;
      maze_width <= SW[4:0] + 1;
      should_reset <= ~should_reset;
   end

   assign HEX3 = d3;
   assign HEX2 = d2;
   assign HEX1 = d1;
   assign HEX0 = d0;

   display dd0(cell0[3:0], d0);
   display dd1(cell1[3:0], d1);
   display dd2(cell2[3:0], d2);
   display dd3(cell3[3:0], d3);
   
   assign LEDR = leds;
   assign LEDG = leds[7:0];
   
   //assign CLK = CLOCK_50_B5B;
   assign CLK = KEY[0];
   
   // Display logic: read switches, show section of maze on 7-seg display, show player position on LEDR,
   // read button presses and move player

endmodule

module display(NUM, HEX);

   input[3:0] NUM;
   output [6:0] HEX;
   reg [6:0]    HEX;

   always @(*)
     case (NUM)
       4'h0 : HEX = 7'b1000000;
       4'h1 : HEX = 7'b1111001;
       4'h2 : HEX = 7'b0100100;
       4'h3 : HEX = 7'b0110000;
       4'h4 : HEX = 7'b0011001;
       4'h5 : HEX = 7'b0010010;
       4'h6 : HEX = 7'b0000010;
       4'h7 : HEX = 7'b1111000;
       4'h8 : HEX = 7'b0000000;
       4'h9 : HEX = 7'b0010000;
       4'hA : HEX = 7'b0001000;
       4'hB : HEX = 7'b0000011;
       4'hC : HEX = 7'b0100111;
       4'hD : HEX = 7'b0100001;
       4'hE : HEX = 7'b0000110;
       4'hF : HEX = 7'b0001110;
     endcase // case (NUM)
endmodule // display
