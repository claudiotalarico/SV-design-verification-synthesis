import yaml
import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, Event
import random

# ============================================================
#  Helper: Virtual Clock Generator (start with Low Phase)
# ============================================================
def make_virtual_clock(dut, period_ns):
    """
    Create a virtual clock generator and return:
      - virtual_rise: Event triggered on rising edges
      - virtual_fall: Event triggered on falling edges
      - virtual_clock_gen: coroutine to start with cocotb.start_soon()
    """

    virtual_rise = Event()
    virtual_fall = Event()

    half = period_ns / 2
    has_vclk = hasattr(dut, "v_clk")

    async def virtual_clock_gen():
        while True:
            # --- 1. Low Phase (Falling Edge Start) ---
            if has_vclk:
                dut.v_clk.value = 0
        
            virtual_fall.set()
            virtual_fall.clear()
        
            # Stay low for half the period
            await Timer(half, unit="ns")

            # --- 2. High Phase (Rising Edge) ---
            if has_vclk:
                dut.v_clk.value = 1

            virtual_rise.set()
            virtual_rise.clear()

            # Stay high for half the period
            await Timer(half, unit="ns")

    return virtual_rise, virtual_fall, virtual_clock_gen

# ==============================================================
#  Helper: wait for N rising edges of virtual clock (default= 1)
# ==============================================================
async def wait_virtual_rising_edges(virtual_rise, count=1):
    for _ in range(count):
        await virtual_rise.wait()

# ==============================================================
#  Helper: wait for N falling edges of virtual clock (default=1)
# ==============================================================
async def wait_virtual_falling_edges(virtual_fall, count=1):
    for _ in range(count):
        await virtual_fall.wait()

# ============================================================
#  Physical clock Helpers
# ============================================================
async def wait_physical_rising_edges(clk_signal, count=1):
    for _ in range(count):
        await RisingEdge(clk_signal)

async def wait_physical_falling_edges(clk_signal, count=1):
    for _ in range(count):
        await FallingEdge(clk_signal)


# ============================================================
#  Helper: apply async active low reset
# ============================================================
async def apply_reset(dut, vclk_rise, vclk_fall):
    """
    Asserts rst_n on falling edge and de-asserts on rising edges
    """
    await wait_virtual_rising_edges(vclk_rise)
    dut.rst_n.value = 0
    await wait_virtual_falling_edges(vclk_fall)
    dut.rst_n.value = 1

# ============================================================
#  regression test #1
# ============================================================
async def test_counter(dut, vclk_rise, vclk_fall, num_cycles=20, period_ns=10, skew_ns=3):
    """
    Helper function to verify up-counting logic.
    """
    print(f"\n")
    dut._log.info(f"-- Up Counter Verification ({num_cycles} cycles)")

    # Reset 
    await apply_reset(dut, vclk_rise, vclk_fall)

    for index in range(num_cycles):
        # Sample output during the stable phase
        await wait_physical_falling_edges(dut.clk)
        await Timer(period_ns/2 - skew_ns, unit='ns')

        probed_val = int(dut.count.value)
        expected_val = index % 10

        dut._log.info(f"Iter. {index:02d} | Got: {probed_val:04b} | Expected: {expected_val:04b}")

        assert probed_val == expected_val, (
            f"Mismatch at index {index}! Expected {expected_val:04b}, Got {probed_val:04b}"
        )

        # Advance virtual clock
        await wait_virtual_rising_edges(vclk_rise, 1)

    dut._log.info("-- Up Counter Verification PASSED.")

# ============================================================
#  regression test #2
# ============================================================
async def test_valid_load(dut, vclk_rise, period_ns=10, skew_ns=3):
    """
    Helper function to verify the loading of a valid value in the counter 
    """
    print(f"\n")
    dut._log.info("-- Testing Valid Load (data_in = 7)")
    
    await wait_virtual_rising_edges(vclk_rise)
    dut.data_in.value = 7  # Valid for Mod-10
    dut.load.value = 1

    # Sample output during the stable phase
    await wait_physical_falling_edges(dut.clk)
    await Timer(period_ns/2 - skew_ns, unit='ns')

    probed_val   = int(dut.count.value)
    expected_val = 7

    dut._log.info(f"Got: {probed_val:04b} | Expected: {expected_val:04b}")
    assert probed_val == expected_val, (
            f"Validation Failed! Expected {expected_val:04b}, Got {probed_val:04b}"
    )

    # de-activate load
    await wait_virtual_rising_edges(vclk_rise)
    dut.load.value    = 0
    dut.data_in.value = 15

    dut._log.info("-- Valid Load Testing PASSED.")
    

