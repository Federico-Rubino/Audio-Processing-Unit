#include <apu.h>
#include <gpio.h>
#include <uart.h>
#include "volume.h"
#include "synth_drain.h"
#include "synth_load.h"
#include "synth_play.h"
#include "ampmod_in.h"
#include "ampmod_load.h"
#include "ampmod_process.h"
#include "delay.h"
#include "keys_add.h"

#define UART ((uart_t*) 0x00028000) //base address of UART peripheral
#define GPIO ((gpio_t*) 0x00029000) //base address of GPIO peripheral
#define APU  ((apu_t*)  0x00030000) //base address of APU peripheral


#define GRAIN_ROWS 128 // 256 samples / 2 samples-per-row

typedef struct {
    const char* name;
    void (*on_select)(void);        // re-applies this mode's constant params
    void (*on_grain)(void);         // called once per new grain; NULL = silent (Off mode)
    void (*apply_number)(int x10);  // handles a typed numeric value; NULL = no numeric entry
    void (*print_value)(void);      // prints the mode's current adjustable value; NULL = none
    const char* number_hint;        // shown on an invalid typed value; NULL = no numeric entry
    int (*handle_key)(char c);      // mode-specific key, returns 1 if consumed; NULL = none
} demo_mode_t;


// Passthrough runs volume.shader.
#define PASSTHROUGH_SHADER_ADDR 0
#define SYNTH_DRAIN_SHADER_ADDR (PASSTHROUGH_SHADER_ADDR + (int)(sizeof(volume_words) / sizeof(volume_words[0])))
#define SYNTH_LOAD_SHADER_ADDR (SYNTH_DRAIN_SHADER_ADDR + (int)(sizeof(synth_drain_words) / sizeof(synth_drain_words[0])))
#define SYNTH_PLAY_SHADER_ADDR (SYNTH_LOAD_SHADER_ADDR + (int)(sizeof(synth_load_words) / sizeof(synth_load_words[0])))
#define AMPMOD_IN_SHADER_ADDR (SYNTH_PLAY_SHADER_ADDR + (int)(sizeof(synth_play_words) / sizeof(synth_play_words[0])))
#define AMPMOD_LOAD_SHADER_ADDR (AMPMOD_IN_SHADER_ADDR + (int)(sizeof(ampmod_in_words) / sizeof(ampmod_in_words[0])))
#define AMPMOD_PROCESS_SHADER_ADDR (AMPMOD_LOAD_SHADER_ADDR + (int)(sizeof(ampmod_load_words) / sizeof(ampmod_load_words[0])))
#define DELAY_SHADER_ADDR (AMPMOD_PROCESS_SHADER_ADDR + (int)(sizeof(ampmod_process_words) / sizeof(ampmod_process_words[0])))
#define KEYS_ADD_SHADER_ADDR (DELAY_SHADER_ADDR + (int)(sizeof(delay_words) / sizeof(delay_words[0])))

#define ENTRY_BUF_CAP 8
static char entry_buf[ENTRY_BUF_CAP];
static int entry_buf_len = 0;
static int entering_volume = 0;
static int entering_delay_time = 0;

static int parse_signed_x10(const char* s, int len, int* out) {
    int i = 0;
    int neg = 0;
    if (i < len && (s[i] == '+' || s[i] == '-')) {
        neg = (s[i] == '-');
        i++;
    }

    int int_part = 0;
    int frac_digit = 0;
    int seen_dot = 0;
    int any_digit = 0;

    for (; i < len; i++) {
        char c = s[i];
        if (c == '.') {
            if (seen_dot) return 0;
            seen_dot = 1;
        } else if (c >= '0' && c <= '9') {
            any_digit = 1;
            if (!seen_dot) {
                int_part = int_part * 10 + (c - '0');
            } else if (frac_digit == 0) {
                frac_digit = c - '0';
            }
        } else {
            return 0;
        }
    }
    if (!any_digit) return 0;

    int mag_x10 = int_part * 10 + frac_digit;
    *out = neg ? -mag_x10 : mag_x10;
    return 1;
}

// ---- Global volume ----
#define VOL_DB_X10_UNITY 0
#define VOL_DB_X10_MIN (-600)
#define VOL_DB_X10_MAX 60

static int volume_db_x10 = VOL_DB_X10_UNITY;

// 10^(dB/20) as Q8.8, 1 dB steps from -60 to +6
static const uint16_t db_to_q88[] = {
    0, 0, 0, 0, 0, 0, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1,
    2, 2, 2, 2, 3, 3, 3, 4,
    4, 5, 5, 6, 6, 7, 8, 9,
    10, 11, 13, 14, 16, 18, 20, 23,
    26, 29, 32, 36, 41, 46, 51, 57,
    64, 72, 81, 91, 102, 114, 128, 144,
    162, 181, 203, 228, 256, 287, 322, 362,
    406, 455, 511, 573,
};

