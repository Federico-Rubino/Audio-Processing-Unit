library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.apu_opcode_pkg.all;
use IEEE.NUMERIC_STD.ALL;

entity APU is
    Port (
        clk, rst : in std_logic;

        -- Read Register File
        opcode : in apu_opcode_t;                               -- Opcode: 0000 copy, 0001 out, ...
        in_buffer1_start : in std_logic_vector(9 downto 0);     -- Address of the first input buffer in the BRAM block 0
        in_buffer1_offset : in std_logic_vector(17 downto 0);   -- Where in the first input buffer to start the operation [bit 17: 0 for sample 15:0, 1 for sample 31:16;  bits 16-10: select the BRAM block;  bits 9-0: actual address in the BRAM block]
        in_buffer2_start : in std_logic_vector(9 downto 0);     -- Address of the second input buffer in the BRAM block 0
        in_buffer2_offset : in std_logic_vector(17 downto 0);   -- Where in the second input buffer to start the operation [bit 17: 0 for sample 15:0, 1 for sample 31:16;  bits 16-10: select the BRAM block;  bits 9-0: actual address in the BRAM block]
        in_buffer3_start : in std_logic_vector(9 downto 0);
        in_buffer3_offset : in std_logic_vector(17 downto 0);
        out_buffer1_start : in std_logic_vector(9 downto 0);
        out_buffer1_offset : in std_logic_vector(17 downto 0);
        out_buffer2_start : in std_logic_vector(9 downto 0);
        out_buffer2_offset : in std_logic_vector(17 downto 0);
        action_size : in std_logic_vector(17 downto 0);         -- On how many samples the operation should be applied (consider there are 2 samples for each memory access)
        block_size : in std_logic_vector(9 downto 0);           -- Length of the buffer in BRAM block 0
        param1 : in std_logic_vector(15 downto 0);              -- First 16 bit parameter used for an operation
        param2 : in std_logic_vector(15 downto 0);              -- Second 16 bit parameter used for an operation
        start_ram_address : in std_logic_vector(31 downto 0);   -- Starting address of the buffer in the RAM (for the 'copy' operation)
        left_right : in std_logic;                              -- 0: left; 1: right
        start : in std_logic;                                   -- 0: do nothing; 1: do the operation

        -- Write Register File
        next_status : out std_logic_vector(31 downto 0);        -- bits 31-16: result of the operation;  bit 15-1: reserved for future use; bit 0: 1 if it is ready to execute, 0 if it is executing some operation

        -- RAM interface
        ram_we_out : out std_logic;
        ram_addr_out : out std_logic_vector(31 downto 0);
        ram_out : in std_logic_vector(31 downto 0);
        
        -- Audio Out
        audio_out : out std_logic_vector(31 downto 0);
        lr_out, enable_out : out std_logic
    );
end APU;

architecture Behavioral of APU is

    -- Internal signals to connect AudioCU and AudioDataPath
    signal sig_enable           : std_logic;
    signal sig_mode             : std_logic_vector(1 downto 0);
    signal sig_we_a             : std_logic;
    signal sig_addr_a           : std_logic_vector(9 downto 0);
    signal sig_select_a         : std_logic_vector(7 downto 0);
    signal sig_we_b             : std_logic;
    signal sig_addr_b           : std_logic_vector(9 downto 0);
    signal sig_select_b         : std_logic_vector(7 downto 0);
    signal sig_ram_we           : std_logic;
    signal sig_ram_addr         : std_logic_vector(31 downto 0);
    signal sig_mux_index        : std_logic_vector(7 downto 0);
    signal sig_write_from       : std_logic_vector(1 downto 0);
    signal sig_audio_out_enable : std_logic;
    signal sig_audio_out_lr     : std_logic;
    signal sig_started          : std_logic;

begin

    CU : entity work.AudioCU
        port map(
            clk => clk,
            rst => rst,
            
            -- Read/Write Register File ports mapping to APU ports
            opcode => opcode,
            in_buffer1_start => in_buffer1_start,
            in_buffer1_offset => in_buffer1_offset,
            in_buffer2_start => in_buffer2_start,
            in_buffer2_offset => in_buffer2_offset,
            in_buffer3_start => in_buffer3_start,
            in_buffer3_offset => in_buffer3_offset,
            out_buffer1_start => out_buffer1_start,
            out_buffer1_offset => out_buffer1_offset,
            out_buffer2_start => out_buffer2_start,
            out_buffer2_offset => out_buffer2_offset,
            action_size => action_size,
            block_size => block_size,
            param1 => param1,
            param2 => param2,
            start_ram_address => start_ram_address,
            left_right => left_right,
            start => start,
            next_status => next_status,
            
            -- Control signals mapping to internal signals
            started => sig_started,
            enable => sig_enable,
            mode => sig_mode,
            we_a => sig_we_a,
            addr_a => sig_addr_a,
            select_a => sig_select_a,
            we_b => sig_we_b,
            addr_b => sig_addr_b,
            select_b => sig_select_b,
            ram_we => sig_ram_we,
            ram_addr => sig_ram_addr,
            mux_index => sig_mux_index,
            write_from => sig_write_from,
            audio_out_enable => sig_audio_out_enable,
            audio_out_lr => sig_audio_out_lr
        );

    DP : entity work.AudioDataPath
        port map(
            clk => clk,
            rst => rst,
            
            -- Control signals driven by CU mapping to internal signals
            enable => sig_enable,
            mode => sig_mode,
            we_a => sig_we_a,
            addr_a => sig_addr_a,
            select_a => sig_select_a,
            we_b => sig_we_b,
            addr_b => sig_addr_b,
            select_b => sig_select_b,
            ram_we => sig_ram_we,
            ram_addr => sig_ram_addr,
            mux_index => sig_mux_index,
            write_from => sig_write_from,
            audio_out_enable => sig_audio_out_enable,
            audio_out_lr => sig_audio_out_lr,
            
            -- Data/Out paths mapping to APU ports
            audio_out => audio_out,
            lr_out => lr_out,
            enable_out => enable_out,
            ram_we_out => ram_we_out,
            ram_addr_out => ram_addr_out,
            ram_out => ram_out
        );

end Behavioral;