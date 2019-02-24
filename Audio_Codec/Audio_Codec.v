
module Audio_Codec (
	// Inputs
	clk,
	rst,
	rd_En,
	wr_En,	
	AUD_ADCDAT,
	
	left_data_i, //speaker
	right_data_i,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	I2C_SDAT,

	// Outputs
	left_data_o, //mic
	right_data_o,
	
	aud_in_av,
		
	AUD_XCK,
	AUD_DACDAT,

	I2C_SCLK	
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				clk;
input				rst;
input				rd_En;
input				wr_En;
input 	wire [31:0]	left_data_i;
input	wire [31:0]	right_data_i;
input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				I2C_SDAT;

// Outputs
output		wire [31:0]		left_data_o;
output		wire [31:0]		right_data_o;

output				AUD_XCK;
output				aud_in_av;
output				AUD_DACDAT;

output				I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
//~ wire				audio_in_available;
//~ wire		[31:0]	left_channel_audio_in;
//~ wire		[31:0]	right_channel_audio_in;
//~ wire				read_audio_in;

wire				audio_out_allowed;
//~ wire		[31:0]	left_channel_audio_out;
//~ wire		[31:0]	right_channel_audio_out;
//~ wire				write_audio_out;



//assign read_audio_in			= audio_in_available & audio_out_allowed;

//~ assign left_channel_audio_out	= left_channel_audio_in; //+sound;
//~ assign right_channel_audio_out	= right_channel_audio_in; //+sound;
//~ assign write_audio_out			= audio_in_available & audio_out_allowed;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50					(clk),
	.reset						(~rst),

	.clear_audio_in_memory		(),
	.read_audio_in				(rd_En),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_data_i),
	.right_channel_audio_out	(right_data_i),
	.write_audio_out			(wr_En),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),


	// Outputs
	.audio_in_available			(aud_in_av),
	.left_channel_audio_in		(left_data_o),
	.right_channel_audio_in		(right_data_o),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT),

);

avconf #(.USE_MIC_INPUT(1)) avc (
	.I2C_SCLK					(I2C_SCLK),
	.I2C_SDAT					(I2C_SDAT),
	.CLOCK_50					(clk),
	.reset						(~rst)
);

endmodule

