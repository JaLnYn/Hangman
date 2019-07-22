// Part 2 skeleton

module Hangman
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,
		SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [17:0]  SW;
	//output  [17:0]  LEDR;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
		defparam VGA.BACKGROUND_IMAGE = "hangman.colour.mif"; // Might have too many bits, can change by setting VGA.MONOCHROME = TRUE and using hangman.mono.mif
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	wire done, enable, letter_found, load;

	wire [7:0] key, l1, l2,l3,l4,l5,l6,l7,l8,l9,l0;
	wire [9:0] checkModOut;
	wire [3:0] counter;


	load ld(CLOCK_50, load, counter, key, l1, l2,l3,l4,l5,l6,l7,l8,l9,l0);
	check_module cm(key,l1, l2,l3,l4,l5,l6,l7,l8,l9,l0, letter_found, checkModOut);

	// Instantiate FSM control
	control c0(CLOCK_50, resetn, SW[17], SW[16], done, enable);
	 
endmodule

module control(clock, resetn, done, key, goNextState, wins, x, y, colour);
	input clock, resetn, done, goNextState, wins; //note done has to mean keyboard enter is not pressed
	input [7:0] key;
	input [7:0] x;
	input [6:0] y;
	input [2:0] colour;
	//input reg enable;
	reg [4:0] cur_state, nxt_state;

	
   localparam  DRAW_INIT = 5'd0,
      LOAD_NUM = 5'd1,
		LOAD_NUM_WAIT = 5'd2,
		LOAD_WORD = 5'd3,
      LOAD_WORD_DRAW = 5'd4,
		LOAD_WORD_WAIT = 5'd5,
      SETUP = 5'd6,
      SETUP_WAIT = 5'd7,
      GUESS_LETTER = 5'd8,
      GUESS_LETTER_WAIT = 5'd9,
      CHECK_LETTER = 5'd10,
		CHECK_LETTER_DRAW = 5'd11,
      CHECK_LETTER_WAIT = 5'd11,
      CHECK_WORD_DRAW = 5'd12,
      CHECK_VICTORY = 5'd13,
      VICTORY = 5'd15,
      VICTORY_WAIT = 5'd16,
      DEATH = 5'd17,
      DEATH_WAIT = 5'd18;
		
	always @(*)
	begin: state_table // next state logic
		case (cur_state)
			//DRAW_SPLASH_SCREEN: begin
			//		assign enable = 1'b1;
			//		drawSplashScreen drawS(enable, clock, resetn, x, y, colour);
			//		assign enable = 1'b0;
			//		nxt_state <= DRAW_INIT;
			//	end
			DRAW_INIT: nxt_state = done ? LOAD_WORD : DRAW_INIT;
				LOAD_WORD: begin
				 if(key == 8'h0A)
					nxt_state <= LOAD_WORD_WAIT;
				 else
					nxt_state <= LOAD_WORD;
			  end
				LOAD_WORD_WAIT: begin
				 if(key == 8'h00)
					nxt_state <= LOAD_WORD_DRAW;
				 else
					nxt_state <= LOAD_WORD_WAIT;
			  end
			LOAD_WORD_DRAW: begin
				 if(done && goNextState) // done drawing
					nxt_state <= LOAD_WORD_DRAW;
				 else if(done) 
					nxt_state <= LOAD_WORD;
				 else
					nxt_state <= LOAD_WORD_DRAW;
			  end
			SETUP:  nxt_state = done ? SETUP_WAIT : SETUP;
			SETUP_WAIT: nxt_state = done ? GUESS_LETTER : SETUP_WAIT;
			GUESS_LETTER: begin
				 if(key != 8'h00 ) // done drawing
					nxt_state <= GUESS_LETTER_WAIT;
				 else 
					nxt_state <= GUESS_LETTER;
			  end
			GUESS_LETTER_WAIT: begin
				 if(key == 8'h00)
					nxt_state <= CHECK_LETTER;
				 else
					nxt_state <= GUESS_LETTER;
			  end
			CHECK_LETTER: nxt_state = done ? CHECK_LETTER_DRAW : CHECK_LETTER;
			CHECK_LETTER_DRAW: begin
				 if(done && goNextState) // done drawing
					if(wins)
					  nxt_state <= VICTORY;
					else
					  nxt_state <= DEATH;
					
				 else if(done) 
					nxt_state <= LOAD_WORD;
				 else
					nxt_state <= LOAD_WORD_DRAW;
			  end
			VICTORY: begin
					assign enable = 1'b1;
					drawVictoryScreen drawV(enable, clock, resetn, x, y, colour);
					assign enable = 1'b0;
					nxt_state <= VICTORY_WAIT;
				end
			VICTORY_WAIT: nxt_state = done ? DRAW_INIT : VICTORY;
			DEATH: begin
					assign enable = 1'b1;
					drawDeathScreen drawD(enable, clock, resetn, x, y, colour);
					assign enable = 1'b0;
					nxt_state <= VICTORY_WAIT;
					nxt_state <= DEATH_WAIT;
				end
			DEATH_WAIT: nxt_state = done ? DRAW_INIT : DEATH;
				default: nxt_state = DRAW_INIT;
		endcase
	end
	
	always @(*)
	begin: enable_signals // datapath control signals
		
		//enable <= 1'b0;
		
		
		case (cur_state)
			DRAW_INIT: begin
				
			end
      LOAD_NUM: begin
				
				//enable <= 1'b1;
			end
			LOAD_NUM_WAIT: begin
				//enable <= 1'b1;
			end
			LOAD_WORD: begin
				//enable <= 1'b1;
			end
			LOAD_WORD_WAIT: begin
				//enable <= 1'b1;
			end
      SETUP: begin
				//enable <= 1'b1;
			end
      SETUP_WAIT: begin
				//enable <= 1'b1;
			end
      GUESS_LETTER: begin
				//enable <= 1'b1;
			end
      GUESS_LETTER_WAIT: begin
				//enable <= 1'b1;
			end
      CHECK_LETTER: begin
				//enable <= 1'b1;

			end
      CHECK_LETTER_WAIT: begin
				//enable <= 1'b1;
			end
      CHECK_VICTORY: begin
				//enable <= 1'b1;
			end
      VICTORY : begin
				//enable <= 1'b1;
			end
      VICTORY_WAIT: begin
				//enable <= 1'b1;
			end
      DEATH: begin
				//enable <= 1'b1;
			end
      DEATH_WAIT: begin
				//enable <= 1'b1;
			end
		endcase
	end
	
	always @(posedge clock)
	begin: state_FFs // current state registers
		cur_state = nxt_state;
		if (!resetn)
			cur_state = DRAW_INIT;
		else
			cur_state = nxt_state;
	end
endmodule
