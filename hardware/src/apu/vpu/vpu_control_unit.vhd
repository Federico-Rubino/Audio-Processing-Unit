library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.apu_opcode_pkg.all;
use work.apu_internal_pkg.all;
use work.vpu_internal_pkg.all;

entity vpuCU is
    Port (
        clk, rst : in std_logic;

        en : in std_logic;
        done : out std_logic;

        vec_op : in vec_op_t;

        --to BMUs
        bmu_read_1_start : out std_logic;
        bmu_read_2_start : out std_logic;
        bmu_write_start : out std_logic;

        bmu_read_1_done : in std_logic;
        bmu_read_2_done : in std_logic;
        bmu_write_done : in std_logic;

        count_en : out std_logic;
        exec1_en : in std_logic; -- pipe's first DSP-execute stage (vpu's s2b_en) -- next count_en waits for this, so bmu_read_1/bmu_read_2 never collide on the shared bus

        --to DSPs
        dsp_op_sel : out dsp_op_sel_array_t;

        --to MUXs
        sel_scal_in : out std_logic; -- 0 = vec in, 1 = scalar in
        sel_output_even : out std_logic; -- even DSP; 0 = take DSP output, 1 = shift for fixed point alignement
        sel_output_odd : out std_logic -- odd DSP; 0 = take DSP output, 1 = shift for fixed point alignement
    );
end vpuCU;

architecture Behavioral of vpuCU is

    type vpu_state is (IDLE, SETUP, INJECT, HOLD, DRAIN, DONE);
    signal state, next_state : vpu_state;

    signal dsp_op_sel_decoded : dsp_op_sel_array_t;
    signal sel_scal_in_decoded : std_logic;
    signal sel_output_even_decoded : std_logic;
    signal sel_output_odd_decoded : std_logic;

    signal dsp_op_sel_reg : dsp_op_sel_array_t;
    signal sel_scal_in_reg : std_logic;
    signal sel_output_even_reg : std_logic;
    signal sel_output_odd_reg : std_logic;

begin

    dsp_op_sel <= dsp_op_sel_reg;
    sel_scal_in <= sel_scal_in_reg;
    sel_output_even <= sel_output_even_reg;
    sel_output_odd <= sel_output_odd_reg;

    -- Combinational decoder
    process(all)
    begin
        dsp_op_sel_decoded <= (others => "00");
        sel_scal_in_decoded <= '0';
        sel_output_even_decoded <= '0';
        sel_output_odd_decoded <= '0';

        dsp_op_sel_decoded <= decode_vec_op(vec_op);

        if vec_op = VEC_OP_ADDS or vec_op = VEC_OP_SUBS or vec_op = VEC_OP_MULS then
            sel_scal_in_decoded <= '1';
        end if;

        if vec_op = VEC_OP_MULV or vec_op = VEC_OP_MULS then
            sel_output_even_decoded <= '1';
            sel_output_odd_decoded <= '1';
        elsif vec_op = VEC_OP_MULCV then
            sel_output_odd_decoded <= '1';
        end if;
    end process;

    -- Sequential Process
    process(clk, rst)
    begin
        if rst = '0' then
            state <= IDLE;

            dsp_op_sel_reg <= (others => "00");
            sel_scal_in_reg <= '0';
            sel_output_even_reg <= '0';
            sel_output_odd_reg <= '0';

        elsif rising_edge(clk) then
            state <= next_state;

            if state = SETUP then
                dsp_op_sel_reg <= dsp_op_sel_decoded;
                sel_scal_in_reg <= sel_scal_in_decoded;
                sel_output_even_reg <= sel_output_even_decoded;
                sel_output_odd_reg <= sel_output_odd_decoded;
            end if;
        end if;
    end process;

    -- Combinational Process
    process(all)
    begin
        -- Default assignments
        next_state <= state;
        done <= '0';
        bmu_read_1_start <= '0';
        bmu_read_2_start <= '0';
        bmu_write_start <= '0';
        count_en <= '0';

        case state is

            when IDLE =>
                if en = '1' then
                    next_state <= SETUP;
                end if;

            when SETUP =>
                next_state <= INJECT;
                bmu_read_1_start <= '1';
                bmu_read_2_start <= '1';
                bmu_write_start <= '1';

            when INJECT =>
                next_state <= HOLD;
                count_en <= '1';

            when HOLD =>
                -- done can pulse before exec1_en, so check it unconditionally
                if bmu_read_1_done = '1' then
                    next_state <= DRAIN;
                elsif exec1_en = '1' then
                    next_state <= INJECT;
                end if;

            when DRAIN =>
                if bmu_write_done = '1' then
                    next_state <= DONE;
                end if;

            when DONE =>
                next_state <= IDLE;
                done <= '1';

            when others =>
                next_state <= IDLE;

        end case;
    end process;

end Behavioral;