// interpolates between adjacent 1 dB entries for the fractional part
static uint32_t db_x10_to_q88(int db_x10) {
    if (db_x10 < VOL_DB_X10_MIN) db_x10 = VOL_DB_X10_MIN;
    if (db_x10 > VOL_DB_X10_MAX) db_x10 = VOL_DB_X10_MAX;

    int shifted = db_x10 + 600; // -60.0dB..+6.0dB -> 0..660, non-negative
    int idx = shifted / 10;
    int frac = shifted % 10;

    uint32_t lo = db_to_q88[idx];
    uint32_t hi = db_to_q88[idx + 1];
    return lo + ((hi - lo) * (uint32_t)frac) / 10;
}

static void apply_volume(void) {
    uint32_t q88 = db_x10_to_q88(volume_db_x10);
    apu_load_param(APU, V_VOLUME, q88, q88);
    apu_load_param(APU, D_VOLUME, q88, q88);
}

static void print_volume(void) {
    int mag = volume_db_x10 < 0 ? -volume_db_x10 : volume_db_x10;
    printuart(UART, "Volume: ");
    if (volume_db_x10 < 0) {
        uart_write_byte(UART, '-');
    }
    printuart_uint32(UART, (uint32_t)(mag / 10));
    printuart(UART, ".");
    printuart_uint32(UART, (uint32_t)(mag % 10));
    printuart(UART, " dB\r\n");
}

static void volume_apply_number(int db_x10) {
    if (db_x10 < VOL_DB_X10_MIN) db_x10 = VOL_DB_X10_MIN;
    if (db_x10 > VOL_DB_X10_MAX) db_x10 = VOL_DB_X10_MAX;
    volume_db_x10 = db_x10;
    apply_volume();
    printuart(UART, "\r\n");
    print_volume();
}

// Off

static void mode_off_select(void) {
    
}