# ============================================================
#  regression test #3
# ============================================================
async def test_invalid_load(dut, vclk_rise, period_ns=10, skew_ns=3):
    """
    Helper function to test the loading of a invalid value in the counter 
    """
    print(f"\n")
    dut._log.info("-- Testing Invalid Load (data_in = 12)")
    
    await wait_virtual_rising_edges(vclk_rise)
    dut.data_in.value = 12  # Out of bounds for Mod-10
    dut.load.value = 1

    # Sample output during the stable phase
    await wait_physical_falling_edges(dut.clk)
    await Timer(period_ns/2 - skew_ns, unit='ns')
    
    probed_val   = int(dut.count.value)
    expected_val = 0

    dut._log.info(f"Got: {probed_val:04b} | Expected: {expected_val:04b}")
    assert probed_val == expected_val, (
            f"Validation Failed! Expected {expected_val:04b}, Got {probed_val:04b}"
    )

    # de-activate load
    await wait_virtual_rising_edges(vclk_rise)
    dut.load.value = 0
    dut.data_in.value = 15
    
    dut._log.info("-- Invalid Load Testing PASSED.")

# ============================================================
#  Testbench
# ============================================================
@cocotb.test()
async def test_cnt(dut):

    # --- 1. Load Configuration
    config_file = "config.yaml"
    if os.path.exists(config_file):
        with open(config_file, "r") as f:
            # SafeLoader is the recommended way to load YAML
            cfg = yaml.load(f, Loader=yaml.SafeLoader)
    else:
        dut._log.error(f"Config file {config_file} not found! Using defaults.")
        # Fallback defaults if file is missing
        cfg = {
            "regressions": {"run": True, "load_valid": False, "load_invalid": False},
            "settings": {"num_cycles": 20, "period_ns": 10, "phase_ns": 1, "skew_ns": 3}
        }

    # Extract settings for easier access
    s = cfg["settings"]
    period_ns = s["period_ns"]
    phase_ns  = s["phase_ns"]
    skew_ns   = s["skew_ns"]

    # --- 2. Initialization ---
    dut.load.value    = 0
    dut.data_in.value = 15 # out of bound value
    dut.rst_n.value   = 1
    dut.clk.value     = 0
    if hasattr(dut, 'v_clk'): # Initialize virtual clock signal if it exists in your HDL
        dut.v_clk.value = 0

    # --- 3. Create virtual clock 
    vclk_rise, vclk_fall, vclk_gen = make_virtual_clock(dut, period_ns)
    # --- 4. Start virtual clock ---
    cocotb.start_soon(vclk_gen())
    
    # --- 5. Start physical clk signal ---
    # Make the physical clk signal a lagged version of the virtual clock 
    await Timer(phase_ns, unit="ns")
    cocotb.start_soon(Clock(dut.clk, period_ns*1, unit="ns").start(start_high=False))

    # --- 6. Log the test start ---
    print(f"\n")
    dut._log.info(f"Starting Test: Time {cocotb.utils.get_sim_time('ns')} ns")

    # --- 7. Conditional Stimuli Execution
    # Run Regression #1: run Module-10 Up counter Regression
    if cfg["regressions"]["run"]:
        await test_counter(dut, vclk_rise, vclk_fall,
                               num_cycles=s["run_cycles"],
                               period_ns=period_ns,
                               skew_ns=skew_ns)
    else:
        dut._log.info("Skipping Modulo-10 Up Counter Regression (disabled in config).")

    # Run Regression #2: Test Valid Load 
    if cfg["regressions"]["valid_load"]:
        await test_valid_load(dut, vclk_rise, period_ns=period_ns, skew_ns=skew_ns)
        await wait_virtual_rising_edges(vclk_rise,14) # advance time a few extra cycles
    else:
        dut._log.info("Skipping Valid Load Regression (disabled in config).")

    # Run Regression #3: Test Invalid Load 
    if cfg["regressions"]["invalid_load"]:
        await test_invalid_load(dut, vclk_rise, period_ns=period_ns, skew_ns=skew_ns)
        await wait_virtual_rising_edges(vclk_rise,14) # advance time a few extra cycles
    else:
        dut._log.info("Skipping Invalid Load Regression (disabled in config).")

    # --- 8. Log the test end
    print(f"\n")
    dut._log.info(f"Ending Test:: Time {cocotb.utils.get_sim_time('ns')} ns")
    print(f"\n")

    # extend the simulation run time a bit longer 
    dut.data_in.value = 'xxxx'
    await wait_virtual_rising_edges(vclk_rise,14) # advance time a few extra cycles
