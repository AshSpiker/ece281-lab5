----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
    component full_adder is
    port (
        A    : in std_logic;
        B    : in std_logic;
        Cin  : in std_logic;
        S    : out std_logic;
        Cout : out std_logic
    );
    end component full_adder;
    -- Declare signals here
    signal w_carry : std_logic_vector(7 downto 0);
    signal w_adder_res : std_logic_vector(7 downto 0);
    signal w_i_B : std_logic_vector(7 downto 0);



begin
    full_adder_0: full_adder
    port map(
        A    => i_A(0),
        B    => w_i_B(0),
        Cin  => i_op(0), -- this is the first bit of the op code, which will be 0 when adding and 1 when subtracting
        S    => w_adder_res(0),
        Cout => w_carry(0)
    );
    
    full_adder_1: full_adder
    port map(
        A    => i_A(1),
        B    => w_i_B(1),
        Cin  => w_carry(0), 
        S    => w_adder_res(1),
        Cout => w_carry(1)
    );
    
    full_adder_2: full_adder
    port map(
        A    => i_A(2),
        B    => w_i_B(2),
        Cin  => w_carry(1), 
        S    => w_adder_res(2),
        Cout => w_carry(2)
    );
    
    full_adder_3: full_adder
    port map(
        A    => i_A(3),
        B    => w_i_B(3),
        Cin  => w_carry(2), 
        S    => w_adder_res(3),
        Cout => w_carry(3)
    );
    
    full_adder_4: full_adder
    port map(
        A    => i_A(4),
        B    => w_i_B(4),
        Cin  => w_carry(3), 
        S    => w_adder_res(4),
        Cout => w_carry(4)
    );
    
    full_adder_5: full_adder
    port map(
        A    => i_A(5),
        B    => w_i_B(5),
        Cin  => w_carry(4), 
        S    => w_adder_res(5),
        Cout => w_carry(5)
    );
    
    full_adder_6: full_adder
    port map(
        A    => i_A(6),
        B    => w_i_B(6),
        Cin  => w_carry(5), 
        S    => w_adder_res(6),
        Cout => w_carry(6)
    );
    
    full_adder_7: full_adder
    port map(
        A    => i_A(7),
        B    => w_i_B(7),
        Cin  => w_carry(6), 
        S    => w_adder_res(7),
        Cout => w_carry(7) -- this should correspond to the carry flag
    );
    
    

    -- B mux
    w_i_B <= not(i_B) when i_op = "001" else
             i_B;

    --outputs
    -- create a mux for the output with the op code as a selector
    o_result <= w_adder_res when i_op = "000" else
                w_adder_res when i_op = "001" else
                ((i_A) and (i_B)) when i_op = "010" else
                ((i_A) or (i_B)) when i_op = "011";
                
    
    
    
    
    o_flags(0) <=  (not((i_op(0) xor (i_A(7)) xor (i_B(7)))) and -- overflow flag
                   (i_A(7) xor w_adder_res(7))         and
                   (not(i_op(1))));
    
    o_flags(1) <= (not(i_op(1)) and (w_carry(7))); -- carry flag
    
    o_flags(3) <= w_adder_res(7); -- negative flag
    
    o_flags(2) <= '1' when (w_adder_res = "00000000") else -- zero flag
                  '0';
    
    
    --o_flags(0) <= '1' when (w_adder_res(7) = '1') else
                  --'0';-- check to see if it is negative
                  -- WHAT I think this does is
                  -- when the MSB of A and B are both 1 and it equals 1, it did not change sign
   -- o_flags(1) <= '0' when (i_A and not(i_B)) = "00000000" else
               --   '1'; -- check to see if it is zero
    -- the reason o_flags 1 does no work is because I am assigning 8 bits into 1 bit
    --o_flags(2) was already set by full adder 7
  --  o_flags(3) <= '0' when ((i_A(7) and i_B(7)) = '1') else-- check to see if it is oVerflow
                --  '0' when ((not(i_A(7)) and not(i_B(7))) = '1') else
                --  '1';
    
                

end Behavioral;