// Passthrough
static void mode_passthrough_select(void) {
    apu_load_param(APU, V_IN_START, 0, 128);
    apu_load_param(APU, V_GRAIN_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_load_param(APU, V_OP_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apply_volume();
}

static void mode_passthrough_grain(void) {
    apu_start_shader(APU, PASSTHROUGH_SHADER_ADDR);
}

//Synth

#define SYNTH_ROW 256          // fixed a-ram destination row for the synth's grain
#define SYNTH_TABLE_SIZE 256   // matches phase accumulator's top 8 bits (phase >> 24)
#define SYNTH_AMPLITUDE 10000  // headroom under int16 full scale (32767)
#define SYNTH_PI 3.14159265f

#define SYNTH_FREQ_X10_DEFAULT 4400 // 440.0 Hz
#define SYNTH_FREQ_X10_MIN 200      // 20.0 Hz
#define SYNTH_FREQ_X10_MAX 200000   // 20000.0 Hz

static int16_t synth_sine_table[SYNTH_TABLE_SIZE];
static uint32_t synth_phase = 0;
static uint32_t synth_phase_inc = 0;
static int synth_freq_x10 = SYNTH_FREQ_X10_DEFAULT;

// Bhaskara I's sine approximation
static float synth_bhaskara_sin(float x) {
    int neg = 0;
    if (x >= SYNTH_PI) { x -= SYNTH_PI; neg = 1; }
    float y = x * (SYNTH_PI - x);
    float s = (16.0f * y) / (5.0f * SYNTH_PI * SYNTH_PI - 4.0f * y);
    return neg ? -s : s;
}

static void synth_init_table(void) {
    for (int i = 0; i < SYNTH_TABLE_SIZE; i++) {
        float angle = 2.0f * SYNTH_PI * (float)i / (float)SYNTH_TABLE_SIZE;
        synth_sine_table[i] = (int16_t)(SYNTH_AMPLITUDE * synth_bhaskara_sin(angle));
    }
}

// increment = freq_hz * 2^32 / 48000 = freq_x10 * 2^32 / 480000
static void synth_set_frequency(int freq_x10) {
    synth_phase_inc = (uint32_t)(((uint64_t)freq_x10 * 4294967296ULL) / 480000ULL);
}

static void mode_synth_select(void) {
    apu_load_param(APU, S_WAVE_START, SYNTH_ROW, SYNTH_ROW);
    apu_load_param(APU, S_WAVE_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_load_param(APU, S_OP_START, SYNTH_ROW, SYNTH_ROW);
    apu_load_param(APU, S_OP_LEN, GRAIN_ROWS, GRAIN_ROWS);
    synth_set_frequency(synth_freq_x10);
}

static void mode_synth_grain(void) {
    // drain the real grain-arrival pulse first (both channels)
    apu_load_param(APU, S_DRAIN_START, 0, 128);
    apu_load_param(APU, S_DRAIN_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_start_shader(APU, SYNTH_DRAIN_SHADER_ADDR);

    uint32_t gain_q88 = db_x10_to_q88(volume_db_x10);

    for (int i = 0; i < GRAIN_ROWS; i++) {
        int16_t s0 = (int16_t)(((int32_t)synth_sine_table[synth_phase >> 24] * (int32_t)gain_q88) >> 8);
        synth_phase += synth_phase_inc;
        int16_t s1 = (int16_t)(((int32_t)synth_sine_table[synth_phase >> 24] * (int32_t)gain_q88) >> 8);
        synth_phase += synth_phase_inc;

        uint32_t word = ((uint32_t)(uint16_t)s0) | (((uint32_t)(uint16_t)s1) << 16);
        apu_load_param(APU, i, word, word);
    }

    apu_start_shader(APU, SYNTH_LOAD_SHADER_ADDR);

    apu_load_param(APU, S_PLAY_START, SYNTH_ROW, SYNTH_ROW);
    apu_load_param(APU, S_PLAY_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_start_shader(APU, SYNTH_PLAY_SHADER_ADDR);
}

static void print_frequency(void) {
    printuart(UART, "Frequency: ");
    printuart_uint32(UART, (uint32_t)(synth_freq_x10 / 10));
    printuart(UART, ".");
    printuart_uint32(UART, (uint32_t)(synth_freq_x10 % 10));
    printuart(UART, " Hz\r\n");
}

static void synth_apply_number(int freq_x10) {
    if (freq_x10 < SYNTH_FREQ_X10_MIN) freq_x10 = SYNTH_FREQ_X10_MIN;
    if (freq_x10 > SYNTH_FREQ_X10_MAX) freq_x10 = SYNTH_FREQ_X10_MAX;
    synth_freq_x10 = freq_x10;
    synth_set_frequency(freq_x10);
    printuart(UART, "\r\n");
    print_frequency();
}

// Keys
#define KEYS_ACCUM_ROW 11520
#define KEYS_TEMP_ROW 11776
#define KEYS_NUM_NOTES 13
static const char keys_key_map[KEYS_NUM_NOTES] = {'a','w','s','e','d','f','t','g','y','h','u','j','k'};
static const char* const keys_note_name[KEYS_NUM_NOTES] = {"C4","C#4","D4","D#4","E4","F4","F#4","G4","G#4","A4","A#4","B4","C5"};
static const uint32_t keys_note_freq_x10[KEYS_NUM_NOTES] = {2616, 2772, 2937, 3111, 3296, 3492, 3700, 3920, 4153, 4400, 4662, 4939, 5233};

static int keys_active[KEYS_NUM_NOTES];
static uint32_t keys_phase[KEYS_NUM_NOTES];
static uint32_t keys_phase_inc[KEYS_NUM_NOTES];

static void print_keys_status(void) {
    printuart(UART, "Notes:");
    int any = 0;
    for (int n = 0; n < KEYS_NUM_NOTES; n++) {
        if (keys_active[n]) {
            printuart(UART, " ");
            printuart(UART, keys_note_name[n]);
            any = 1;
        }
    }
    if (!any) {
        printuart(UART, " (none)");
    }
    printuart(UART, "\r\n");
}

// space releases all
static int keys_handle_key(char c) {
    if (c == ' ') {
        for (int n = 0; n < KEYS_NUM_NOTES; n++) {
            keys_active[n] = 0;
        }
        printuart(UART, "\r\n");
        print_keys_status();
        return 1;
    }
    for (int n = 0; n < KEYS_NUM_NOTES; n++) {
        if (keys_key_map[n] == c) {
            keys_active[n] = !keys_active[n];
            if (keys_active[n]) {
                keys_phase[n] = 0;
            }
            printuart(UART, "\r\n");
            print_keys_status();
            return 1;
        }
    }
    return 0;
}

static void mode_keys_select(void) {
    apu_load_param(APU, S_WAVE_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_load_param(APU, S_OP_LEN, GRAIN_ROWS, GRAIN_ROWS);
    for (int n = 0; n < KEYS_NUM_NOTES; n++) {
        keys_active[n] = 0;
        keys_phase[n] = 0;
        keys_phase_inc[n] = (uint32_t)(((uint64_t)keys_note_freq_x10[n] * 4294967296ULL) / 480000ULL);
    }
}

static void keys_load_note(int n, uint32_t gain_q88, uint32_t target) {
    for (int i = 0; i < GRAIN_ROWS; i++) {
        int16_t s0 = (int16_t)(((int32_t)synth_sine_table[keys_phase[n] >> 24] * (int32_t)gain_q88) >> 8);
        keys_phase[n] += keys_phase_inc[n];
        int16_t s1 = (int16_t)(((int32_t)synth_sine_table[keys_phase[n] >> 24] * (int32_t)gain_q88) >> 8);
        keys_phase[n] += keys_phase_inc[n];
        uint32_t word = ((uint32_t)(uint16_t)s0) | (((uint32_t)(uint16_t)s1) << 16);
        apu_load_param(APU, i, word, word);
    }
    apu_load_param(APU, S_WAVE_START, target, target);
    apu_load_param(APU, S_OP_START, target, target);
    apu_start_shader(APU, SYNTH_LOAD_SHADER_ADDR);
}

static void mode_keys_grain(void) {
    apu_load_param(APU, S_DRAIN_START, 0, 128);
    apu_load_param(APU, S_DRAIN_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_start_shader(APU, SYNTH_DRAIN_SHADER_ADDR);

    uint32_t gain_q88 = db_x10_to_q88(volume_db_x10);
    int any_active = 0;

    for (int n = 0; n < KEYS_NUM_NOTES; n++) {
        if (!keys_active[n]) continue;

        if (!any_active) {
            keys_load_note(n, gain_q88, KEYS_ACCUM_ROW);
            any_active = 1;
        } else {
            keys_load_note(n, gain_q88, KEYS_TEMP_ROW);
            apu_load_param(APU, K_ACC_START, KEYS_ACCUM_ROW, KEYS_ACCUM_ROW);
            apu_load_param(APU, K_ACC_LEN, GRAIN_ROWS, GRAIN_ROWS);
            apu_load_param(APU, K_TEMP_START, KEYS_TEMP_ROW, KEYS_TEMP_ROW);
            apu_start_shader(APU, KEYS_ADD_SHADER_ADDR); // accumulator += temp
        }
    }

    if (!any_active) {
        for (int i = 0; i < GRAIN_ROWS; i++) {
            apu_load_param(APU, i, 0, 0);
        }
        apu_load_param(APU, S_WAVE_START, KEYS_ACCUM_ROW, KEYS_ACCUM_ROW);
        apu_load_param(APU, S_OP_START, KEYS_ACCUM_ROW, KEYS_ACCUM_ROW);
        apu_start_shader(APU, SYNTH_LOAD_SHADER_ADDR);
    }

    apu_load_param(APU, S_PLAY_START, KEYS_ACCUM_ROW, KEYS_ACCUM_ROW);
    apu_load_param(APU, S_PLAY_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_start_shader(APU, SYNTH_PLAY_SHADER_ADDR);
}

// AmpMod
#define AM_IN_ROW 0    // scratch row for captured audio, 0=left/128=right
#define AM_MOD_ROW 512 // fixed a-ram row for the modulator wave
#define AM_TABLE_SIZE 256   // matches phase accumulator's top 8 bits (phase >> 24)
#define AM_MOD_AMPLITUDE 256 // Q8.8 unity -- this wave is a MUL_VECTOR multiplier, not a raw audio sample
#define AM_PI 3.14159265f

#define AM_FREQ_X10_DEFAULT 50   // 5.0 Hz
#define AM_FREQ_X10_MIN 1        // 0.1 Hz
#define AM_FREQ_X10_MAX 20000    // 2000.0 Hz

static int16_t am_mod_table[AM_TABLE_SIZE];
static uint32_t am_phase = 0;
static uint32_t am_phase_inc = 0;
static int am_freq_x10 = AM_FREQ_X10_DEFAULT;
static int am_bipolar = 0; // 0 = unipolar/tremolo (default), 1 = bipolar/ring-mod

static void am_init_table(void) {
    for (int i = 0; i < AM_TABLE_SIZE; i++) {
        float angle = 2.0f * AM_PI * (float)i / (float)AM_TABLE_SIZE;
        am_mod_table[i] = (int16_t)(AM_MOD_AMPLITUDE * synth_bhaskara_sin(angle));
    }
}

static void am_set_frequency(int freq_x10) {
    am_phase_inc = (uint32_t)(((uint64_t)freq_x10 * 4294967296ULL) / 480000ULL);
}

static void mode_ampmod_select(void) {
    // AM_IN/AM_AUDIO reasserted each grain
    apu_load_param(APU, AM_MOD_WAVE_START, AM_MOD_ROW, AM_MOD_ROW);
    apu_load_param(APU, AM_MOD_WAVE_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_load_param(APU, AM_MOD_OP_START, AM_MOD_ROW, AM_MOD_ROW);
    apu_load_param(APU, AM_MOD_OP_LEN, GRAIN_ROWS, GRAIN_ROWS);
    am_set_frequency(am_freq_x10);
}

static void mode_ampmod_grain(void) {

    apu_load_param(APU, AM_IN_START, 0, 128);
    apu_load_param(APU, AM_IN_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_start_shader(APU, AMPMOD_IN_SHADER_ADDR);

    // modulator wave for the grain, with volume folded in
    uint32_t gain_q88 = db_x10_to_q88(volume_db_x10);

    for (int i = 0; i < GRAIN_ROWS; i++) {
        int32_t m0 = am_mod_table[am_phase >> 24];
        am_phase += am_phase_inc;
        int32_t m1 = am_mod_table[am_phase >> 24];
        am_phase += am_phase_inc;

        if (!am_bipolar) {
            m0 = (m0 + 256) / 2; // -256..256 -> 0..256
            m1 = (m1 + 256) / 2;
        }
        m0 = (m0 * (int32_t)gain_q88) >> 8;
        m1 = (m1 * (int32_t)gain_q88) >> 8;

        uint32_t word = ((uint32_t)(uint16_t)(int16_t)m0) | (((uint32_t)(uint16_t)(int16_t)m1) << 16);
        apu_load_param(APU, i, word, word);
    }

    apu_start_shader(APU, AMPMOD_LOAD_SHADER_ADDR);

    apu_load_param(APU, AM_AUDIO_START, 0, 128);
    apu_load_param(APU, AM_GRAIN_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_load_param(APU, AM_OP_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_load_param(APU, AM_MOD_START, AM_MOD_ROW, AM_MOD_ROW);
    apu_start_shader(APU, AMPMOD_PROCESS_SHADER_ADDR);
}

static void print_ampmod(void) {
    printuart(UART, "Mod freq: ");
    printuart_uint32(UART, (uint32_t)(am_freq_x10 / 10));
    printuart(UART, ".");
    printuart_uint32(UART, (uint32_t)(am_freq_x10 % 10));
    printuart(UART, " Hz (");
    printuart(UART, am_bipolar ? "bipolar/ring-mod" : "unipolar/tremolo");
    printuart(UART, ", 'b' to toggle)\r\n");
    printuart(UART, "Type a number + Enter to set frequency\r\n");
}

static void ampmod_apply_number(int freq_x10) {
    if (freq_x10 < AM_FREQ_X10_MIN) freq_x10 = AM_FREQ_X10_MIN;
    if (freq_x10 > AM_FREQ_X10_MAX) freq_x10 = AM_FREQ_X10_MAX;
    am_freq_x10 = freq_x10;
    am_set_frequency(freq_x10);
    printuart(UART, "\r\n");
    print_ampmod();
}

static void toggle_am_bipolar(void) {
    am_bipolar = !am_bipolar;
    printuart(UART, "\r\n");
    print_ampmod();
}

// Delay
#define DELAY_MAX_SLOTS 100         // reserves up to 100 * 5.33ms =~ 533ms
#define DELAY_SLOT_SPACING 32       // actual rows per 256-sample grain
#define DELAY_RING_BASE_L 1024
#define DELAY_RING_BASE_R (DELAY_RING_BASE_L + DELAY_MAX_SLOTS * DELAY_SLOT_SPACING)
#define DELAY_TEMP_ROW 768
#define DELAY_OUT_ROW 896 // volume-scaled output copy, kept separate from D_DELAY_START (see delay.shader)

#define DELAY_FEEDBACK_X10_DEFAULT 550 // 55.0%
#define DELAY_FEEDBACK_X10_MIN 0
#define DELAY_FEEDBACK_X10_MAX 900     // clamped below 100% so echoes always decay

#define DELAY_TIME_MS_X10_DEFAULT 1000 // 100.0 ms
#define DELAY_TIME_MS_X10_MIN 100      // 10.0 ms
#define DELAY_TIME_MS_X10_MAX 5000     // 500.0 ms

static int delay_feedback_x10 = DELAY_FEEDBACK_X10_DEFAULT;
static int delay_time_ms_x10 = DELAY_TIME_MS_X10_DEFAULT;
static int delay_num_slots = 1;
static int delay_grain_counter = 0;

static void apply_delay_feedback(void) {
    uint32_t q88 = (uint32_t)((delay_feedback_x10 * 256) / 1000);
    apu_load_param(APU, D_FEEDBACK, q88, q88);
}

// slots = ms / (256 samples / 48000 Hz * 1000) = ms * 3/16, rounded
static int delay_ms_x10_to_slots(int ms_x10) {
    int n = (ms_x10 * 3 + 80) / 160;
    if (n < 1) n = 1;
    if (n > DELAY_MAX_SLOTS) n = DELAY_MAX_SLOTS;
    return n;
}

static void print_delay(void) {
    printuart(UART, "Feedback: ");
    printuart_uint32(UART, (uint32_t)(delay_feedback_x10 / 10));
    printuart(UART, ".");
    printuart_uint32(UART, (uint32_t)(delay_feedback_x10 % 10));
    printuart(UART, "%\r\n");
    printuart(UART, "Delay time: ");
    printuart_uint32(UART, (uint32_t)(delay_time_ms_x10 / 10));
    printuart(UART, ".");
    printuart_uint32(UART, (uint32_t)(delay_time_ms_x10 % 10));
    printuart(UART, " ms (");
    printuart_uint32(UART, (uint32_t)delay_num_slots);
    printuart(UART, " slots, 'm' to set)\r\n");
}

static void delay_apply_number(int feedback_x10) {
    if (feedback_x10 < DELAY_FEEDBACK_X10_MIN) feedback_x10 = DELAY_FEEDBACK_X10_MIN;
    if (feedback_x10 > DELAY_FEEDBACK_X10_MAX) feedback_x10 = DELAY_FEEDBACK_X10_MAX;
    delay_feedback_x10 = feedback_x10;
    apply_delay_feedback();
    printuart(UART, "\r\n");
    print_delay();
}

static void delay_time_apply_number(int ms_x10) {
    if (ms_x10 < DELAY_TIME_MS_X10_MIN) ms_x10 = DELAY_TIME_MS_X10_MIN;
    if (ms_x10 > DELAY_TIME_MS_X10_MAX) ms_x10 = DELAY_TIME_MS_X10_MAX;
    delay_time_ms_x10 = ms_x10;
    delay_num_slots = delay_ms_x10_to_slots(ms_x10);
    printuart(UART, "\r\n");
    print_delay();
}

static void mode_delay_select(void) {
    apu_load_param(APU, D_IN_START, 0, 128);
    apu_load_param(APU, D_LEN, GRAIN_ROWS, GRAIN_ROWS);
    apu_load_param(APU, D_TEMP_START, DELAY_TEMP_ROW, DELAY_TEMP_ROW);
    apu_load_param(APU, D_OUT_START, DELAY_OUT_ROW, DELAY_OUT_ROW);
    delay_grain_counter = 0;
    delay_num_slots = delay_ms_x10_to_slots(delay_time_ms_x10);
    apply_delay_feedback();
    apply_volume();
}

static void mode_delay_grain(void) {
    int slot = delay_grain_counter % delay_num_slots;
    uint32_t row_l = DELAY_RING_BASE_L + slot * DELAY_SLOT_SPACING;
    uint32_t row_r = DELAY_RING_BASE_R + slot * DELAY_SLOT_SPACING;
    apu_load_param(APU, D_DELAY_START, row_l, row_r);
    apu_start_shader(APU, DELAY_SHADER_ADDR);
    delay_grain_counter++;
}

// Mode table

static const demo_mode_t modes[] = {
    { "Off",         mode_off_select,         0,                       0,                   0,                 0, 0 },
    { "Passthrough", mode_passthrough_select, mode_passthrough_grain,  0,                   0,                 0, 0 },
    { "Synth",       mode_synth_select,       mode_synth_grain,        synth_apply_number,  print_frequency,
      "e.g. 440, 440.5, range 20..20000 Hz", 0 },
    { "Keys",        mode_keys_select,        mode_keys_grain,         0,                   print_keys_status,
      0, keys_handle_key },
    { "AmpMod",      mode_ampmod_select,      mode_ampmod_grain,       ampmod_apply_number, print_ampmod,
      "e.g. 5, 0.1, 200, range 0.1..2000 Hz", 0 },
    { "Delay",       mode_delay_select,       mode_delay_grain,        delay_apply_number,  print_delay,
      "e.g. 55, 0, 90, range 0..90 %", 0 },
};
#define NUM_MODES ((int)(sizeof(modes) / sizeof(modes[0])))

static uint16_t mode_switch_mask(int i) { return BIT(i + 1); }
static uint8_t mode_led_mask(int i) { return (uint8_t)BIT(i + 1); }

static int current_mode = 0;

static void update_mode_leds(void) {
    for (int i = 0; i < NUM_MODES; i++) {
        gpio_set_output(GPIO, mode_led_mask(i), i == current_mode);
    }
}

static void print_help(void) {
    printuart(UART, "\r\n-- APU Demo --\r\n");
    printuart(UART, "SW1-SW6 : select mode directly (matches LED1-LED6)\r\n");
    printuart(UART, "n/p : next/prev mode\r\n");
    printuart(UART, "l   : list modes\r\n");
    printuart(UART, "v   : set volume (any mode) -- type a dB value + Enter\r\n");
    printuart(UART, "m   : set Delay's delay time -- type a ms value + Enter\r\n");
    printuart(UART, "b   : toggle AmpMod bipolar/unipolar (ring-mod/tremolo)\r\n");
    printuart(UART, "?   : this help\r\n");
    printuart(UART, "In a mode with an adjustable value: type it + Enter to set\r\n");
    printuart(UART, "In Keys mode: a-w-s-e-d-f-t-g-y-h-u-j-k play C4..C5, space releases all\r\n");
}

static void print_status(void) {
    printuart(UART, "Mode: ");
    printuart(UART, modes[current_mode].name);
    printuart(UART, "\r\n");
    if (modes[current_mode].print_value) {
        modes[current_mode].print_value();
    }
    print_volume();
}

static void finalize_entry(void) {
    if (entry_buf_len == 0) {
        entering_volume = 0;
        entering_delay_time = 0;
        return;
    }

    int x10;
    void (*target)(int) = entering_volume ? volume_apply_number
                         : entering_delay_time ? delay_time_apply_number
                         : modes[current_mode].apply_number;
    const char* hint = entering_volume ? "e.g. -6, 0, +3.5, range -60..+6 dB"
                     : entering_delay_time ? "e.g. 100, 10, 500, range 10..500 ms"
                     : modes[current_mode].number_hint;

    if (parse_signed_x10(entry_buf, entry_buf_len, &x10) && target) {
        target(x10);
    } else {
        printuart(UART, "\r\nInvalid value");
        if (hint) {
            printuart(UART, " (expected ");
            printuart(UART, hint);
            printuart(UART, ")");
        }
        printuart(UART, "\r\n");
    }
    entering_volume = 0;
    entering_delay_time = 0;
    entry_buf_len = 0;
}

static void list_modes(void) {
    for (int i = 0; i < NUM_MODES; i++) {
        printuart_uint32(UART, (uint32_t)i);
        printuart(UART, ": ");
        printuart(UART, modes[i].name);
        if (i == current_mode) {
            printuart(UART, "  <-- current");
        }
        printuart(UART, "\r\n");
    }
}

static void set_mode(int idx) {
    if (idx < 0) idx = NUM_MODES - 1;
    if (idx >= NUM_MODES) idx = 0;
    current_mode = idx;
    entry_buf_len = 0;
    entering_volume = 0;
    entering_delay_time = 0;
    modes[current_mode].on_select();
    update_mode_leds();
    print_status();
}

// IR pre-load stage
#define IR_READY_SIGNAL 0xCC
#define IR_ACK_SIGNAL 0xCD
#define IR_CMD_LOAD_GRAIN 0x01
#define IR_CMD_FINISHED 0x02

#define IR_BASE_ROW 12800
#define IR_GRAIN_SPACING 32    // actual rows per 256-sample grain
#define IR_MAX_GRAINS 350      // caps a-ram usage well under its real capacity

static void ir_preload_stage(void) {
    printuart(UART, "\r\nWaiting for IR upload (flip SW0 to skip)...\r\n");

    uint32_t sw0_prev = gpio_get_input(GPIO, SW_00) != 0;
    while (!uart_has_data(UART)) {
        uint32_t sw0 = gpio_get_input(GPIO, SW_00) != 0;
        if (sw0 && !sw0_prev) {
            printuart(UART, "IR upload skipped.\r\n");
            return;
        }
        sw0_prev = sw0;
        uart_write_byte(UART, IR_READY_SIGNAL);
    }

    uint32_t grain_index = 0;
    while (1) {
        uint8_t cmd = uart_read_byte(UART);
        if (cmd == IR_CMD_FINISHED) {
            break;
        } else if (cmd == IR_CMD_LOAD_GRAIN) {
            for (int i = 0; i < GRAIN_ROWS; i++) {
                uint32_t word = uart_read_word(UART);
                apu_load_param(APU, i, word, word);
            }

            uint32_t idx = grain_index < IR_MAX_GRAINS ? grain_index : IR_MAX_GRAINS - 1;
            uint32_t target = IR_BASE_ROW + idx * IR_GRAIN_SPACING;
            apu_load_param(APU, S_WAVE_START, target, target);
            apu_load_param(APU, S_WAVE_LEN, GRAIN_ROWS, GRAIN_ROWS);
            apu_load_param(APU, S_OP_START, target, target);
            apu_load_param(APU, S_OP_LEN, GRAIN_ROWS, GRAIN_ROWS);
            apu_start_shader(APU, SYNTH_LOAD_SHADER_ADDR);

            grain_index++;
            uart_write_byte(UART, IR_ACK_SIGNAL);
        }
    }

    printuart(UART, "IR upload done: ");
    printuart_uint32(UART, grain_index);
    printuart(UART, " grains.\r\n");
}

int main() {
    apu_load_shader(APU, PASSTHROUGH_SHADER_ADDR, (uint32_t*)volume_words,
                     sizeof(volume_words) / sizeof(volume_words[0]));
    apu_load_shader(APU, SYNTH_DRAIN_SHADER_ADDR, (uint32_t*)synth_drain_words,
                     sizeof(synth_drain_words) / sizeof(synth_drain_words[0]));
    apu_load_shader(APU, SYNTH_LOAD_SHADER_ADDR, (uint32_t*)synth_load_words,
                     sizeof(synth_load_words) / sizeof(synth_load_words[0]));
    apu_load_shader(APU, SYNTH_PLAY_SHADER_ADDR, (uint32_t*)synth_play_words,
                     sizeof(synth_play_words) / sizeof(synth_play_words[0]));
    apu_load_shader(APU, AMPMOD_IN_SHADER_ADDR, (uint32_t*)ampmod_in_words,
                     sizeof(ampmod_in_words) / sizeof(ampmod_in_words[0]));
    apu_load_shader(APU, AMPMOD_LOAD_SHADER_ADDR, (uint32_t*)ampmod_load_words,
                     sizeof(ampmod_load_words) / sizeof(ampmod_load_words[0]));
    apu_load_shader(APU, AMPMOD_PROCESS_SHADER_ADDR, (uint32_t*)ampmod_process_words,
                     sizeof(ampmod_process_words) / sizeof(ampmod_process_words[0]));
    apu_load_shader(APU, DELAY_SHADER_ADDR, (uint32_t*)delay_words,
                     sizeof(delay_words) / sizeof(delay_words[0]));
    apu_load_shader(APU, KEYS_ADD_SHADER_ADDR, (uint32_t*)keys_add_words,
                     sizeof(keys_add_words) / sizeof(keys_add_words[0]));

    ir_preload_stage();

    synth_init_table();
    am_init_table();
    set_mode(0);

    //UART menu is gated by SW0
    uint32_t sw0_prev = 0;

    uint32_t mode_switches_prev = gpio_get_input(GPIO, 0xFE);

    while (1)
    {
        if (apu_has_new_grain(APU) && modes[current_mode].on_grain) {
            modes[current_mode].on_grain();
        }

        uint32_t mode_switches = gpio_get_input(GPIO, 0xFE);
        for (int i = 0; i < NUM_MODES; i++) {
            uint16_t mask = mode_switch_mask(i);
            if ((mode_switches & mask) && !(mode_switches_prev & mask)) {
                set_mode(i);
                break;
            }
        }
        mode_switches_prev = mode_switches;

        uint32_t sw0 = gpio_get_input(GPIO, SW_00);

        if (sw0) {
            if (!sw0_prev) {
                print_help();
                print_status();
            }

            if (uart_has_data(UART)) {
                char c = getchar(UART);

                if (modes[current_mode].handle_key && modes[current_mode].handle_key(c)) {
                    // consumed
                } else if ((modes[current_mode].apply_number || entering_volume || entering_delay_time) &&
                    ((c >= '0' && c <= '9') || c == '.' || c == '+' || c == '-' ||
                     c == '\r' || c == '\n' || c == 0x08 || c == 0x7F)) {
                    if (c == '\r' || c == '\n') {
                        finalize_entry();
                    } else if (c == 0x08 || c == 0x7F) {
                        if (entry_buf_len > 0) {
                            entry_buf_len--;
                            printuart(UART, "\b \b");
                        }
                    } else if (entry_buf_len < ENTRY_BUF_CAP - 1) {
                        entry_buf[entry_buf_len++] = c;
                        uart_write_byte(UART, (uint8_t)c);
                    }
                } else {
                    switch (c) {
                        case 'n': case 'N': set_mode(current_mode + 1); break;
                        case 'p': case 'P': set_mode(current_mode - 1); break;
                        case 'l': case 'L': list_modes(); break;
                        case 'v': case 'V':
                            entering_volume = 1;
                            entry_buf_len = 0;
                            printuart(UART, "\r\nVolume (dB): ");
                            break;
                        case 'm': case 'M':
                            entering_delay_time = 1;
                            entry_buf_len = 0;
                            printuart(UART, "\r\nDelay time (ms): ");
                            break;
                        case 'b': case 'B': toggle_am_bipolar(); break;
                        case '?': print_help(); break;
                        default: break;
                    }
                }
            }
        } else {

            if (uart_has_data(UART)) {
                getchar(UART);
            }
        }

        sw0_prev = sw0;
    }
}
