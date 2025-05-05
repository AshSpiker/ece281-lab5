----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

    type sm_state is (state0, state1, state2, state3);

    signal f_Q, f_Q_next : sm_state;
    
    begin

        --f_Q_next <= state1 when ((f_Q = state0) and (i_adv = '1')) else
        --            state2 when ((f_Q = state1) and (i_adv = '1')) else
        --            state3 when ((f_Q = state2) and (i_adv = '1')) else
        --            state0 when ((f_Q = state3) and (i_adv = '1')) else
        --            f_Q;
                    
        f_Q_next <= state1 when (f_Q = state0) else
                    state2 when (f_Q = state1) else
                    state3 when (f_Q = state2) else
                    state0 when (f_Q = state3) else
                    f_Q;
                    
        with f_Q select
            o_cycle <= "1000" when state0,
                       "0100" when state1,
                       "0010" when state2,
                       "0001" when state3;
            
        



    state_register : process(i_adv)
	begin
        if rising_edge(i_adv) then
           if i_reset = '1' then
               f_Q <= state0;
           else
                f_Q <= f_Q_next;
            end if;
        end if;
	end process state_register;


    end FSM;
