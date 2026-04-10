----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2026 05:04:51 PM
-- Design Name: 
-- Module Name: branch_unit_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

use work.opcode_pkg.all;

entity branch_unit_tb is
end branch_unit_tb;

architecture Behavioral of branch_unit_tb is

    -- DUT signals
    signal branch      : std_logic := '0';
    signal branch_op   : branch_op_t;
    signal a           : std_logic_vector(31 downto 0);
    signal b           : std_logic_vector(31 downto 0);
    signal take_branch : std_logic;

begin

    -- Instantiate DUT
    uut: entity work.branch_unit
        port map (
            branch => branch,
            branch_op => branch_op,
            a => a,
            b => b,
            take_branch => take_branch
        );

    -- Test process
    stim_proc: process

        -- helper procedure for clean testing
        procedure check(
            constant test_name : string;
            constant br        : std_logic;
            constant op        : branch_op_t;
            constant va        : std_logic_vector(31 downto 0);
            constant vb        : std_logic_vector(31 downto 0);
            constant expected  : std_logic
        ) is
        begin
            branch    <= br;
            branch_op <= op;
            a         <= va;
            b         <= vb;

            wait for 10 ns;

            assert take_branch = expected
                report "FAILED: " & test_name
                severity error;

            report "PASSED: " & test_name;
        end procedure;

    begin

        ----------------------------------------------------------------
        -- BRANCH DISABLED TESTS
        ----------------------------------------------------------------
        check("Branch disabled BEQ", '0', OP_BRANCH_BEQ, x"00000005", x"00000005", '0');
        check("Branch disabled BNE", '0', OP_BRANCH_BNE, x"00000005", x"00000006", '0');

        ----------------------------------------------------------------
        -- BEQ TESTS
        ----------------------------------------------------------------
        check("BEQ equal", '1', OP_BRANCH_BEQ, x"00000005", x"00000005", '1');
        check("BEQ not equal", '1', OP_BRANCH_BEQ, x"00000005", x"00000006", '0');
        check("BEQ zero", '1', OP_BRANCH_BEQ, x"00000000", x"00000000", '1');

        ----------------------------------------------------------------
        -- BNE TESTS
        ----------------------------------------------------------------
        check("BNE equal", '1', OP_BRANCH_BNE, x"00000005", x"00000005", '0');
        check("BNE not equal", '1', OP_BRANCH_BNE, x"00000005", x"00000006", '1');

        ----------------------------------------------------------------
        -- BLT (SIGNED)
        ----------------------------------------------------------------
        check("BLT positive true", '1', OP_BRANCH_BLT, x"00000001", x"00000002", '1');
        check("BLT positive false", '1', OP_BRANCH_BLT, x"00000002", x"00000001", '0');

        check("BLT negative < positive", '1', OP_BRANCH_BLT, x"FFFFFFFF", x"00000001", '1'); -- -1 < 1
        check("BLT positive < negative", '1', OP_BRANCH_BLT, x"00000001", x"FFFFFFFF", '0');

        check("BLT equal", '1', OP_BRANCH_BLT, x"00000005", x"00000005", '0');

        ----------------------------------------------------------------
        -- BGE (SIGNED)
        ----------------------------------------------------------------
        check("BGE equal", '1', OP_BRANCH_BGE, x"00000005", x"00000005", '1');
        check("BGE greater", '1', OP_BRANCH_BGE, x"00000006", x"00000005", '1');
        check("BGE less", '1', OP_BRANCH_BGE, x"00000004", x"00000005", '0');

        check("BGE negative >= negative", '1', OP_BRANCH_BGE, x"FFFFFFFF", x"FFFFFFFE", '1'); -- -1 >= -2
        check("BGE negative < positive", '1', OP_BRANCH_BGE, x"FFFFFFFF", x"00000001", '0');

        ----------------------------------------------------------------
        -- BLTU (UNSIGNED)
        ----------------------------------------------------------------
        check("BLTU small < large", '1', OP_BRANCH_BLTU, x"00000001", x"FFFFFFFF", '1');
        check("BLTU large > small", '1', OP_BRANCH_BLTU, x"FFFFFFFF", x"00000001", '0');

        check("BLTU equal", '1', OP_BRANCH_BLTU, x"AAAAAAAA", x"AAAAAAAA", '0');

        ----------------------------------------------------------------
        -- BGEU (UNSIGNED)
        ----------------------------------------------------------------
        check("BGEU equal", '1', OP_BRANCH_BGEU, x"AAAAAAAA", x"AAAAAAAA", '1');
        check("BGEU greater", '1', OP_BRANCH_BGEU, x"FFFFFFFF", x"00000001", '1');
        check("BGEU less", '1', OP_BRANCH_BGEU, x"00000001", x"FFFFFFFF", '0');

        ----------------------------------------------------------------
        -- JAL / JALR (ALWAYS TAKEN)
        ----------------------------------------------------------------
        check("JAL always", '1', OP_BRANCH_JAL_JALR, x"00000000", x"00000000", '1');
        check("JAL always random", '1', OP_BRANCH_JAL_JALR, x"12345678", x"87654321", '1');

        ----------------------------------------------------------------
        -- EXTREME EDGE CASES
        ----------------------------------------------------------------
        check("Min signed vs max signed BLT", '1', OP_BRANCH_BLT,
              x"80000000", x"7FFFFFFF", '1'); -- -2^31 < +2^31-1

        check("Max unsigned vs zero BLTU", '1', OP_BRANCH_BLTU,
              x"FFFFFFFF", x"00000000", '0');

        check("Zero vs max unsigned BLTU", '1', OP_BRANCH_BLTU,
              x"00000000", x"FFFFFFFF", '1');

        ----------------------------------------------------------------
        -- END SIMULATION
        ----------------------------------------------------------------
        report "ALL TESTS COMPLETED" severity note;
        wait;

    end process;

end Behavioral;
