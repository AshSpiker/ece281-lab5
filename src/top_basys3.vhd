--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    
    
    -- TO DO !!!! :
    -- blank final display
    -- make registers (not sure if I did this correct)
    -- figure out flags on ALU.vhd (I think they are all messed up but I want to test them)
    -- figure out what MUX between ALU and twos comp is supposed to do
    -- test, make sure works
    -- get 100%, validate the final :)
    
    
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic; -- clock reset (asyncrhonous)
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
  
    -- signal declaration
    signal w_clk : std_logic;
    signal w_cycle : std_logic_vector(3 downto 0);
    signal w_ALU_to_MUX : std_logic_vector(7 downto 0);
    signal w_MUX_to_twos_comp : std_logic_vector(7 downto 0);
    signal w_sign : std_logic;
    signal w_D3 : std_logic_vector(3 downto 0);
    signal w_hund_D2 : std_logic_vector(3 downto 0);
    signal w_tens_D1 : std_logic_vector(3 downto 0);
    signal w_ones_D0 : std_logic_vector(3 downto 0);
    --signal w_TDM_to_MUX : std_logic_vector(3 downto 0);
    --signal w_MUX_to_sevenseg : std_logic_vector (3 downto 0);
    signal w_sw_to_register : std_logic_vector(7 downto 0);
    signal w_register_to_A : std_logic_vector(7 downto 0);
    signal w_register_to_B : std_logic_vector(7 downto 0);
    signal w_sel_to_MUX : std_logic_vector(3 downto 0);
    signal w_MUX_to_an : std_logic_vector(3 downto 0);
    signal w_data : std_logic_vector(3 downto 0);
    signal w_sevenseg_to_MUX : std_logic_vector(6 downto 0);
    signal w_MUX_to_seg : std_logic_vector(6 downto 0);
    signal w_MUX_to_MUX : std_logic_vector(6 downto 0);
    
	-- declare components and signals
	-- DECLARE FSM COMPONENT
    component controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    
    -- DECLARE CLOCK DIVIDER COMPONENT
    component clock_divider is
	generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
											   -- Effectively, you divide the clk double this 
											   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	port ( 	i_clk    : in std_logic;
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	);
    end component clock_divider;
    
    -- DECLARE ALU COMPONENT
    component ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
    end component ALU;
    
    -- DECLARE TWO's COMP COMPONENT
    component twos_comp is
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
    end component twos_comp;
    
    -- DECLARE TDM 
    component TDM4 is
	generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
    end component TDM4;
    
    -- DECLARE 7-SEG COMPONENT 
    component sevenseg_decoder is
    Port ( i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
           o_seg_n : out STD_LOGIC_VECTOR (6 downto 0));
    end component sevenseg_decoder;
  
begin
	-- PORT MAPS ----------------------------------------
    -- inst components
    controller_fsm_inst : controller_fsm
    port map (
    i_reset => btnU,
    i_adv => btnC,
    o_cycle => w_cycle
    );
    
    clock_divider_inst : clock_divider
    generic map(k_DIV => 208333)
    port map(
    i_clk => clk,
    i_reset => btnL,
    o_clk => w_clk
    );
    
    alu_inst : ALU
    port map(
    i_A => w_register_to_A,-- register 1.. need to remember how to do this
    i_B => w_register_to_B,-- register 2
    i_op => sw(2 downto 0),
    o_result => w_ALU_to_MUX,
    o_flags => led(15 downto 12)
    );
    
    twos_comp_inst : twos_comp
    port map(
    i_bin => w_MUX_to_twos_comp,
    o_sign => w_sign,
    o_hund => w_hund_D2,  
    o_tens => w_tens_D1,
    o_ones => w_ones_D0
    );
    
    TDM_inst : TDM4
    port map(
    i_clk => w_clk,
    i_reset => btnU,
    i_D3 => w_D3, -- need to figure this one out with figuring out o_sign
    i_D2 => w_hund_D2,
    i_D1 => w_tens_D1,
    i_D0 => w_ones_D0,
    o_data => w_data,
    o_sel => w_sel_to_MUX
    );
    
    seven_seg_inst : sevenseg_decoder
    port map(
    i_hex => w_data,
    o_seg_n => w_sevenseg_to_MUX
    );
    
	
	
	-- CONCURRENT STATEMENTS ----------------------------
	-- led(15 downto 12) were already given values
	led(3 downto 0) <= w_cycle;
	-- ground unused leds
	led(11 downto 4) <= (others => '0');
	
	
	
	
	-- Creating the negative sign between o_sign and i_D3
	w_D3 <= "1111" when w_sign = '1' else
	        "1110" when w_sign = '0';
	        
	        
	
	   -- Part 2 for making negative sign
    --w_MUX_to_seg <= w_MUX_to_MUX when w_sel_to_MUX = "0111" else
      --              w_sevenseg_to_MUX;
      
      w_MUX_to_MUX <= "0111111" when w_D3 = "1111" else
                      "1111111" when w_D3 = "1110" else
                      w_sevenseg_to_MUX; -- this bottom line never occurs and therefore sets all of the values to blank or negative sign
           
      w_MUX_to_seg <=  w_MUX_to_MUX when w_sel_to_MUX = "0111" else
                       w_sevenseg_to_MUX;
           
           
    --w_MUX_to_MUX <= "0111111" when w_D3 = "1111" else
           --         "1111111" when w_D3 = "1110" else
           --         w_sevenseg_to_MUX; -- this bottom line will never occur (which is why it wasn't working before)
           
           
           
           -- WHAT I think these two parts do is essentially add a 2 MUXs between 
           -- first my o_sign and i_D3 and second between o_data and i_hex
           -- since I am not using E or F since I am only doing binary, what I can do
           -- is set my E and F to my positive (blank) and negative (-) signs
           -- so my first mux sets my value to be F when its negative and E when its positive
           -- then my second mux sets an incoming F as only the g anode being hot (a negative sign)
           -- and sets an incoming E as no anode being hot (simply being blank)
      seg(6 downto 0) <= w_MUX_to_seg;
           
    -- Creating Registers
    w_sw_to_register <= sw(7 downto 0);
    
    memory_register : process(btnC)
    begin
        if(w_cycle = "1000") then
            w_register_to_A <= w_sw_to_register;
        end if;
        if(w_cycle = "0100") then
            w_register_to_B <= w_sw_to_register;
        end if;
    end process memory_register;
    
    
    -- Creating MUX between ALU and twos_comp
    w_MUX_to_twos_comp <=  w_register_to_A when w_cycle = "1000" else
                           w_register_to_B when w_cycle = "0100" else
                           w_ALU_to_MUX when w_cycle = "0010";
                           --something else here?, maybe doesnt matter because I am blanking screen anyway?
                           
    -- Creating a MUX to blank the display between o_sel and an, by using w_cycle as controller
    w_MUX_to_an <= "1111" when w_cycle = "1000" else
                   w_sel_to_MUX;
                   
    an(3 downto 0) <= w_MUX_to_an;
                   
    
	
	
end top_basys3_arch;
